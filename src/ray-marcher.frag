#define numMaterials 25
#define numLights 20
#define numObjectsPerType 20
#define rayMarchMaxStackSize 6
#define rayCollisionOffset collisionTolerance * 3

uniform lowp vec2 dimensions;
uniform lowp float maxDistance;
uniform highp float globalMinLight;
uniform mediump float collisionTolerance;
uniform lowp float samplesPerAxis;
uniform lowp int maxReflections;
uniform lowp int maxRefractionDepth;
uniform highp float spaceSpeedOfLight;
uniform highp float softShadowAngle;

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
    highp vec3 dirNorm;
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
        Ray shadowRay = Ray(lightPositions[i].xyz, normalize(-lightPositions[i] + pos), -1);

        highp float normDot = dot(shadowRay.dirNorm, rayClosestObject.surfaceNormal);
        if (normDot > 0) {
            continue;
        }

        highp float pointVisibility = 1.0;
        highp float lightAngleVisibility = length(normDot)
            / (length(shadowRay.dirNorm) * length(rayClosestObject.surfaceNormal));

        highp ObjectData closestPathObject = ObjectData(-1, -1, vec3(0), maxDistance, vec4(0), vec3(0));
        highp vec3 closestPathPos = shadowRay.pos;

        while (distanceTravelled < dist - collisionTolerance && pointVisibility > 0.05) {
            highp ObjectData closestObject = distanceEstimator(shadowRay);
            highp float theta = asin(closestPathObject.dist / length(shadowRay.pos - closestPathPos));
            pointVisibility = min(theta / softShadowAngle, pointVisibility);
            if (abs(closestObject.dist) < abs(closestPathObject.dist)) {
                closestPathObject = closestObject;
                closestPathPos = shadowRay.pos;
            }
            distanceTravelled += closestObject.dist;
            if (closestObject.dist < collisionTolerance) {
                if (closestObject.id != rayClosestObject.id) {
                    pointVisibility = 0.0;
                }
                break;
            }
            shadowRay.pos += shadowRay.dirNorm * closestObject.dist;
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

struct RayMarchAR {
    Ray ray;
    int refractionDepth;
    float rayStrength;
    float distanceTravelled;
    int reflections;
} stackFrames[rayMarchMaxStackSize];
mediump vec4 rayMarch(in Ray ray) {
    stackFrames[0] = RayMarchAR(
        ray,
        0,
        1.0,
        0.0,
        0
    );
    lowp int stackIndex = 0;
    lowp int lastStackIndex = 0;
    RayMarchAR ar = stackFrames[0];
    highp float raySpeed = ar.ray.inMaterial < 0 ? spaceSpeedOfLight : materialSpeedsOfLight[ar.ray.inMaterial];
    vec4 accumulatedColour = vec4(0.0, 0.0, 0.0, 1.0);
    float accumulatedStrength = 1.0;
    while (stackIndex >= 0) {
        if (lastStackIndex != stackIndex) {
            stackFrames[lastStackIndex] = ar;
            ar = stackFrames[stackIndex];
            raySpeed = ar.ray.inMaterial < 0 ? spaceSpeedOfLight : materialSpeedsOfLight[ar.ray.inMaterial];
            lastStackIndex = stackIndex;
        }
        if (ar.distanceTravelled >= maxDistance || ar.rayStrength < 0.05) {
            stackIndex -= 1;
            continue;
        }
        highp ObjectData closestObject = distanceEstimator(ar.ray);
        highp float objSpeedOfLight = materialSpeedsOfLight[closestObject.materialIndex];
        closestObject.dist = abs(closestObject.dist);
        ar.distanceTravelled += closestObject.dist;
        if (closestObject.dist < collisionTolerance) {
            float strength = ar.rayStrength
                * (1 - materialReflectances[closestObject.materialIndex])
                * (1 - materialTransparencies[closestObject.materialIndex]);
            accumulatedStrength += strength;
            accumulatedColour += strength * lightPoint(closestObject, ar.ray.pos);
            ar.reflections += 1;
            if (ar.reflections > maxReflections || ar.rayStrength < 0.05) {
                stackIndex -= 1;
                continue;
            }
            vec3 boundaryNormal = dot(closestObject.surfaceNormal, ar.ray.dirNorm) >= 0
                ? -closestObject.surfaceNormal
                : closestObject.surfaceNormal;

            float n = objSpeedOfLight / raySpeed;

            float cosI = dot(boundaryNormal, ar.ray.dirNorm);
            float cosRSqr = 1 - (n * n * (1 - cosI * cosI));
            if (
                cosRSqr >= 0
                && materialTransparencies[closestObject.materialIndex] > 0.0
                && ar.refractionDepth < maxRefractionDepth
                && stackIndex < rayMarchMaxStackSize - 1
            ) {
                vec3 refractedDir = n * (ar.ray.dirNorm - cosI * boundaryNormal) - sqrt(cosRSqr) * boundaryNormal;
                stackIndex += 1;
                stackFrames[stackIndex] = RayMarchAR(
                    Ray(
                        ar.ray.pos + refractedDir * rayCollisionOffset,
                        refractedDir,
                        closestObject.materialIndex
                    ),
                    ar.refractionDepth + 1,
                    ar.rayStrength * materialTransparencies[closestObject.materialIndex],
                    0.0,
                    0
                );
                ar.rayStrength *= 1 - materialTransparencies[closestObject.materialIndex];
            }
            ar.rayStrength *= materialReflectances[closestObject.materialIndex];
            ar.distanceTravelled = 0.0;
            ar.ray.dirNorm -= 2 * dot(ar.ray.dirNorm, -closestObject.surfaceNormal) * -closestObject.surfaceNormal;
            ar.ray.pos += ar.ray.dirNorm * collisionTolerance;
        }
        ar.ray.pos += ar.ray.dirNorm * closestObject.dist;
    }
    return accumulatedColour / accumulatedStrength;
}

vec4 effect(in vec4 inColour, in sampler2D texture, in vec2 textureCoords, in vec2 screenCoords) {
    vec4 colour = vec4(0);
    vec2 coords = dimensions * textureCoords;
    highp float rangeExtreme = 0.5 - 1 / (2 * samplesPerAxis);

    int materialIndex = -1;
    ObjectData closestObject = distanceEstimator(Ray(cameraPos, vec3(0), materialIndex));
    if (closestObject.dist < 0) {
        materialIndex = closestObject.materialIndex;
    }

    for (highp float x = -rangeExtreme; x < 0.5; x += 1 / samplesPerAxis) {
        for (highp float y = -rangeExtreme; y < 0.5; y += 1 / samplesPerAxis) {
            vec2 adjustedOffset = (coords + vec2(x, y)) / dimensions;
            vec2 relativeOffset = (adjustedOffset - vec2(0.5)) * vec2(dimensions.x / dimensions.y, 1);
            vec3 relativeDir = vec3(cameraViewPortDist, -relativeOffset.x, relativeOffset.y);
            vec3 dirNorm = normalize(cameraRotationMatrix * relativeDir);

            colour += rayMarch(Ray(cameraPos, dirNorm, materialIndex));
        }
    }
    return colour / (samplesPerAxis * samplesPerAxis);
}
