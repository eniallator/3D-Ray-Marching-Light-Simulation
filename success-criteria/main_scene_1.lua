local RayMarcher = require 'src.ray-marcher'
local keys = require 'src.utils.keys'
local viewAngleSensitivity = 0.005
local positionSensitivity = 30

local scene
function love.load()
    scene =
        RayMarcher.Scene(
        {
            maxDistance = math.sqrt(100 * 100 * 3),
            globalMinLight = 0.15,
            collisionTolerance = 0.01,
            samplesPerPixelPerAxis = 3,
            lightMaxRange = 200,
            maxReflections = 3,
            maxRefractionDepth = 3,
            spaceSpeedOfLight = 300,
            softShadowAngle = 0.02
        }
    )
    scene.camera:setPosition(-40, 0, 0)

    local roomMaterial = RayMarcher.Material()
    scene:registerMaterial(roomMaterial)
    local reflective = RayMarcher.Material({reflectance = 1})
    scene:registerMaterial(reflective)

    local sphere =
        RayMarcher.Object({type = 'sphere', material = reflective, position = {0, 25, 0}, data = {radius = 5}})
    scene:registerObject(sphere)
    local room =
        RayMarcher.Object(
        {
            type = 'insideCube',
            material = roomMaterial,
            position = {0, 0, 0},
            data = {width = 100, height = 100, depth = 100}
        }
    )
    scene:registerObject(room)
    scene:registerLight(
        RayMarcher.Light(
            {
                position = {0, -25, 0},
                brightness = 1.2
            }
        )
    )

    scene:loadAllData()
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
        local xSign = (scene.camera.rotationData[2] + math.pi / 2) % (2 * math.pi) < math.pi and 1 or -1
        scene.camera:addRotation(xSign * dx * viewAngleSensitivity, dy * viewAngleSensitivity)
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
end

function love.draw(dt)
    scene:draw(0, 0, love.graphics.getDimensions())
    love.graphics.print('FPS: ' .. love.timer.getFPS(), 10, 10)
end
