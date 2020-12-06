#define numMaterials 25
#define numLights 20
#define numObjectsPerType 20
#define rayMarchMaxStackSize 10

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
};

struct Ray {
    highp vec3 pos;
    lowp int inMaterial;
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
ObjectData cubeDistanceEstimator(in Ray ray, ObjectData closestObject) {
    for (int i = 0; i < cubeCount / 2; i ++) {
        vec3 cubePos = cubeData[i * 2];
        vec3 cubeDim = cubeData[i * 2 + 1];
        mediump vec3 diff = max(cubePos - cubeDim / 2 - ray.pos, max(vec3(0), ray.pos - cubePos - cubeDim / 2));
        highp float dist;
        if (diff == vec3(0)) {
            vec3 distVec = abs(ray.pos - cubePos) - cubeDim / 2;
            dist = max(distVec.x, max(distVec.y, distVec.z));
        } else {
            dist = length(diff);
        }
        if (dist < closestObject.dist) {
            vec3 diff = ray.pos - cubePos;
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
ObjectData insideCubeDistanceEstimator(in Ray ray, ObjectData closestObject) {
    for (int i = 0; i < insideCubeCount / 2; i ++) {
        vec3 insideCubePos = insideCubeData[i * 2];
        vec3 insideCubeDim = insideCubeData[i * 2 + 1];
        mediump vec3 diff = max(insideCubePos - insideCubeDim / 2 - ray.pos, max(vec3(0), ray.pos - insideCubePos - insideCubeDim / 2));
        highp float dist;
        if (diff == vec3(0)) {
            vec3 distVec = abs(ray.pos - insideCubePos) - insideCubeDim / 2;
            dist = max(distVec.x, max(distVec.y, distVec.z));
        } else {
            dist = length(diff);
        }
        if (-dist < closestObject.dist) {
            vec3 diff = insideCubePos - ray.pos;
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
highp ObjectData sphereDistanceEstimator(in Ray ray, ObjectData closestObject) {
    for (int i = 0; i < sphereCount; i ++) {
        vec4 sphere = sphereData[i];
        vec3 diff = sphere.xyz - ray.pos;
        highp float dist = length(diff) - sphere.w;
        if (dist < closestObject.dist) {
            closestObject = ObjectData(
                i + 2 * numObjectsPerType,
                sphereMaterial[i],
                0.5 + diff / vec3(sphere.w, sphere.w, sphere.w),
                dist,
                vec4(0.0),
                normalize(ray.pos - sphere.xyz)
            );
            closestObject.colour = getColour(closestObject);
        }
    }
    return closestObject;
}


uniform lowp vec3 cylinderData[2 * numObjectsPerType];
uniform lowp int cylinderMaterial[numObjectsPerType];
uniform lowp int cylinderCount;
highp ObjectData cylinderDistanceEstimator(in Ray ray, ObjectData closestObject) {
    for (int i = 0; i < cylinderCount / 2; i ++) {
        vec3 cylinderPos = cylinderData[i * 2];
        float radius = cylinderData[i * 2 + 1].x;
        float height = cylinderData[i * 2 + 1].y;

        vec3 diff = ray.pos - cylinderPos;
        vec2 posDiff = vec2(
            max(length(diff.xy) - radius, 0),
            max(abs(diff.z) - height / 2, 0)
        );
        float dist;
        if (posDiff.x + posDiff.y == 0) {
            dist = max(length(diff.xz) - radius, abs(diff.y) - height / 2);
        } else {
            dist = length(posDiff);
        }

        if (dist < closestObject.dist) {
            vec3 surfaceNormal;
            if (length(diff.xy) < radius) {
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


highp ObjectData distanceEstimator(in Ray ray) {
    ObjectData closestObject = ObjectData(-1, -1, vec3(0), maxDistance, vec4(0), vec3(0));
    closestObject = cubeDistanceEstimator(ray, closestObject);
    closestObject = insideCubeDistanceEstimator(ray, closestObject);
    closestObject = sphereDistanceEstimator(ray, closestObject);
    closestObject = cylinderDistanceEstimator(ray, closestObject);
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
            highp ObjectData closestObject = distanceEstimator(Ray(shadowRayPos, -1));
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

// Use recursion for refraction where there's a maximum "refraction" depth (aka recursion depth)

struct RayMarchAR {
    Ray ray;
    vec3 dirNorm;
    float rayStrength;
    int refractionDepth;
    float distanceTravelled;
    float accumulatedReflectance;
    float totalInverseReflectance;
};
mediump vec4 rayMarch(in Ray ray, in vec3 dirNorm, in float rayStrength, in int refractionDepth, inout RayMarchAR recursiveStack, inout int stackIndex) {
    mediump float distanceTravelled = 0.0;
    lowp int reflections = 0;
    highp float raySpeed = ray.inMaterial < 0 ? spaceSpeedOfLight : materialSpeedsOfLight[ray.inMaterial];
    highp float accumulatedReflectance = 1.0;
    highp float totalInverseReflectance = 1.0;
    vec4 accumulatedColour = vec4(0.0, 0.0, 0.0, 1.0);
    while (distanceTravelled < maxDistance) {
        highp ObjectData closestObject = distanceEstimator(ray);
        highp float objSpeedOfLight = materialSpeedsOfLight[closestObject.materialIndex];
        if (raySpeed == objSpeedOfLight && objSpeedOfLight != spaceSpeedOfLight) {
            closestObject.dist *= -1;
        }
        distanceTravelled += closestObject.dist;
        if (closestObject.dist < collisionTolerance) {
            highp float inverseReflectance = 1 - materialReflectances[closestObject.materialIndex];
            highp vec4 colour = rayStrength * accumulatedReflectance * lightPoint(closestObject, ray.pos)
                * (1 - materialReflectances[closestObject.materialIndex]);
            accumulatedColour = (accumulatedColour * totalInverseReflectance + colour)
                / (totalInverseReflectance + inverseReflectance);
            accumulatedReflectance *= materialReflectances[closestObject.materialIndex];
            reflections += 1;
            totalInverseReflectance += inverseReflectance;
            if (reflections > maxReflections || rayStrength * accumulatedReflectance < 0.05) {
                break;
            }
            vec3 boundaryNormal = dot(closestObject.surfaceNormal, dirNorm) >= 0
                ? closestObject.surfaceNormal.xyz
                : -closestObject.surfaceNormal.xyz;
            float nextRaySpeed = closestObject.dist < 0 ? materialSpeedsOfLight[closestObject.materialIndex] : raySpeed;
            float n = raySpeed / nextRaySpeed;
            float cosI = dot(boundaryNormal, dirNorm);
            float sinT2 = n * n * (1.0 - cosI * cosI);
            if (sinT2 <= 1.0 && refractionDepth < maxRefractionDepth && stackIndex < rayMarchMaxStackSize - 1) {
                rayStrength *= 1 - materialTransparencies[closestObject.materialIndex];
                float cosT = sqrt(1.0 - sinT2);
                vec3 refractedDir = n * dirNorm + (n * cosI - cosT) * boundaryNormal;
                accumulatedColour = rayMarch(
                    Ray(
                        ray.pos.xyz + refractedDir * collisionTolerance,
                        closestObject.materialIndex
                    ),
                    refractedDir,
                    rayStrength * materialTransparencies[closestObject.materialIndex],
                    refractionDepth + 1
                );
            }
            distanceTravelled = 0.0;
            dirNorm -= 2 * dot(dirNorm, -closestObject.surfaceNormal) * -closestObject.surfaceNormal;
            ray.pos += dirNorm * collisionTolerance;
        }
        ray.pos += dirNorm * closestObject.dist;
    }
    return accumulatedColour;
}

mediump vec4 rayMarch(in Ray ray, in vec3 dirNorm) {
    vec4 accumulatedColour = vec4(0.0, 0.0, 0.0, 1.0);
    RayMarchAR rayMarchRecursionStack[rayMarchMaxStackSize];
    int recursiveIndex = 0;
    return rayMarch(ray, dirNorm, 1.0, 0);
}

vec4 effect(in vec4 inColour, in sampler2D texture, in vec2 textureCoords, in vec2 screenCoords) {
    vec4 colour = vec4(0);
    vec2 coords = dimensions * textureCoords;
    highp float rangeExtreme = 0.5 - 1 / (2 * samplesPerAxis);

    int materialIndex = -1;
    ObjectData closestObject = distanceEstimator(Ray(cameraPos, materialIndex));
    if (closestObject.dist < 0) {
        materialIndex = closestObject.materialIndex;
    }

    for (highp float x = -rangeExtreme; x < 0.5; x += 1 / samplesPerAxis) {
        for (highp float y = -rangeExtreme; y < 0.5; y += 1 / samplesPerAxis) {
            vec2 adjustedOffset = (coords + vec2(x, y)) / dimensions;
            vec2 relativeOffset = (adjustedOffset - vec2(0.5)) * vec2(dimensions.x / dimensions.y, 1);
            vec3 relativeDir = vec3(cameraViewPortDist, -relativeOffset.x, relativeOffset.y);
            vec3 dirNorm = normalize(cameraRotationMatrix * relativeDir);

            colour += rayMarch(Ray(cameraPos, materialIndex), dirNorm);
        }
    }
    return colour / (samplesPerAxis * samplesPerAxis);
}
