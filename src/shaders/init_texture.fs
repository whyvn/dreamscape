#version 330 core
out vec4 frag_colour;
in vec2 v_uv;
uniform sampler2D start;

void main() {
    frag_colour = texture(start, v_uv);
}
