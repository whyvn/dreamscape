const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const zstbi = @import("zstbi");

fn framebuffer_size_callback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);

    // technically dont need to use a user pointer to get Renderer
    // since frame.texture is the only texture that can be bound
    // so we can just use glTexImage2D
    const renderer = @import("shared.zig").glfwShared.getRenderer(window.?);
    renderer.viewport.width = width;
    renderer.viewport.height = height;

    c.glBindTexture(c.GL_TEXTURE_2D, renderer.backbuffer);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, width, height, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, null);

    // dont really need to cache the location since we wont be calling this that often
    c.glUniform2f(
        c.glGetUniformLocation(renderer.shader, "u_viewport"),
        @floatFromInt(width),
        @floatFromInt(height)
    );

    renderer.populateBuffer() catch {};
}

const WindowCreationError = error{
    glfwInit,
    glfwWindowCreation,
    gladLoading
};

pub fn createWindow() !*c.GLFWwindow {
    if (c.glfwInit() == 0)
        return error.glfwInit;
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(800, 600, "dreamscape", null, null);
    errdefer c.glfwTerminate();
    if (window == null)
        return error.glfwWindowCreation;
    c.glfwMakeContextCurrent(window);

    _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == c.GL_FALSE)
        return error.gladLoading;

    // remove optional pointer since we wouldve propagated the error already
    return @ptrCast(window);
}

