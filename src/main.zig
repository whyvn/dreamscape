const std = @import("std");
const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const gl = @cImport(@cInclude("glad/glad.h"));

fn framebuffer_size_callback(_: ?*glfw.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    gl.glViewport(0, 0, width, height);
}

const WindowCreationError = error{ glfwInit, glfwWindowCreation, gladLoading };

fn create_window() error{WindowCreationError}!?*glfw.GLFWwindow {
    if (glfw.glfwInit() == 0)
        return error.glfwInit;

    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);

    const window = glfw.glfwCreateWindow(800, 600, "dreamscape", null, null);
    if (window == null)
        return error.glfwWindowCreation;
    glfw.glfwMakeContextCurrent(window);

    _ = glfw.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if (gl.gladLoadGLLoader(@ptrCast(&glfw.glfwGetProcAddress)) == gl.GL_FALSE)
        return error.gladLoading;

    return window;
}

const Renderer = struct {
    vao: gl.GLuint,
    ibo: gl.GLuint,
    vbo: gl.GLuint,

    shader: gl.GLuint,

    fn init_buffers(self: *@This()) void {
        gl.glGenVertexArrays(1, &self.vao);
        gl.glBindVertexArray(self.vao);

        // because of `SCREEN` quadrants (see vertex shader)
        const indices = [_]gl.GLuint{ 0, 1, 2, 0, 3, 2 };
        gl.glGenBuffers(1, &self.ibo);
        gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, self.ibo);
        gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, gl.GL_STATIC_DRAW);

        const vertices = [_]gl.GLfloat{ 0, 1, 2, 3 };
        gl.glGenBuffers(1, &self.vbo);
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.vbo);
        gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);

        gl.glVertexAttribPointer(0, 1, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(gl.GLfloat), null);
        gl.glEnableVertexAttribArray(0);
    }

    fn init_shader(self: *@This()) void {
        _ = self;
    }

    fn init() @This() {
        var self: @This() = undefined;
        self.init_buffers();

        return self;
    }

    fn free(self: *@This()) void {
        gl.glDeleteVertexArrays(1, &self.vao);
        gl.glDeleteBuffers(1, &self.vbo);
        gl.glDeleteBuffers(1, &self.ibo);
    }

    fn draw() void {
        gl.glDrawElements(gl.GL_TRIANGLES, 4 * @sizeOf(gl.GLfloat), gl.GL_UNSIGNED_INT, null);
    }
};

pub fn main() void {
    const window = create_window() catch |err| {
        std.log.err("window creation error: {s}", .{err});

        if ((err == WindowCreationError.glfwWindowCreation) ||
            (err == WindowCreationError.gladLoading))
            glfw.glfwTerminate();

        return;
    };
    defer glfw.glfwTerminate();

    var renderer = Renderer.init();
    defer renderer.free();

    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
        gl.glClearColor(0.1, 0.1, 0.1, 1);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        Renderer.draw();
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_ESCAPE) == glfw.GLFW_PRESS)
            glfw.glfwSetWindowShouldClose(window, glfw.GLFW_TRUE);

        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
    }
}
