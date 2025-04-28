const std = @import("std");
const ren = @import("renderer.zig");
const wrld = @import("world.zig");

pub fn main() void {
    const window = ren.createWindow() catch |err| {
        std.log.err("window creation error: {s}", .{@errorName(err)});
        return;
    };
    defer ren.c.glfwTerminate();

    var renderer = ren.Renderer.init() catch |err| {
        std.log.err("failed to initialise graphics stuff: {s}", .{@errorName(err)});
        return;
    };
    defer renderer.deinit();
    ren.c.glfwSetWindowUserPointer(window, &renderer);

    var world = wrld.World.init(window, renderer.shader);

    while (ren.c.glfwWindowShouldClose(window) == ren.c.GLFW_FALSE) {
        renderer.draw();
        world.frame();

        if (ren.c.glfwGetKey(window, ren.c.GLFW_KEY_ESCAPE) == ren.c.GLFW_PRESS) {
            ren.c.glfwSetWindowShouldClose(window, ren.c.GLFW_TRUE);
        } else if(ren.c.glfwGetKey(window, ren.c.GLFW_KEY_R) == ren.c.GLFW_PRESS) {
            renderer.populateBuffer() catch {};
        }

        ren.c.glfwSwapBuffers(window);
        ren.c.glfwPollEvents();
    }
}