pub const Renderer = struct {
    const startingPoint = enum {
        random,
        texture
    };

    vao: c.GLuint,
    ibo: c.GLuint,
    vbo: c.GLuint,

    shader: c.GLuint,

    backbuffer: c.GLuint, // as texture

    viewport: struct {
        width: c_int,
        height: c_int
    },

    startup: struct {
        starting_point: startingPoint = .random,
        texture: c.GLuint = undefined,
    } = .{},

    fn initBuffers(self: *@This()) !void {
        // TODO: start with a randomly coloured texture or a texture given by the user
        c.glGenTextures(1, &self.backbuffer);
        c.glBindTexture(c.GL_TEXTURE_2D, self.backbuffer);
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, 800, 600, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, null);
        // nearest neighbor is better for the effect i want
        // but i need bi linear for blur effects in shader
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);

        c.glGenVertexArrays(1, &self.vao);
        c.glBindVertexArray(self.vao);

        const indices = [6]c.GLuint{ 0, 1, 2, 0, 3, 2 };
        c.glGenBuffers(1, &self.ibo);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ibo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, c.GL_STATIC_DRAW);

        const vertices = [_]c.GLfloat{0} ** 4;
        c.glGenBuffers(1, &self.vbo);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

        c.glVertexAttribPointer(0, 1, c.GL_FLOAT, c.GL_FALSE, @sizeOf(c.GLfloat), null);
        c.glEnableVertexAttribArray(0);
    }

    fn shaderErrorCheck(shader: c.GLuint, pname: c.GLenum) !void {
        var success: c.GLint = undefined;

        if(pname == c.GL_COMPILE_STATUS) {
            c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
        } else if(pname == c.GL_LINK_STATUS) {
            c.glGetProgramiv(shader, c.GL_LINK_STATUS, &success);
        }

        if(success == 0) {
            var info_log: [512]c.GLchar = undefined;
            @memset(&info_log, 0);
            c.glGetShaderInfoLog(shader, 512, null, &info_log);
            std.log.err("shader fail log: {s}", .{info_log});
            return error.ShaderCompilationFailed;
        }
    }

    fn shaderMake(comptime vertex_path: []const u8, comptime fragment_path: []const u8) !c.GLuint {
        const vertex_source = @embedFile(vertex_path);
        const fragment_source = @embedFile(fragment_path);

        const vertex = c.glCreateShader(c.GL_VERTEX_SHADER);
        const fragment = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        defer c.glDeleteShader(vertex);
        defer c.glDeleteShader(fragment);
        c.glShaderSource(vertex, 1, @ptrCast(&vertex_source), null);
        c.glShaderSource(fragment, 1, @ptrCast(&fragment_source), null);
        c.glCompileShader(vertex);
        c.glCompileShader(fragment);
        try shaderErrorCheck(vertex, c.GL_COMPILE_STATUS);
        try shaderErrorCheck(fragment, c.GL_COMPILE_STATUS);

        const shader = c.glCreateProgram();
        c.glAttachShader(shader, vertex);
        c.glAttachShader(shader, fragment);
        defer c.glDetachShader(shader, vertex);
        defer c.glDetachShader(shader, fragment);
        c.glLinkProgram(shader);
        try shaderErrorCheck(shader, c.GL_LINK_STATUS);

        return shader;
    }

    fn addNoise(self: *@This()) !void {
        _ = self;
        // TODO: implement a function that half mixes a bit of random pixel values to the framebfufer
    }

    /// populate initial fbo texture
    pub fn populateBuffer(self: *@This()) !void {
        var init_frame: c.GLuint = undefined;
        defer c.glDeleteProgram(init_frame);

        switch(self.startup.starting_point) {
            .random => {
                init_frame = try shaderMake("shader.vs", "init_random.fs");
                c.glUseProgram(init_frame);

                var seed: u64 = undefined;
                try std.posix.getrandom(std.mem.asBytes(&seed));
                var rand = std.rand.DefaultPrng.init(seed);
                c.glUniform1f(c.glGetUniformLocation(init_frame, "u_seed"), rand.random().float(f32));
            },

            .texture => {
                init_frame = try shaderMake("shader.vs", "init_texture.fs");
                c.glUseProgram(init_frame);

                c.glActiveTexture(c.GL_TEXTURE1);
                c.glUniform1i(c.glGetUniformLocation(init_frame, "start"), 1);
            }
        }

        self.draw();
        c.glUseProgram(self.shader);
    }

    pub fn textureFromPath(path: []const u8) !c.GLuint {
        var texture: c.GLuint = undefined;
        c.glGenTextures(1, &texture);
        c.glBindTexture(c.GL_TEXTURE_2D, texture);

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        zstbi.init(gpa.allocator());
        defer zstbi.deinit();
        zstbi.setFlipVerticallyOnLoad(true);
        var img = try zstbi.Image.loadFromFile(@ptrCast(path), 0);
        defer img.deinit();

        const format = c.GL_RGB + @intFromBool(img.num_components == 4) - @as(c_int, @intFromBool(img.num_components == 1))*4;
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, format, @intCast(img.width), @intCast(img.height), 0, @intCast(format), c.GL_UNSIGNED_BYTE, img.data.ptr);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);

        return texture;
    }

    pub fn init(startup: struct {
        starting_point: startingPoint,
        texture_name: ?[]const u8
    }) !@This() {
        // c.glEnable(c.GL_BLEND);
        // c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);

        var self: @This() = undefined;
        try self.initBuffers();
        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, self.backbuffer);

        self.startup.starting_point = startup.starting_point;
        if (startup.starting_point == .texture) {
            // self.startup.texture = try textureFromPath(startup.texture_name.?);
        }

        self.shader = try shaderMake("shader.vs", "shader.fs");
        c.glUniform1i(c.glGetUniformLocation(self.shader, "u_frame"), 0);

        try self.populateBuffer();
        c.glUseProgram(self.shader);

        return self;
    }

    pub fn deinit(self: *@This()) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteBuffers(1, &self.ibo);

        c.glDeleteProgram(self.shader);
        c.glDeleteTextures(1, &self.backbuffer);
        if(self.startup.starting_point == .texture)
            c.glDeleteTextures(1, &self.startup.texture);
    }

    pub fn draw(self: *@This()) void {
        c.glCopyTexSubImage2D(
            c.GL_TEXTURE_2D,
            0, 0, 0, 0, 0,
            self.viewport.width,
            self.viewport.height,
        );

        c.glClearColor(0.1, 0.1, 0.1, 1);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
    }
};
