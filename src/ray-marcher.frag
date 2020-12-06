#define numMaterials 25
#define numLights 20
#define numObjectsPerType 20

uniform lowp vec2 dimensions;
uniform lowp float maxDistance;
uniform highp float globalMinLight;
uniform mediump float collisionTolerance;
uniform lowp float samplesPerAxis;
uniform lowp int maxReflections;
uniform lowp int maxRefractionDepth;
uniform highp float spaceSpeedOfLight;

uniform highp vec3 cameraPos;
uniform highp mat3 cameraRotationMatrix;
uniform highp float cameraViewPortDist;

uniform highp vec3 lightPositions[numLights];
uniform highp vec4 lightColours[numLights];
uniform highp float lightBrightnesses[numLights];
uniform lowp int lightCount;
uniform highp float lightMaxRange;

uniform highp vec4 materialColours[numMaterials];
uniform highp float materialReflectances[numMaterials];
uniform highp float materialSpeedsOfLight[numMaterials];
uniform highp float materialTransparencies[numMaterials];

struct ObjectData {
    mediump int id;
    lowp int materialIndex;
    highp vec3 relativePos;
    highp float dist;
    highp vec4 colour;
    highp vec3 surfaceNormal;
    // highp float refactiveIndex;
};


vec4 getColour(in ObjectData object) {
    if (object.materialIndex < 0) {
        return vec4(1.0);
    }
    return materialColours[object.materialIndex];
}


uniform lowp vec3 cubeData[2 * numObjectsPerType];
uniform lowp int cubeMaterial[numObjectsPerType];
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
            vec3 diff = pos - cubePos;
            vec3 absDiff = abs(diff);
            vec3 surfaceNormal;
            if (absDiff.x > absDiff.y && absDiff.x > absDiff.z) {
                surfaceNormal = vec3(diff.x / absDiff.x, 0, 0);
            } else if (absDiff.y > absDiff.x && absDiff.y > absDiff.z) {
                surfaceNormal = vec3(0, diff.y / absDiff.y, 0);
            } else {
                surfaceNormal = vec3(0, 0, diff.z / absDiff.z);
            }
            closestObject = ObjectData(
                i,
                cubeMaterial[i],
                0.5 + diff / cubeDim,
                dist,
                vec4(0.0),
                surfaceNormal
            );
            closestObject.colour = getColour(closestObject);
        }
    }
    return closestObject;
}


uniform lowp vec3 insideCubeData[2 * numObjectsPerType];
uniform lowp int insideCubeMaterial[numObjectsPerType];
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
            vec3 diff = insideCubePos - pos;
            vec3 absDiff = abs(diff);
            vec3 surfaceNormal;
            if (absDiff.x > absDiff.y && absDiff.x > absDiff.z) {
                surfaceNormal = vec3(diff.x / absDiff.x, 0, 0);
            } else if (absDiff.y > absDiff.x && absDiff.y > absDiff.z) {
                surfaceNormal = vec3(0, diff.y / absDiff.y, 0);
            } else {
                surfaceNormal = vec3(0, 0, diff.z / absDiff.z);
            }
            closestObject = ObjectData(
                i + numObjectsPerType,
                insideCubeMaterial[i],
                // -1,
                0.5 + diff / insideCubeDim,
                -dist,
                vec4(0.0),
                surfaceNormal
            );
            closestObject.colour = getColour(closestObject);
        }
    }
    return closestObject;
}


uniform lowp vec4 sphereData[numObjectsPerType];
uniform lowp int sphereMaterial[numObjectsPerType];
uniform lowp int sphereCount;
highp ObjectData sphereDistanceEstimator(in vec3 pos, ObjectData closestObject) {
    for (int i = 0; i < sphereCount; i ++) {
        vec4 sphere = sphereData[i];
        vec3 diff = sphere.xyz - pos;
        highp float dist = length(diff) - sphere.w;
        if (dist < closestObject.dist) {
            closestObject = ObjectData(
                i + 2 * numObjectsPerType,
                sphereMaterial[i],
                0.5 + diff / vec3(sphere.w, sphere.w, sphere.w),
                dist,
                vec4(0.0),
                normalize(pos - sphere.xyz)
            );
            closestObject.colour = getColour(closestObject);
        }
    }
    return closestObject;
}


uniform lowp vec3 cylinderData[2 * numObjectsPerType];
uniform lowp int cylinderMaterial[numObjectsPerType];
uniform lowp int cylinderCount;
highp ObjectData cylinderDistanceEstimator(in vec3 pos, ObjectData closestObject) {
    for (int i = 0; i < cylinderCount / 2; i ++) {
        vec3 cylinderPos = cylinderData[i * 2];
        float radius = cylinderData[i * 2 + 1].x;
        float height = cylinderData[i * 2 + 1].y;

        vec3 relativePos = cylinderPos - pos;
        vec2 posDiff = vec2(
            max(length(relativePos.xy) - radius, 0),
            max(abs(relativePos.z) - height / 2, 0)
        );
        float dist;
        if (posDiff.x + posDiff.y == 0) {
            dist = max(length(relativePos.xz) - radius, abs(relativePos.y) - height / 2);
        } else {
            dist = length(posDiff);
        }

        if (dist < closestObject.dist) {
            vec3 diff = pos - cylinderPos;
            vec3 surfaceNormal;
            if (length(relativePos.xy) < radius) {
                surfaceNormal = normalize(vec3(0, 0, diff.z));
            } else {
                surfaceNormal = normalize(vec3(diff.x, diff.y, 0));
            }
            closestObject = ObjectData(
                i + 3 * numObjectsPerType,
                cylinderMaterial[i],
                0.5 + diff / vec3(radius, radius, height),
                dist,
                vec4(0.0),
                surfaceNormal
            );
            closestObject.colour = getColour(closestObject);
        }
    }
    return closestObject;
}

