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

    mouse: struct {
        x: f64 = 0,
        y: f64 = 0,
        last_x: f64 = 0,
        last_y: f64 = 0
    } = .{},

    delta_time: f64 = 0,
    last_frame: f64 = 0,

    pub fn init(window: ?*c.GLFWwindow, shader: c.GLuint) @This() {
        return .{
            .window = window,
            .input_loc = c.glGetUniformLocation(shader, "u_world_input")
        };
    }

    fn inputToValue(self: *@This(), key: c_int) f32 {
        return
            @as(f32, @floatCast(self.delta_time)) *
            @as(f32, @floatFromInt(@intFromBool(c.glfwGetKey(self.window, key) == c.GLFW_PRESS)));
    }

    // gets input and updates uniforms
    pub fn frame(self: *@This()) void {
        const current_frame = c.glfwGetTime();
        self.delta_time = current_frame - self.last_frame;
        self.last_frame = current_frame;

        self.pos = .{
            .x = self.inputToValue(c.GLFW_KEY_RIGHT) - self.inputToValue(c.GLFW_KEY_LEFT),
            .y = self.inputToValue(c.GLFW_KEY_UP) - self.inputToValue(c.GLFW_KEY_DOWN),
            .z = self.inputToValue(c.GLFW_KEY_W) - self.inputToValue(c.GLFW_KEY_S),
        };

        self.camera = .{
            .yaw = @as(f32, @floatCast(self.mouse.x - self.mouse.last_x)),
            .pitch = @as(f32, @floatCast(self.mouse.y - self.mouse.last_y))
        };
        self.mouse = .{};

        self.setInputs();
    }

    pub fn mouseCallback(window: ?*c.GLFWwindow, x_pos: f64, y_pos: f64) callconv(.C) void {
        const world = @import("shared.zig").glfwShared.getWorld(window.?);
        world.mouse = .{
            .last_x = world.mouse.x,
            .last_y = world.mouse.y,
            .x = x_pos,
            .y = y_pos
        };
    }

    pub fn setInputs(self: *@This()) void {
        // dont use identitiy matrix since we are just adding this since its like fake movement
        const input = zlm.Mat4{
            .fields = .{
                .{0,    0,          0, self.pos.x   },
                .{0,    0,          0, self.pos.y   },
                .{0,    0,          self.pos.z, 0   },
                .{0,    0,          0, 0            }
            }
        };

        c.glUniformMatrix4fv(self.input_loc, 1, c.GL_FALSE, @ptrCast(&input.fields));
    }
};

// TODO: generate constant shader `COLOURS` based on texture colours or something
