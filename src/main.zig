const std = @import("std");
pub const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const ren = @import("renderer.zig");
const wrld = @import("world.zig");
const shared = @import("shared.zig");

pub fn main() void {
    const window = ren.createWindow() catch |err| {
        std.log.err("window creation error: {s}", .{@errorName(err)});
        return;
    };
    defer c.glfwTerminate();

    c.glfwSetInputMode(window, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);
    _ = c.glfwSetCursorPosCallback(window, wrld.World.mouseCallback);

    var renderer = ren.Renderer.init(.texture) catch |err| {
        std.log.err("failed to initialise graphics stuff: {s}", .{@errorName(err)});
        return;
    };
    defer renderer.deinit();

    var world = wrld.World.init(window, renderer.shader);

    var shared_data = shared.glfwShared{
        .renderer = &renderer,
        .world = &world
    };
    shared_data.setWindowPtr(window);

    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        renderer.draw();
        world.frame();

        if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
            c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
        } else if(c.glfwGetKey(window, c.GLFW_KEY_R) == c.GLFW_PRESS) {
            renderer.populateBuffer() catch {};
        }

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
