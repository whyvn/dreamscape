const std = @import("std");
const ren = @import("renderer.zig");
const wrld = @import("world.zig");
const shared = @import("shared.zig");

pub fn main() void {
    const window = ren.createWindow() catch |err| {
        std.log.err("window creation error: {s}", .{@errorName(err)});
        return;
    };
    defer ren.c.glfwTerminate();

    ren.c.glfwSetInputMode(window, ren.c.GLFW_CURSOR, ren.c.GLFW_CURSOR_DISABLED);
    _ = ren.c.glfwSetCursorPosCallback(window, wrld.World.mouseCallback);

    var renderer = ren.Renderer.init() catch |err| {
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
