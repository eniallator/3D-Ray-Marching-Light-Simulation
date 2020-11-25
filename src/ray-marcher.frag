uniform lowp vec2 dimensions;
uniform lowp float maxDistance;
uniform mediump float collisionTolerance;

uniform highp vec3 cameraPos;
uniform highp mat3 cameraRotationMatrix;
uniform highp float cameraViewPortDist;

uniform highp vec3 lightPositions[100];
uniform highp vec4 lightColours[100];
uniform highp float lightBrightnesses[100];
uniform lowp int lightCount;
uniform highp float lightMaxRange;

struct ObjectData {
    mediump int id;
    highp float dist;
    highp vec4 colour;
    // highp vec3 surfaceNormal;
    // highp float refactiveIndex;
};


uniform lowp vec3 cubeData[200];
uniform lowp int cubeCount;
ObjectData cubeDistanceEstimator(in vec3 pos, ObjectData closestObject) {
    for (int i = 0; i < cubeCount / 2; i ++) {
        vec3 cubePos = cubeData[i * 2];
        vec3 cubeDim = cubeData[i * 2 + 1];
        mediump float dx = max(cubePos.x - cubeDim.x / 2 - pos.x, max(0, pos.x - cubePos.x - cubeDim.x / 2));
        mediump float dy = max(cubePos.y - cubeDim.y / 2 - pos.y, max(0, pos.y - cubePos.y - cubeDim.y / 2));
        mediump float dz = max(cubePos.z - cubeDim.z / 2 - pos.z, max(0, pos.z - cubePos.z - cubeDim.z / 2));
        highp float dist;
        if (dx + dy + dz == 0) {
            vec3 distVec = abs(pos - cubePos) - cubeDim / 2;
            dist = max(distVec.x, max(distVec.y, distVec.z));
        } else {
            dist = sqrt(dx * dx + dy * dy + dz * dz);
        }
        if (dist < closestObject.dist) {
            closestObject = ObjectData(i, dist, vec4(
                (cubePos.x + cubeDim.x / 2 - pos.x) / cubeDim.x,
                (cubePos.y + cubeDim.y / 2 - pos.y) / cubeDim.y,
                (cubePos.z + cubeDim.z / 2 - pos.z) / cubeDim.z,
                1.0
            ));
        }
    }
    return closestObject;
}


uniform lowp vec3 insideCubeData[200];
uniform lowp int insideCubeCount;
ObjectData insideCubeDistanceEstimator(in vec3 pos, ObjectData closestObject) {
    for (int i = 0; i < insideCubeCount / 2; i ++) {
        vec3 insideCubePos = insideCubeData[i * 2];
        vec3 insideCubeDim = insideCubeData[i * 2 + 1];
        mediump float dx = max(insideCubePos.x - insideCubeDim.x / 2 - pos.x, max(0, pos.x - insideCubePos.x - insideCubeDim.x / 2));
        mediump float dy = max(insideCubePos.y - insideCubeDim.y / 2 - pos.y, max(0, pos.y - insideCubePos.y - insideCubeDim.y / 2));
        mediump float dz = max(insideCubePos.z - insideCubeDim.z / 2 - pos.z, max(0, pos.z - insideCubePos.z - insideCubeDim.z / 2));
        highp float dist;
        if (dx + dy + dz == 0) {
            vec3 distVec = abs(pos - insideCubePos) - insideCubeDim / 2;
            dist = max(distVec.x, max(distVec.y, distVec.z));
        } else {
            dist = sqrt(dx * dx + dy * dy + dz * dz);
        }
        if (-dist < closestObject.dist) {
            closestObject = ObjectData(i + 100, -dist, vec4(1.0));
        }
    }
    return closestObject;
}


uniform lowp vec4 sphereData[100];
uniform lowp int sphereCount;
highp ObjectData sphereDistanceEstimator(in vec3 pos, ObjectData closestObject) {
    for (int i = 0; i < sphereCount; i ++) {
        vec4 sphere = sphereData[i];
        mediump float dx = sphere.x - pos.x;
        mediump float dy = sphere.y - pos.y;
        mediump float dz = sphere.z - pos.z;
        highp float dist =  sqrt(dx * dx + dy * dy + dz * dz) - sphere.w;
        if (dist < closestObject.dist) {
            closestObject = ObjectData(i + 200, dist, vec4(
                (sphere.x + sphere.w / 2 - pos.x) / sphere.w,
                (sphere.y + sphere.w / 2 - pos.y) / sphere.w,
                (sphere.z + sphere.w / 2 - pos.z) / sphere.w,
                1.0
            ));
        }
    }
    return closestObject;
}


