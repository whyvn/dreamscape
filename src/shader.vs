#version 330 core

layout (location = 0) in float a_index;

// is setting this uniform any faster than using
// world position as a vertex attribute rather than index
uniform vec2 u_framebuffer;

const vec2 SCREEN[3] = vec2[4](
    vec2( 1, 1),
    vec2(-1, 1),
    vec2(-1,-1),
    vec2( 1, -1),
);

void main() {
    gl_Position = vec4(SCREEN[int(a_index)] * u_framebuffer, 0.0, 1.0);
}
