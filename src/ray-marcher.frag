#define numMaterials 25
#define numLights 20
#define numObjectsPerType 20
#define rayMarchMaxStackSize 6
#define rayCollisionOffset collisionTolerance * 8
#define mandelbulbBailNumber 100
#define boundingOffset collisionTolerance * 6

uniform lowp vec2 dimensions;
uniform lowp float maxDistance;
uniform highp float globalMinLight;
uniform mediump float collisionTolerance;
uniform lowp float samplesPerPixelPerAxis;
uniform lowp int maxReflections;
uniform lowp int maxRefractionDepth;
uniform highp float spaceSpeedOfLight;
uniform highp float softShadowAngle;
uniform lowp int ambientOcclusionSamples;
uniform highp float ambientOcclusionMaxHeight;
uniform highp float ambientOcclusionStrength;

uniform highp vec3 cameraPos;
uniform highp mat3 cameraRotationMatrix;
uniform highp float cameraViewportDist;

uniform highp vec3 lightPositions[numLights];
uniform highp vec4 lightColours[numLights];
uniform highp float lightBrightnesses[numLights];
uniform lowp int lightCount;
uniform highp float lightMaxRange;

uniform highp vec4 materialColours[numMaterials];
uniform highp float materialReflectances[numMaterials];
uniform highp float materialSpeedsOfLight[numMaterials];
uniform highp float materialTransparencies[numMaterials];
uniform highp float materialGlowStrengths[numMaterials];
uniform highp float materialGlowRanges[numMaterials];
uniform highp vec4 materialGlowColours[numMaterials];

struct ObjectData {
    mediump int id;
    lowp int materialIndex;
    highp float dist;
    highp vec3 surfaceNormal;
    highp vec4 colour;
    highp vec4 emittedColour;
    highp float emittedStrength;
};

struct Ray {
    highp vec3 pos;
    highp vec3 dirNorm;
    lowp int inMaterial;
};


void setColour(inout ObjectData object) {
    if (object.materialIndex < 0) {
        return;
    }
    object.colour = materialColours[object.materialIndex];
}

void setGlow(inout ObjectData object, in int materialIndex, in float dist) {
    if (materialIndex < 0
        || materialGlowRanges[materialIndex] == 0.0
        || dist > materialGlowRanges[materialIndex]) {
        return;
    }
    highp float strength = materialGlowStrengths[materialIndex] * (
        1.0 - (dist / materialGlowRanges[materialIndex])
    );
    strength *= strength;
    object.emittedStrength += strength;
    object.emittedColour += strength * materialGlowColours[materialIndex];
}

highp vec3 applyTransformation(in vec3 position, in vec3 scale, in mat3 rotation) {
    return (position * transpose(rotation)) / scale;
}

highp vec3 undoRotation(in vec3 normal, in mat3 rotation) {
    return normal * rotation;
}


uniform lowp int cubeCount;
uniform lowp int cubeMaterial[numObjectsPerType];
uniform lowp vec3 cubePosition[numObjectsPerType];
uniform lowp vec3 cubeScale[numObjectsPerType];
uniform lowp mat3 cubeRotation[numObjectsPerType];
uniform lowp vec3 cubeData[numObjectsPerType];
ObjectData cubeDistanceEstimator(in Ray ray, ObjectData closestObject) {
    for (int i = 0; i < cubeCount; i ++) {
        vec3 relativePos = applyTransformation(cubePosition[i] - ray.pos, cubeScale[i], cubeRotation[i]);
        vec3 cubeDim = cubeData[i];
        mediump vec3 diff = max(relativePos - cubeDim / 2, max(vec3(0), -relativePos - cubeDim / 2));
        highp float dist;
        if (diff == vec3(0)) {
            vec3 distVec = abs(relativePos) - cubeDim / 2;
            dist = max(distVec.x, max(distVec.y, distVec.z));
        } else {
            dist = length(diff);
        }
        if (dist < closestObject.dist) {
            vec3 diff = -relativePos;
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
                dist,
                undoRotation(surfaceNormal, cubeRotation[i]),
                vec4(0.0),
                closestObject.emittedColour,
                closestObject.emittedStrength
            );
            setColour(closestObject);
        }
        setGlow(closestObject, cubeMaterial[i], dist);
    }
    return closestObject;
}


