const std = @import("std");
const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const gl = @cImport(@cInclude("glad/glad.h"));

pub fn framebuffer_size_callback(_: ?*glfw.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    gl.glViewport(0, 0, width, height);
}

pub fn main() void {
    if (glfw.glfwInit() == 0) {
        std.log.err("GLFW init failed", .{});
        return;
    }
    defer glfw.glfwTerminate();

    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);

    const window = glfw.glfwCreateWindow(800, 600, "dreamscape", null, null);
    if (window == null) {
        std.log.err("GLFW window creation failed", .{});
        glfw.glfwTerminate();
        return;
    }
    glfw.glfwMakeContextCurrent(window);
    _ = glfw.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if (gl.gladLoadGLLoader(@ptrCast(&glfw.glfwGetProcAddress)) == gl.GL_FALSE) {
        std.log.err("glad init failed", .{});
        glfw.glfwTerminate();
        return;
    }
}
