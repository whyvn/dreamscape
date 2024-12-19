const std = @import("std");
pub const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

fn framebuffer_size_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
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
    vao: c.GLuint,
    ibo: c.GLuint,
    vbo: c.GLuint,

    shader: c.GLuint,

    // because of `SCREEN` quadrants (see vertex shader)
    const indices = [6]c.GLuint{ 0, 1, 2, 0, 3, 2 };
    const vertices = [4]c.GLfloat{ 0, 1, 2, 3 };

    const vertex_shader_location = "src/shader.vs";
    const fragment_shader_location = "src/shader.fs";

    fn initBuffers(self: *@This()) void {
        c.glGenVertexArrays(1, &self.vao);
        c.glBindVertexArray(self.vao);

        c.glGenBuffers(1, &self.ibo);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ibo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, c.GL_STATIC_DRAW);

        c.glGenBuffers(1, &self.vbo);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

        c.glVertexAttribPointer(0, 1, c.GL_FLOAT, c.GL_FALSE, @sizeOf(c.GLfloat), null);
        c.glEnableVertexAttribArray(0);
    }

    fn shaderErrorCheck(shader: c.GLuint, pname: c.GLenum) !void {
        var success: c.GLint = undefined;

        c.glGetShaderiv(shader, pname, &success);
        if(success == 0) {
            var info_log: [512]c.GLchar = undefined;
            @memset(&info_log, 0);
            c.glGetShaderInfoLog(shader, 512, null, &info_log);
            std.log.err("shader fail log: {s}", .{info_log});
            return error.ShaderCompilationFailed;
        }
    }

    fn initShader(self: *@This()) !void {
        _ = self;

        const vertex_source = @embedFile("shader.vs");
        const fragment_source = @embedFile("shader.fs");

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
    }

    pub fn init() !@This() {
        var self: @This() = undefined;
        self.initBuffers();
        try self.initShader();

        return self;
    }

    pub fn free(self: *@This()) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteBuffers(1, &self.ibo);
    }

    pub fn draw() void {
        // delta time maybe?
        c.glDrawElements(c.GL_TRIANGLES, 4, c.GL_UNSIGNED_INT, null);
    }
};
