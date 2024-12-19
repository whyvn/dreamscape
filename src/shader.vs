#version 330 core

layout (location = 0) in float a_index;

const vec2 SCREEN[4] = vec2[4](
    vec2( 1, 1),
    vec2(-1, 1),
    vec2(-1,-1),
    vec2( 1,-1)
);

const vec2 UV[4] = vec2[4](
    vec2(1,1),
    vec2(0,1),
    vec2(0,0),
    vec2(1,0)
);

out vec2 v_uv;

void main() {
    gl_Position = vec4(
        SCREEN[int(a_index)],
        0.0,
        1.0
    );

    v_uv = UV[int(a_index)];
}
