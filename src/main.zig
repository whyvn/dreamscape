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

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(gpa.allocator());
    defer args.deinit();
    _ = args.skip();
    const texture_name = args.next();

    var renderer = ren.Renderer.init(.{
        .starting_point = if (texture_name != null) .texture else .random,
        .texture_name = texture_name
    }) catch |err| {
        std.log.err("failed to initialise graphics stuff: {s}", .{@errorName(err)});
        return;
    };
    defer renderer.deinit();

    var world = wrld.World.init(window, renderer.shaders.main);

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
        } else if(c.glfwGetKey(window, c.GLFW_KEY_E) == c.GLFW_PRESS) {
            renderer.addNoise(0.001) catch {};
        }

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