uniform lowp int insideCubeCount;
uniform lowp int insideCubeMaterial[numObjectsPerType];
uniform lowp vec3 insideCubePosition[numObjectsPerType];
uniform lowp vec3 insideCubeScale[numObjectsPerType];
uniform lowp mat3 insideCubeRotation[numObjectsPerType];
uniform lowp vec3 insideCubeData[numObjectsPerType];
ObjectData insideCubeDistanceEstimator(in Ray ray, ObjectData closestObject) {
    for (int i = 0; i < insideCubeCount; i ++) {
        vec3 relativePos = applyTransformation(insideCubePosition[i] - ray.pos, insideCubeScale[i], insideCubeRotation[i]);
        vec3 insideCubeDim = insideCubeData[i];
        mediump vec3 diff = max(relativePos - insideCubeDim / 2, max(vec3(0), -relativePos - insideCubeDim / 2));
        highp float dist;
        if (diff == vec3(0)) {
            vec3 distVec = abs(relativePos) - insideCubeDim / 2;
            dist = max(distVec.x, max(distVec.y, distVec.z));
        } else {
            dist = length(diff);
        }
        if (-dist < closestObject.dist) {
            vec3 diff = relativePos;
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
                -dist,
                undoRotation(surfaceNormal, insideCubeRotation[i]),
                vec4(0.0),
                closestObject.emittedColour,
                closestObject.emittedStrength
            );
            setColour(closestObject);
        }
        setGlow(closestObject, insideCubeMaterial[i], -dist);
    }
    return closestObject;
}


uniform lowp int sphereCount;
uniform lowp int sphereMaterial[numObjectsPerType];
uniform lowp vec3 spherePosition[numObjectsPerType];
uniform lowp vec3 sphereScale[numObjectsPerType];
uniform lowp mat3 sphereRotation[numObjectsPerType];
uniform lowp float sphereData[numObjectsPerType];
highp ObjectData sphereDistanceEstimator(in Ray ray, ObjectData closestObject) {
    for (int i = 0; i < sphereCount; i ++) {
        vec3 relativePos = applyTransformation(spherePosition[i] - ray.pos, sphereScale[i], sphereRotation[i]);
        float radius = sphereData[i];
        highp float dist = length(relativePos) - radius;
        if (dist < closestObject.dist) {
            closestObject = ObjectData(
                i + 2 * numObjectsPerType,
                sphereMaterial[i],
                dist,
                undoRotation(-normalize(relativePos), sphereRotation[i]),
                vec4(0.0),
                closestObject.emittedColour,
                closestObject.emittedStrength
            );
            setColour(closestObject);
        }
        setGlow(closestObject, sphereMaterial[i], dist);
    }
    return closestObject;
}


uniform lowp int cylinderCount;
uniform lowp int cylinderMaterial[numObjectsPerType];
uniform lowp vec3 cylinderPosition[numObjectsPerType];
uniform lowp vec3 cylinderScale[numObjectsPerType];
uniform lowp mat3 cylinderRotation[numObjectsPerType];
uniform lowp vec2 cylinderData[numObjectsPerType];
highp ObjectData cylinderDistanceEstimator(in Ray ray, ObjectData closestObject) {
    for (int i = 0; i < cylinderCount; i ++) {
        vec3 relativePos = applyTransformation(cylinderPosition[i] - ray.pos, cylinderScale[i], cylinderRotation[i]);
        float radius = cylinderData[i].x;
        float height = cylinderData[i].y;

        vec2 clampedRelativePos = vec2(
            max(length(relativePos.xy) - radius, 0),
            max(abs(relativePos.z) - height / 2, 0)
        );
        float dist;
        if (clampedRelativePos.x + clampedRelativePos.y == 0) {
            dist = max(length(relativePos.xz) - radius, abs(relativePos.y) - height / 2);
        } else {
            dist = length(clampedRelativePos);
        }

        if (dist < closestObject.dist) {
            vec3 surfaceNormal;
            if (length(relativePos.xy) < radius) {
                surfaceNormal = normalize(vec3(0, 0, -relativePos.z));
            } else {
                surfaceNormal = normalize(vec3(-relativePos.x, -relativePos.y, 0));
            }
            closestObject = ObjectData(
                i + 3 * numObjectsPerType,
                cylinderMaterial[i],
                dist,
                undoRotation(surfaceNormal, cylinderRotation[i]),
                vec4(0.0),
                closestObject.emittedColour,
                closestObject.emittedStrength
            );
            setColour(closestObject);
        }
        setGlow(closestObject, cylinderMaterial[i], dist);
    }
    return closestObject;
}


