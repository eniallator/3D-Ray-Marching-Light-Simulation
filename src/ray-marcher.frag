// uniform lowp vec3 cameraPos;
vec4 effect(in vec4 colour, in sampler2D texture, in vec2 texture_coords, in vec2 screen_coords ) {
    // return vec4(colour.r, colour.g, colour.b, colour.a);
    return vec4(1.0, texture_coords.x, texture_coords.y, colour.a);
}
