#version 330 core

out vec4 frag_colour;

in vec2 v_uv;
uniform sampler2D u_frame;

void main() {
    frag_colour = vec4(vec3(0.01) + texture(u_frame, v_uv).xyz, 1.0);
}
