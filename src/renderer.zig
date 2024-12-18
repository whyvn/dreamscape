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

    const vertex_shader_location = "src/shader.vs";
    const fragment_shader_location = "src/shader.fs";

    fn initBuffers(self: *@This()) void {
        c.glGenVertexArrays(1, &self.vao);
        c.glBindVertexArray(self.vao);

        // because of `SCREEN` quadrants (see vertex shader)
        const indices = [_]c.GLuint{ 0, 1, 2, 0, 3, 2 };
        c.glGenBuffers(1, &self.ibo);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ibo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, c.GL_STATIC_DRAW);

        const vertices = [_]c.GLfloat{ 0, 1, 2, 3 };
        c.glGenBuffers(1, &self.vbo);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

        c.glVertexAttribPointer(0, 1, c.GL_FLOAT, c.GL_FALSE, @sizeOf(c.GLfloat), null);
        c.glEnableVertexAttribArray(0);
    }

    fn readFileToCString(allocator: *const std.mem.Allocator, path: []const u8) !?[:0]u8 {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        const buffer = try allocator.alloc(u8, try file.getEndPos() + 1); // +1 for c style null termination
        buffer[try file.readAll(buffer)] = 0;
        // return @intToPtr(:0), buffer;
    }

    fn shaderErrorCheck(shader: c.GLuint, pname: c.GLenum) !void {
        var success = undefined;
        var info_log: [512]u8 = undefined;

        c.glGetShaderiv(shader, pname, &success);
        if(!success) {
            c.glGetShaderInfoLog(shader, 512, null, &info_log);
            return error.ShaderCompilationFailed;
        }
    }

    fn initShader(self: *@This()) !void {
        _ = self;
        const allocator = std.heap.page_allocator;

        const vertex_source = try readFileToCString(&allocator, vertex_shader_location);
        const fragment_source = try readFileToCString(&allocator, fragment_shader_location);
        defer allocator.free(vertex_source);
        defer allocator.free(fragment_source);

        const vertex = c.glCreateShader(c.GL_VERTEX_SHADER);
        const fragment = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        c.glShaderSource(vertex, 1, &vertex_source, null);
        c.glShaderSource(fragment, 1, &fragment_source, null);
        c.glCompileShader(vertex);
        c.glCompileShader(fragment);
        shaderErrorCheck(vertex, c.GL_COMPILE_STATUS);
        shaderErrorCheck(fragment, c.GL_COMPILE_STATUS);
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

    pub fn update() void {
        // delta time maybe?

        c.glDrawElements(c.GL_TRIANGLES, 4 * @sizeOf(c.GLfloat), c.GL_UNSIGNED_INT, null);
    }
};