uniform lowp int mandelbulbCount;
uniform lowp int mandelbulbMaterial[numObjectsPerType];
uniform lowp vec3 mandelbulbPosition[numObjectsPerType];
uniform lowp vec3 mandelbulbScale[numObjectsPerType];
uniform lowp mat3 mandelbulbRotation[numObjectsPerType];
uniform lowp vec3 mandelbulbData[numObjectsPerType];
highp ObjectData mandelbulbDistanceEstimator(in Ray ray, ObjectData closestObject) {
    for (int i = 0; i < mandelbulbCount; i ++) {
        float boundingRadius = mandelbulbData[i].z;
        vec3 posDiff = mandelbulbPosition[i] - ray.pos;
        float posDiffSquared = posDiff.x * posDiff.x + posDiff.y * posDiff.y + posDiff.z * posDiff.z;
        float dist;
        vec3 relativePos = posDiff;
        bool inBounds = false;
        if (posDiffSquared > boundingRadius * boundingRadius) {
            dist = sqrt(posDiffSquared) - boundingRadius + boundingOffset;
        } else {
            inBounds = true;
            float iterations = mandelbulbData[i].x;
            float power = mandelbulbData[i].y;
            relativePos = applyTransformation(posDiff, mandelbulbScale[i], mandelbulbRotation[i]);
            vec3 z = relativePos;
            float dr = 1.0;
            float r = 0.0;
            for (int j = 0; j < iterations; j++) {
                r = length(z);
                if (r > mandelbulbBailNumber) break;

                float theta = acos(z.z / r);
                float phi = atan(z.y, z.x);
                dr = pow(r, power-1.0) * power * dr + 1.0;

                float zr = pow(r, power);
                theta *= power;
                phi *= power;

                z = zr * vec3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
                z += relativePos;
            }
            dist = (log(r) * r) / (2 * dr);
        }
        if (dist < closestObject.dist) {
            closestObject = ObjectData(
                i + 4 * numObjectsPerType,
                mandelbulbMaterial[i],
                dist,
                inBounds ? undoRotation(-normalize(relativePos), mandelbulbRotation[i]) : -normalize(relativePos),
                vec4(0.0),
                closestObject.emittedColour,
                closestObject.emittedStrength
            );
            setColour(closestObject);
        }
        if (inBounds) {
            setGlow(closestObject, mandelbulbMaterial[i], dist);
        }
    }
    return closestObject;
}


highp ObjectData distanceEstimator(in Ray ray) {
    ObjectData closestObject = ObjectData(-1, -1, maxDistance, vec3(0), vec4(0), vec4(0), 0.0);
    closestObject = cubeDistanceEstimator(ray, closestObject);
    closestObject = insideCubeDistanceEstimator(ray, closestObject);
    closestObject = sphereDistanceEstimator(ray, closestObject);
    closestObject = cylinderDistanceEstimator(ray, closestObject);
    closestObject = mandelbulbDistanceEstimator(ray, closestObject);
    return closestObject;
}