highp ObjectData distanceEstimator(in vec3 pos) {
    ObjectData closestObject = ObjectData(-1, -1, vec3(0), maxDistance, vec4(0), vec3(0));
    closestObject = cubeDistanceEstimator(pos, closestObject);
    closestObject = insideCubeDistanceEstimator(pos, closestObject);
    closestObject = sphereDistanceEstimator(pos, closestObject);
    closestObject = cylinderDistanceEstimator(pos, closestObject);
    return closestObject;
}


highp vec4 lightPoint(in ObjectData rayClosestObject, in vec3 pos) {
    highp vec4 outColour = vec4(0);
    for (int i = 0; i < lightCount; i++) {
        highp float dist = length(lightPositions[i] - pos);
        if (dist > lightMaxRange) {
            continue;
        }

        mediump float distanceTravelled = 0.0;
        vec3 shadowRayPos = lightPositions[i].xyz;
        vec3 shadowRayDirNorm = normalize(-lightPositions[i] + pos);

        highp float normDot = dot(shadowRayDirNorm, rayClosestObject.surfaceNormal);
        if (normDot > 0) {
            continue;
        }

        highp float pointVisibility = 1.0;
        highp float lightAngleVisibility = length(normDot)
            / (length(shadowRayDirNorm) * length(rayClosestObject.surfaceNormal));

        while (distanceTravelled < dist - collisionTolerance) {
            highp ObjectData closestObject = distanceEstimator(shadowRayPos);
            distanceTravelled += closestObject.dist;
            if (closestObject.dist < collisionTolerance) {
                if (closestObject.id != rayClosestObject.id) {
                    pointVisibility = 0.0;
                }
                break;
            }
            shadowRayPos += shadowRayDirNorm * closestObject.dist;
        }
        highp float inverseDist = 1 - dist / lightMaxRange;
        outColour += rayClosestObject.colour * lightColours[i]
            * inverseDist * inverseDist
            * lightBrightnesses[i]
            * lightAngleVisibility
            * pointVisibility;
    }
    return max(outColour, rayClosestObject.colour * globalMinLight);
}


mediump vec4 rayMarch(in vec3 pos, in vec3 dirNorm) {
    mediump float distanceTravelled = 0.0;
    lowp int reflections = 0;
    highp float accumulatedReflectance = 1.0;
    highp float totalInverseReflectance = 1.0;
    vec4 accumulatedColour = vec4(0.0, 0.0, 0.0, 1.0);
    while (distanceTravelled < maxDistance) {
        highp ObjectData closestObject = distanceEstimator(pos);
        distanceTravelled += closestObject.dist;
        if (closestObject.dist < collisionTolerance) {
            highp float inverseReflectance = 1 - materialReflectances[closestObject.materialIndex];
            highp vec4 colour = accumulatedReflectance * lightPoint(closestObject, pos)
                * (1 - materialReflectances[closestObject.materialIndex]);
            accumulatedColour = (accumulatedColour * totalInverseReflectance + colour)
                / (totalInverseReflectance + inverseReflectance);
            accumulatedReflectance *= materialReflectances[closestObject.materialIndex];
            reflections += 1;
            totalInverseReflectance += inverseReflectance;
            if (reflections > maxReflections || accumulatedReflectance < 0.05) {
                break;
            }
            distanceTravelled = 0.0;
            dirNorm -= 2 * dot(dirNorm, -closestObject.surfaceNormal) * -closestObject.surfaceNormal;
            pos += dirNorm * collisionTolerance;
            ObjectData obj = distanceEstimator(pos);
        }
        pos += dirNorm * closestObject.dist;
    }
    return accumulatedColour;
}

vec4 effect(in vec4 inColour, in sampler2D texture, in vec2 textureCoords, in vec2 screenCoords) {
    vec4 colour = vec4(0);
    vec2 coords = dimensions * textureCoords;
    highp float rangeExtreme = 0.5 - 1 / (2 * samplesPerAxis);

    for (highp float x = -rangeExtreme; x < 0.5; x += 1 / samplesPerAxis) {
        for (highp float y = -rangeExtreme; y < 0.5; y += 1 / samplesPerAxis) {
            vec2 adjustedOffset = (coords + vec2(x, y)) / dimensions;
            vec2 relativeOffset = (adjustedOffset - vec2(0.5)) * vec2(dimensions.x / dimensions.y, 1);
            vec3 relativeDir = vec3(cameraViewPortDist, -relativeOffset.x, relativeOffset.y);
            vec3 dirNorm = normalize(cameraRotationMatrix * relativeDir);

            colour += rayMarch(cameraPos, dirNorm);
        }
    }
    return colour / (samplesPerAxis * samplesPerAxis);
}
