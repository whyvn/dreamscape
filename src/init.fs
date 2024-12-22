#version 330 core
out vec4 frag_colour;
in vec2 v_uv;

uniform float u_seed;

// https://stackoverflow.com/a/4275343
vec4 random_colour(vec2 seed){
    float n = dot(seed, vec2(12.9898, 78.233));
    return fract(vec4(sin(n), cos(n), sin(n), 1.0) * 43758.5453);
}

void main() {
    // frag_colour = texture(, v_uv);
    frag_colour = random_colour(v_uv * u_seed);
}
