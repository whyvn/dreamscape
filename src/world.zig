const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const zlm = @import("zlm");

pub const World = struct {
    window: ?*c.GLFWwindow,
    // use delta values for movement.
    input_loc: c.GLint,

    pos: struct {
        x: f32 = 1,
        y: f32 = 0,
        z: f32 = 0
    } = .{},

    camera: struct {
        yaw: f32 = 0,
        pitch: f32 = 1,
        roll: f32 = 0,
        // fov: f32 = 0,

        // enabled: bool = true
    } = .{},

    delta_time: f64 = 0,
    last_frame: f64 = 0,

    pub fn init(window: ?*c.GLFWwindow, shader: c.GLuint) @This() {
        return @This() {
            .window = window,
            .input_loc = c.glGetUniformLocation(shader, "u_world_input")
        };
    }

    fn input_to_value(self: *@This(), key: c_int) f32 {
        return
            @as(f32, @floatCast(self.delta_time)) *
            @as(f32, @floatFromInt(@intFromBool(c.glfwGetKey(self.window, key) == c.GLFW_PRESS)));
    }

    // gets input and updates uniforms
    pub fn frame(self: *@This()) void {
        // self.pos = .{};
        // self.camera = .{};

        const current_frame = c.glfwGetTime();
        self.delta_time = current_frame - self.last_frame;
        self.last_frame = current_frame;

        self.pos = .{
            .x = self.input_to_value(c.GLFW_KEY_RIGHT) - self.input_to_value(c.GLFW_KEY_LEFT),
            .y = self.input_to_value(c.GLFW_KEY_UP) - self.input_to_value(c.GLFW_KEY_DOWN),
        };

        // TODO: camera stuff
        const input = zlm.Mat4{
            .fields = .{
                .{0,    0,  0, self.pos.x   },
                .{0,    0,  0, self.pos.y   },
                .{0,    0,  0, self.pos.z   },
                .{0,    0,  0, 0            }
            },
        };

        c.glUniformMatrix4fv(self.input_loc, 1, c.GL_FALSE, @ptrCast(&input.fields));
    }
};

// TODO: generate constant shader `COLOURS` based on texture colours or something
