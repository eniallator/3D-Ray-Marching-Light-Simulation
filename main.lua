local Scene, scene = require 'src.scene'
local keys = require 'src.utils.keys'
local viewAngleSensitivity = 0.005
local positionSensitivity = 30
local Object = require 'src.scene-data.object'
local Light = require 'src.scene-data.light'
local Material = require 'src.scene-data.material'

function love.load()
    scene =
        Scene(
        {
            maxDistance = math.sqrt(100 * 100 * 3),
            globalMinLight = 0.15,
            collisionTolerance = 0.01,
            samplesPerPixelPerAxis = 3,
            lightMaxRange = 200,
            maxReflections = 3,
            maxRefractionDepth = 3,
            spaceSpeedOfLight = 300,
            softShadowAngle = 0.02,
            ambientOcclusionSamples = 5,
            ambientOcclusionMaxHeight = 3,
            ambientOcclusionStrength = 0.2
        }
    )
    scene.camera:setPosition(-40, 0, 0)

    local roomMaterial = Material()
    scene:registerMaterial(roomMaterial)
    local red = Material({colour = {1, 0, 0}})
    scene:registerMaterial(red)
    local green =
        Material(
        {
            colour = {0, 1, 0},
            reflectance = 0.4,
            glowStrength = 0.4,
            glowRange = 5,
            glowColour = {1, 1, 0.3}
        }
    )
    scene:registerMaterial(green)
    local blue = Material({colour = {0, 0, 1}})
    scene:registerMaterial(blue)
    local chrome = Material({reflectance = 1})
    scene:registerMaterial(chrome)
    local water = Material({colour = {0.6, 0.6, 1}, reflectance = 0.4, transparency = 0.7, speedOfLight = 225})
    scene:registerMaterial(water)
    local glass = Material({colour = {0.776, 0.886, 0.89}, reflectance = 1.0, transparency = 0.9, speedOfLight = 200})
    scene:registerMaterial(glass)
    local diamond = Material({reflectance = 0.5, transparency = 0.8, speedOfLight = 125})
    scene:registerMaterial(diamond)
    local hidden = Material({transparency = 1, speedOfLight = 250})
    scene:registerMaterial(hidden)
    local radioactive = Material({colour = {0, 1, 0}, glowStrength = 0.1, glowRange = 0.5, glowColour = {1, 1, 0.3}})
    scene:registerMaterial(radioactive)

    local cube =
        Object(
        {
            type = 'cube',
            material = red,
            position = {0, 10, -10},
            scale = {1, 2, 1},
            rotation = {math.pi / 4, math.pi / 4, 0},
            data = {width = 10, height = 10, depth = 10}
        }
    )
    scene:registerObject(cube)
    local sphere = Object({type = 'sphere', material = hidden, position = {0, -10, 0}, data = {radius = 5}})
    scene:registerObject(sphere)
    local cylinder =
        Object({type = 'cylinder', material = green, position = {0, 10, 10}, data = {radius = 5, height = 10}})
    scene:registerObject(cylinder)
    local mandelbulb =
        Object(
        {
            type = 'mandelbulb',
            material = radioactive,
            position = {0, 0, 0},
            scale = {4, 4, 4},
            data = {iterations = 40, power = 3}
        }
    )
    scene:registerObject(mandelbulb)
    local room =
        Object(
        {
            type = 'insideCube',
            material = roomMaterial,
            position = {0, 0, 0},
            data = {width = 100, height = 100, depth = 100}
        }
    )
    scene:registerObject(room)
    scene:registerLight(
        Light(
            {
                position = {-20, -20, 0},
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
