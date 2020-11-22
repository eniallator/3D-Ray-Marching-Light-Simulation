uniform highp float aspectRatio;
uniform lowp float maxDistance;
uniform mediump float collisionTolerance;

uniform highp vec3 cameraPos;
uniform highp vec3 cameraDirNorm;
uniform highp float cameraViewPortDist;

struct ObjectData {
    highp float dist;
    highp vec4 colour;
    // highp vec3 surfaceNormal;
    // highp float refactiveIndex;
};


uniform lowp vec3 cubeData[200];
uniform lowp int numCubes;
ObjectData cubeDistanceEstimator(in vec3 pos, ObjectData closestObject) {
    for (int i = 0; i < numCubes; i ++) {
        vec3 cubePos = cubeData[i * 2];
        vec3 cubeDim = cubeData[i * 2 + 1];
        mediump float dx = max(cubePos.x - cubeDim.x / 2 - pos.x, max(0, pos.x - cubePos.x - cubeDim.x / 2));
        mediump float dy = max(cubePos.y - cubeDim.y / 2 - pos.y, max(0, pos.y - cubePos.y - cubeDim.y / 2));
        mediump float dz = max(cubePos.z - cubeDim.z / 2 - pos.z, max(0, pos.z - cubePos.z - cubeDim.z / 2));
        highp float dist = sqrt(dx * dx + dy * dy + dz * dz);
        if (dist < closestObject.dist) {
            closestObject = ObjectData(dist, vec4(
                (cubePos.x + cubeDim.x / 2 - pos.x) / cubeDim.x,
                (cubePos.y + cubeDim.y / 2 - pos.y) / cubeDim.y,
                (cubePos.z + cubeDim.z / 2 - pos.z) / cubeDim.z,
                1.0
            ));
        }
    }
    return closestObject;
}


uniform lowp vec4 sphereData[100];
uniform lowp int numSpheres;
highp ObjectData sphereDistanceEstimator(in vec3 pos, ObjectData closestObject) {
    for (int i = 0; i < numSpheres; i ++) {
        vec4 sphere = sphereData[i];
        mediump float dx = sphere.x - pos.x;
        mediump float dy = sphere.y - pos.y;
        mediump float dz = sphere.z - pos.z;
        highp float dist =  sqrt(dx * dx + dy * dy + dz * dz) - sphere.w;
        if (dist < closestObject.dist) {
            closestObject = ObjectData(dist, vec4(
                (sphere.x + sphere.w / 2 - pos.x) / sphere.w,
                (sphere.y + sphere.w / 2 - pos.y) / sphere.w,
                (sphere.z + sphere.w / 2 - pos.z) / sphere.w,
                1.0
            ));
        }
    }
    return closestObject;
}

highp ObjectData distanceEstimator(in vec3 pos) {
    ObjectData closestObject = ObjectData(maxDistance, vec4(0));
    closestObject = sphereDistanceEstimator(pos, closestObject);
    closestObject = cubeDistanceEstimator(pos, closestObject);
    return closestObject;
}

mediump vec4 rayMarch(in vec3 pos, in vec3 dirNorm) {
    mediump float distanceTravelled = 0.0;
    highp vec4 colour = vec4(1.0);
    while (distanceTravelled < maxDistance) {
        highp ObjectData closestObject = distanceEstimator(pos);
        distanceTravelled += closestObject.dist;
        if (closestObject.dist < collisionTolerance) {
            highp float depth = distanceTravelled / maxDistance;
            highp vec4 shading = vec4(1 - depth, 1 - depth, 1 - depth, 1.0);
            return closestObject.colour * shading;
        }
        pos += dirNorm * closestObject.dist;
    }
    return vec4(0, 0, 0, 1.0);
}

vec4 effect(in vec4 inColour, in sampler2D texture, in vec2 textureCoords, in vec2 screenCoords) {
    vec3 viewPlaneY = cross(cameraDirNorm, vec3(0, 1, 0));
    vec3 viewPlaneX = cross(cameraDirNorm, viewPlaneY);
    vec2 relativeOffset = (textureCoords - vec2(0.5)) * vec2(aspectRatio, 1);
    vec3 dirNorm = normalize(cameraViewPortDist * cameraDirNorm + relativeOffset.x * viewPlaneX + relativeOffset.y * viewPlaneY);

    highp vec4 colour = rayMarch(cameraPos, dirNorm);
    return colour;
}
