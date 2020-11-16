uniform highp float aspectRatio;
uniform lowp float maxDistance;
uniform mediump float collisionTolerance;

uniform highp vec3 cameraPos;
uniform highp vec2 cameraRotation;
uniform highp float cameraFov;

uniform lowp vec3 cubeData[200];
uniform lowp int numCubes;

uniform lowp vec4 sphereData[100];
uniform lowp int numSpheres;

highp float cubeDistanceEstimator(in vec3 pos, in vec3 cubePos, in vec3 cubeDim) {
    mediump float dx = max(cubePos.x - pos.x, max(0, pos.x - cubePos.x - cubeDim.x));
    mediump float dy = max(cubePos.y - pos.y, max(0, pos.y - cubePos.y - cubeDim.y));
    mediump float dz = max(cubePos.z - pos.z, max(0, pos.z - cubePos.z - cubeDim.z));
    return sqrt(dx * dx + dy * dy + dz * dz);
}
highp float sphereDistanceEstimator(in vec3 pos, in vec4 sphereData) {
    mediump float dx = sphereData.x - pos.x;
    mediump float dy = sphereData.y - pos.y;
    mediump float dz = sphereData.z - pos.z;
    return sqrt(dx * dx + dy * dy + dz * dz) - sphereData.w;
}

highp float distanceEstimator(in vec3 pos) {
    highp float closestDistance = maxDistance;
    for (int i = 0; i < numCubes; i ++) {
        closestDistance = min(
            closestDistance,
            cubeDistanceEstimator(pos, cubeData[2 * i], cubeData[2 * i + 1])
        );
    }
    for (int i = 0; i < numSpheres; i ++) {
        closestDistance = min(
            closestDistance,
            sphereDistanceEstimator(pos, sphereData[i])
        );
    }
    return closestDistance;
}

mediump vec4 rayMarch(in vec3 pos, in vec3 directionNorm) {
    mediump float distanceTravelled = 0.0;
    while (distanceTravelled < maxDistance) {
        highp float stepSize = distanceEstimator(pos);
        distanceTravelled += stepSize;
        if (stepSize < collisionTolerance) {
            highp float depth = distanceTravelled / maxDistance;
            return vec4(1 - depth, 1 - depth, 1 - depth, 1.0);
        }
        pos += directionNorm * stepSize;
    }
    return vec4(0, 0, 0, 1.0);
}

vec4 effect(in vec4 in_colour, in sampler2D texture, in vec2 texture_coords, in vec2 screen_coords ) {
    highp float verticalFov = cameraFov / aspectRatio;
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
    highp vec4 colour = rayMarch(cameraPos, directionNorm);

    return colour;
}
