uniform highp vec2 cameraRotation;
uniform highp float cameraFov;


vec4 effect(in vec4 colour, in sampler2D texture, in vec2 texture_coords, in vec2 screen_coords ) {
    highp float verticalFov = cameraFov * 9 / 14;
    highp vec2 rayRotation = vec2(
        cameraRotation.x - cameraFov / 2 + texture_coords.x * cameraFov,
        cameraRotation.y - verticalFov / 2 + texture_coords.y * verticalFov
    );
    highp float xzlen = cos(rayRotation.x);
    highp vec3 directionNorm = vec3(
        xzlen * cos(rayRotation.y),
        sin(rayRotation.x),
        xzlen * sin(-rayRotation.y)
    );
    return vec4(0.5 + directionNorm.x / 2, 0.5 + directionNorm.y / 2, 0.5 + directionNorm.z / 2, colour.a);
}
