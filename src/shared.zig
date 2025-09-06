pub const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const Renderer = @import("renderer.zig").Renderer;
const World = @import("world.zig").World;

pub const glfwShared = struct {
    renderer: *Renderer,
    world: *World,

    pub fn setWindowPtr(self: *@This(), window: ?*c.GLFWwindow) void {
        c.glfwSetWindowUserPointer(window, self);
    }

    pub fn getRenderer(window: *c.GLFWwindow) *Renderer {
        return @as(*@This(), @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window)))).renderer;
    }

    pub fn getWorld(window: *c.GLFWwindow) *World {
        return @as(*@This(), @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window)))).world;
    }
};