highp vec4 lightPoint(in ObjectData rayClosestObject, in Ray ray) {
    highp vec4 outColour = vec4(0);
    for (int i = 0; i < lightCount; i++) {
        highp float dist = length(lightPositions[i] - ray.pos);
        if (dist > lightMaxRange) {
            continue;
        }

        mediump float distanceTravelled = 0.0;
        Ray shadowRay = Ray(lightPositions[i].xyz, normalize(-lightPositions[i] + ray.pos), -1);

        // Calculating ambient occlusion
        float ambientOcclusionModifier = 1.0;
        for (int i = 1; i <= ambientOcclusionSamples; i ++) {
            float height = i * ambientOcclusionMaxHeight / ambientOcclusionSamples;
            ObjectData closestObject = distanceEstimator(Ray(
                height * rayClosestObject.surfaceNormal + ray.pos,
                rayClosestObject.surfaceNormal,
                ray.inMaterial
            ));
            ambientOcclusionModifier -= (1 - pow(closestObject.dist / height, 2)) / ambientOcclusionSamples;
        }
        ambientOcclusionModifier = 1 - (1 - ambientOcclusionModifier) * ambientOcclusionStrength;

        // Calculating the angle that the light hits the object
        highp float normDot = dot(shadowRay.dirNorm, rayClosestObject.surfaceNormal);
        if (normDot > 0) {
            continue;
        }

        highp float pointVisibility = 1.0;
        highp float lightAngleVisibility = length(normDot)
            / (length(shadowRay.dirNorm) * length(rayClosestObject.surfaceNormal));

        // Calculating if an object is in between the point and the light source
        highp ObjectData closestPathObject = ObjectData(-1, -1, maxDistance, vec3(0), vec4(0), vec4(0), 0.0);
        highp vec3 closestPathPos = shadowRay.pos;

        while (distanceTravelled < dist - collisionTolerance && pointVisibility > 0.05) {
            // If not in the way, calculate the soft shadow
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
        // Inverse square law and putting it together
        highp float inverseDist = 1 - dist / lightMaxRange;
        outColour += rayClosestObject.colour * lightColours[i]
            * inverseDist * inverseDist
            * lightBrightnesses[i]
            * lightAngleVisibility
            * pointVisibility
            * ambientOcclusionModifier;
    }
    return max(outColour, rayClosestObject.colour * globalMinLight);
}

// Ray marching activation record struct, since GLSL does not support recursion
// Needed to handle both reflection + refraction
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

    // These variables hold the output colour - the colour will be divided by the strength in the end
    vec4 accumulatedColour = vec4(0.0, 0.0, 0.0, 1.0);
    float accumulatedStrength = 1.0;

    while (stackIndex >= 0) {
        if (lastStackIndex != stackIndex) {
            // Update the current ar variable
            stackFrames[lastStackIndex] = ar;
            ar = stackFrames[stackIndex];
            raySpeed = ar.ray.inMaterial < 0 ? spaceSpeedOfLight : materialSpeedsOfLight[ar.ray.inMaterial];
            lastStackIndex = stackIndex;
        }
        if (ar.distanceTravelled >= maxDistance || ar.rayStrength < 0.05) {
            stackIndex -= 1;
            continue;
        }

        // Getting scene data
        highp ObjectData closestObject = distanceEstimator(ar.ray);
        highp float objSpeedOfLight = materialSpeedsOfLight[closestObject.materialIndex];
        closestObject.dist = abs(closestObject.dist);
        ar.distanceTravelled += closestObject.dist;

        // If the object glows, add the glow
        accumulatedColour += closestObject.emittedColour * ar.rayStrength;
        accumulatedStrength += closestObject.emittedStrength * ar.rayStrength;

        if (closestObject.dist < collisionTolerance) {
            // Collided with an object, so get the objects colour and add it to the accumulated variables
            float strength = ar.rayStrength
                * (1 - materialReflectances[closestObject.materialIndex])
                * (1 - materialTransparencies[closestObject.materialIndex]);
            accumulatedStrength += strength;
            accumulatedColour += strength * lightPoint(closestObject, ar.ray);

            // If the ray can go no further, throw out the current activation record
            ar.reflections += 1;
            if (ar.reflections > maxReflections || ar.rayStrength < 0.05) {
                stackIndex -= 1;
                continue;
            }

            // Refractions
            vec3 boundaryNormal = dot(closestObject.surfaceNormal, ar.ray.dirNorm) >= 0
                ? -closestObject.surfaceNormal
                : closestObject.surfaceNormal;

            float n = objSpeedOfLight / raySpeed;

            float cosI = dot(boundaryNormal, ar.ray.dirNorm);
            float cosRSqr = 1 - (n * n * (1 - cosI * cosI));
            if (
                cosRSqr >= 0 // If there is an angle of refraction (if not, it's total internal reflection)
                && materialTransparencies[closestObject.materialIndex] > 0.0
                && ar.refractionDepth < maxRefractionDepth
                && stackIndex < rayMarchMaxStackSize - 1
            ) {
                // Make an activation record to handle the refracted ray
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

            // Handling reflections
            ar.rayStrength *= materialReflectances[closestObject.materialIndex];
            ar.distanceTravelled = 0.0;
            ar.ray.dirNorm -= 2 * dot(ar.ray.dirNorm, -closestObject.surfaceNormal) * -closestObject.surfaceNormal;
            ar.ray.pos += ar.ray.dirNorm * collisionTolerance;
        }
        // Move the ray forward
        ar.ray.pos += ar.ray.dirNorm * closestObject.dist;
    }
    return accumulatedColour / accumulatedStrength;
}

vec4 effect(in vec4 inColour, in sampler2D texture, in vec2 textureCoords, in vec2 screenCoords) {
    vec4 colour = vec4(0);
    vec2 coords = dimensions * textureCoords;
    highp float rangeExtreme = 0.5 - 1 / (2 * samplesPerPixelPerAxis);

    int materialIndex = -1;
    ObjectData closestObject = distanceEstimator(Ray(cameraPos, vec3(0), materialIndex));
    if (closestObject.dist < 0) {
        materialIndex = closestObject.materialIndex;
    }

    for (highp float x = -rangeExtreme; x < 0.5; x += 1 / samplesPerPixelPerAxis) {
        for (highp float y = -rangeExtreme; y < 0.5; y += 1 / samplesPerPixelPerAxis) {
            vec2 adjustedOffset = (coords + vec2(x, y)) / dimensions;
            vec2 relativeOffset = (adjustedOffset - vec2(0.5)) * vec2(dimensions.x / dimensions.y, 1);
            vec3 relativeDir = vec3(cameraViewportDist, -relativeOffset.x, relativeOffset.y);
            vec3 dirNorm = normalize(cameraRotationMatrix * relativeDir);

            colour += rayMarch(Ray(cameraPos, dirNorm, materialIndex));
        }
    }
    return colour / (samplesPerPixelPerAxis * samplesPerPixelPerAxis);
}