uniform lowp vec3 cylinderData[200];
uniform lowp int cylinderCount;
highp ObjectData cylinderDistanceEstimator(in vec3 pos, ObjectData closestObject) {
    for (int i = 0; i < cylinderCount / 2; i ++) {
        vec3 cylinderPos = cylinderData[i * 2];
        float radius = cylinderData[i * 2 + 1].x;
        float height = cylinderData[i * 2 + 1].y;

        vec3 relativePos = cylinderPos - pos;
        vec2 posDiff = vec2(
            max(length(relativePos.xz) - radius, 0),
            max(abs(relativePos.y) - height / 2, 0)
        );
        float dist;
        if (posDiff.x + posDiff.y == 0) {
            dist = max(length(relativePos.xz) - radius, abs(relativePos.y) - height / 2);
        } else {
            dist = length(posDiff);
        }

        if (dist < closestObject.dist) {
            closestObject = ObjectData(i + 300, dist, vec4(
                (cylinderPos.x + radius / 2 - pos.x) / radius,
                (cylinderPos.y + height / 2 - pos.y) / height,
                (cylinderPos.z + radius / 2 - pos.z) / radius,
                1.0
            ));
        }
    }
    return closestObject;
}

highp ObjectData distanceEstimator(in vec3 pos) {
    ObjectData closestObject = ObjectData(-1, maxDistance, vec4(0));
    closestObject = cubeDistanceEstimator(pos, closestObject);
    closestObject = insideCubeDistanceEstimator(pos, closestObject);
    closestObject = sphereDistanceEstimator(pos, closestObject);
    closestObject = cylinderDistanceEstimator(pos, closestObject);
    return closestObject;
}


highp vec4 lightPixel(in ObjectData rayClosestObject, in vec3 pos) {
    highp vec4 outColour = vec4(0);
    for (int i = 0; i < lightCount; i++) {
        highp float dist = length(lightPositions[i] - pos);
        if (dist > lightMaxRange) {
            continue;
        }

        mediump float distanceTravelled = 0.0;
        vec3 shadowRayPos = lightPositions[i].xyz;
        vec3 shadowRayDirNorm = normalize(-lightPositions[i] + pos);
        highp float pixelVisibility = 1.0;
        highp float smallestDist = maxDistance;
        while (distanceTravelled < dist - collisionTolerance) {
            highp ObjectData closestObject = distanceEstimator(shadowRayPos);
            distanceTravelled += closestObject.dist;
            if (closestObject.dist < collisionTolerance) {
                if (closestObject.id != rayClosestObject.id) {
                    pixelVisibility = 0.0;
                }
                break;
            }
            shadowRayPos += shadowRayDirNorm * closestObject.dist;
        }
        highp float inverseDist = 1 - dist / lightMaxRange;
        outColour +=
            rayClosestObject.colour * lightColours[i]
            * inverseDist * inverseDist
            * lightBrightnesses[i]
            * pixelVisibility;
    }
    return outColour;
}


mediump vec4 rayMarch(in vec3 pos, in vec3 dirNorm) {
    mediump float distanceTravelled = 0.0;
    while (distanceTravelled < maxDistance) {
        highp ObjectData closestObject = distanceEstimator(pos);
        distanceTravelled += closestObject.dist;
        if (closestObject.dist < collisionTolerance) {
            return lightPixel(closestObject, pos);
        }
        pos += dirNorm * closestObject.dist;
    }
    return vec4(0, 0, 0, 1.0);
}

vec4 effect(in vec4 inColour, in sampler2D texture, in vec2 textureCoords, in vec2 screenCoords) {
    int samplesPerAxis = 2;
    vec4 colour = vec4(0);
    vec2 coords = dimensions * textureCoords;
    for (float x = -0.33; x <= 0.33; x += 0.33) {
        for (float y = -0.33; y <= 0.33; y += 0.33) {
            vec2 adjustedOffset = (coords + vec2(x, y)) / dimensions;
            vec2 relativeOffset = (adjustedOffset - vec2(0.5)) * vec2(dimensions.x / dimensions.y, 1);
            vec3 relativeDir = vec3(cameraViewPortDist, -relativeOffset.x, relativeOffset.y);
            vec3 dirNorm = normalize(cameraRotationMatrix * relativeDir);

            colour += rayMarch(cameraPos, dirNorm) / 9;
        }
    }
    return colour;
}
