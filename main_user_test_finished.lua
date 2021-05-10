local RayMarcher = require 'src.ray-marcher'
local keys = require 'src.utils.keys'
local viewAngleSensitivity, positionSensitivity = 0.005, 30

local scene, sphere
function love.load()
    scene = RayMarcher.Scene({
        softShadowAngle = 0.05,
        globalMinLight = 0.2,
        collisionTolerance = 0.02,
        ambientOcclusionSamples = 4,
        ambientOcclusionMaxHeight = 3.5,
        ambientOcclusionStrength = 0.25
    })

    local roomMaterial = RayMarcher.Material()
    scene:registerMaterial(roomMaterial)
    local room = RayMarcher.Object({
        type = 'insideCube',
        material = roomMaterial,
        position = {0, 0, 0},
        data = {width = 100, height = 100, depth = 100}
    })
    scene:registerObject(room)

    local sphereMaterial = RayMarcher.Material({
        colour = {1, 0, 0},
        transparency = 0.7,
        speedOfLight = 250
    })
    scene:registerMaterial(sphereMaterial)
    sphere = RayMarcher.Object({
        type = 'sphere',
        material = sphereMaterial,
        position = {10, 0, 0},
        data = {radius = 5}
    })
    scene:registerObject(sphere)

    local cubeMaterial = RayMarcher.Material({
        colour = {0, 1, 0},
        reflectance = 0.3
    })
    scene:registerMaterial(cubeMaterial)
    local cube = RayMarcher.Object({
        type = 'cube',
        material = cubeMaterial,
        position = {10, 10, -7},
        data = {width = 10, height = 10, depth = 10}
    })
    scene:registerObject(cube)

    local cylinderMaterial = RayMarcher.Material({
        colour = {1, 1, 0.3},
        glowStrength = 0.2,
        glowRange = 3,
        glowColour = {0, 0, 1}
    })
    scene:registerMaterial(cylinderMaterial)
    local cylinder = RayMarcher.Object({
        type = 'cylinder',
        material = cylinderMaterial,
        position = {10, 10, 7},
        data = {height = 10, radius = 5}
    })
    scene:registerObject(cylinder)

    local light = RayMarcher.Light({
        position = {-20, -20, 0},
        colour = {1, 0.84, 0.88},
        brightness = 1.25
    })
    scene:registerLight(light)

    scene:loadAllData()
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
        local xSign = (scene.camera.rotationData[2] + math.pi / 2) % (2 * math.pi) < math.pi and 1 or -1
        local relativeRotationOffset = {
            yaw = xSign * dx * viewAngleSensitivity,
            pitch = dy * viewAngleSensitivity
        }
        scene.camera:addRotation(relativeRotationOffset.yaw, relativeRotationOffset.pitch)
    end
end

function love.update(dt)
    local relativePosOffset = {
        x = 0,
        y = 0,
        z = 0
    }
    if keys.state.w then
        relativePosOffset.x = relativePosOffset.x + positionSensitivity * dt
    end
    if keys.state.s then
        relativePosOffset.x = relativePosOffset.x - positionSensitivity * dt
    end
    if keys.state.e then
        relativePosOffset.z = relativePosOffset.z + positionSensitivity * dt
    end
    if keys.state.q then
        relativePosOffset.z = relativePosOffset.z - positionSensitivity * dt
    end
    if keys.state.a then
        relativePosOffset.y = relativePosOffset.y + positionSensitivity * dt
    end
    if keys.state.d then
        relativePosOffset.y = relativePosOffset.y - positionSensitivity * dt
    end
    scene.camera:addRelativePosition(relativePosOffset.x, relativePosOffset.y, relativePosOffset.z)

    sphere:addRotation(0, 0, dt)
    sphere:addRelativePosition(0, 0, dt * 10)
    scene:loadObjects()
end

function love.draw(dt)
    scene:draw(0, 0, 800, 600)
    love.graphics.print('FPS: ' .. love.timer.getFPS(), 10, 10)
end
