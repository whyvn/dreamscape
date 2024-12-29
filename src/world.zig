const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

// const math = @import("../zlm/src/zlm.zig");
const math = @import("zlm");

pub const World = struct {
    // use delta values for movement.
    input_loc: c.GLint,

    pos: struct {
        x: f32 = 0,
        y: f32 = 0,
        z: f32 = 0
    } = .{},

    camera: struct {
        yaw: f32 = 0,
        pitch: f32 = 0,
        roll: f32 = 0,
        // fov: f32 = 0,

        // enabled: bool = true
    } = .{},

    last_frame: f64 = 0,

    pub fn init(shader: c.GLuint) @This() {
        return @This() {
            .input_loc = c.glGetUniformLocation(shader, "u_world_input")
        };
    }

    // gets input and updates uniforms
    pub fn frame(self: *@This(), window: ?*c.GLFWwindow) void {
        const current_frame = c.glfwGetTime();
        const delta_time = current_frame - self.last_frame;
        self.last_frame = current_frame;

        if(c.glfwGetKey(window, c.GLFW_KEY_LEFT) == c.GLFW_PRESS)
            self.pos.x += @floatCast(delta_time);

        std.debug.print("{d}\n", .{self.pos.x});
        const input = math.Mat3{
            .fields = .{
                .{self.pos.x, self.pos.y, self.pos.z},
                .{self.camera.yaw, self.camera.pitch, self.camera.roll},
                .{0, 0, 0},
            },
        };

        c.glUniformMatrix4fv(self.input_loc, 1, c.GL_FALSE, @ptrCast(&input.fields));
    }
};

// TODO: generate constant shader `COLOURS` based on texture colours or something
