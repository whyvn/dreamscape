#version 330 core

out vec4 frag_colour;

in vec2 v_uv;

// viewport (and also `u_frame`) width and height
uniform vec2 u_viewport;
// frame buffer texture of previous frame
uniform sampler2D u_frame;

const float WEIGHT_HUE          = .50;
const float WEIGHT_SATURATION   = .25;
const float WEIGHT_VALUE        = .25;
const vec3  WEIGHTS = vec3(WEIGHT_HUE, WEIGHT_SATURATION, WEIGHT_VALUE);
const int   COLOURS_AMOUNT = 6;
const vec3  COLOURS[COLOURS_AMOUNT] = vec3[COLOURS_AMOUNT](
    vec3(0.00, 0.00, 0.00),
    vec3(1.00, 1.00, 1.00),

    vec3(0.01, 0.01, 0.01),
    vec3(0.50, 0.10, 0.00),
    vec3(0.20, 0.55, 0.70),
    vec3(0.20, 0.20, 0.10)
);

// https://github.com/Experience-Monks/glsl-fast-gaussian-blur/blob/master/9.glsl
// 9 tap filter with predefined gaussian weights
vec4 gaussian_blur() {
    vec4 horizontal = vec4(0.0);
    vec4 vertical = vec4(0.0);

    vec2 off1 = vec2(1.3846153846, 0.0);
    vec2 off2 = vec2(3.2307692308, 0.0);

    horizontal += texture2D(u_frame, v_uv) * 0.2270270270;
    horizontal += texture2D(u_frame, v_uv + (off1 / u_viewport)) * 0.3162162162;
    horizontal += texture2D(u_frame, v_uv - (off1 / u_viewport)) * 0.3162162162;
    horizontal += texture2D(u_frame, v_uv + (off2 / u_viewport)) * 0.0702702703;
    horizontal += texture2D(u_frame, v_uv - (off2 / u_viewport)) * 0.0702702703;

    // redo with new direction
    off1 = vec2(0.0, 1.3846153846);
    off2 = vec2(0.0, 3.2307692308);

    vertical += texture2D(u_frame, v_uv) * 0.2270270270;
    vertical += texture2D(u_frame, v_uv + (off1 / u_viewport)) * 0.3162162162;
    vertical += texture2D(u_frame, v_uv - (off1 / u_viewport)) * 0.3162162162;
    vertical += texture2D(u_frame, v_uv + (off2 / u_viewport)) * 0.0702702703;
    vertical += texture2D(u_frame, v_uv - (off2 / u_viewport)) * 0.0702702703;

    return (horizontal + vertical) * 0.5;
}

// https://stackoverflow.com/a/17897228
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// https://stackoverflow.com/a/17897228
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// TODO: maybe check if oklab colour space produces better results
vec4 most_similar() {
    vec4 blurred = gaussian_blur();
    // TODO: how does alpha influences this?
    vec3 colour = rgb2hsv(blurred.xyz);
    // lower score is better
    vec2 closest_colour = vec2(0, 1.0/0.0); // (index, similarity score)

    // TODO: could optimize by hardcoding COLOURS to also be in HSV and sorted by Hue
    //       then using a binary search (is that even faster on gpu though cause of all the branching?)
    for(int i = 0; i < COLOURS_AMOUNT; ++i) {
        vec3 variant = rgb2hsv(COLOURS[i]);
        vec3 similarity = abs(variant - colour) * WEIGHTS;
        float score = similarity.x + similarity.y + similarity.z;

        if(score < closest_colour.y)
            closest_colour = vec2(i, score);
    }

    return vec4(COLOURS[int(closest_colour.x)], blurred.a);
}

void main() {
    // TODO: maybe we could interpolate towards the new colour based on how similar it is?
    frag_colour = most_similar();

    frag_colour += vec4(texture(u_frame, v_uv).xyz, 0.0);
    frag_colour = clamp(frag_colour, 0.0, 1.0);

    // frag_colour = texture(u_frame, v_uv);
}
