const std = @import("std");
const ren = @import("renderer.zig");

pub fn main() void {
    const window = ren.createWindow() catch |err| {
        std.log.err("window creation error: {s}", .{@errorName(err)});

        switch(err) {
            error.glfwWindowCreation,
            error.gladLoading => ren.c.glfwTerminate(),
            else => {}
        }

        return;
    };
    defer ren.c.glfwTerminate();

    var renderer = ren.Renderer.init() catch |err| {
        std.log.err("failed to initialise graphics stuff: {s}", .{@errorName(err)});
        return;
    };
    defer renderer.free();

    while (ren.c.glfwWindowShouldClose(window) == ren.c.GLFW_FALSE) {
        ren.c.glClearColor(0.1, 0.1, 0.1, 1);
        ren.c.glClear(ren.c.GL_COLOR_BUFFER_BIT);

        var viewport: [4]ren.c.GLint = undefined;
        ren.c.glGetIntegerv(ren.c.GL_VIEWPORT, @ptrCast(&viewport));
        const fb_loc = ren.c.glGetUniformLocation(renderer.shader, "u_framebuffer");
        if(fb_loc != -1)
            // width, height
            ren.c.glUniform2f(fb_loc, @floatFromInt(viewport[2]), @floatFromInt(viewport[3]));

        ren.Renderer.draw();
        if (ren.c.glfwGetKey(window, ren.c.GLFW_KEY_ESCAPE) == ren.c.GLFW_PRESS)
            ren.c.glfwSetWindowShouldClose(window, ren.c.GLFW_TRUE);

        ren.c.glfwSwapBuffers(window);
        ren.c.glfwPollEvents();
    }
}
