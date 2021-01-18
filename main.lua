local Scene, scene = require 'src.scene'
local keys = require 'src.keys'
local viewAngleSensitivity = 0.005
local positionSensitivity = 30

function love.load()
    scene =
        Scene(
        {
            maxDistance = math.sqrt(100 * 100 * 3),
            globalMinLight = 0.15,
            collisionTolerance = 0.01,
            samplesPerAxis = 3,
            lightMaxRange = 200,
            maxReflections = 3,
            maxRefractionDepth = 3,
            spaceSpeedOfLight = 300,
            softShadowAngle = 0.02,
            ambientOcclusionSamples = 10,
            ambientOcclusionMaxHeight = 3,
            ambientOcclusionStrength = 0.2
        }
    )
    scene:addMaterial('room', {1.0, 1.0, 1.0})
    scene:addMaterial('red', {1.0, 0.0, 0.0})
    scene:addMaterial('green', {0.0, 1.0, 0.0}, 0.4, nil, nil, 0.6, 5, {1, 1, 0.3})
    scene:addMaterial('blue', {0.0, 0.0, 1.0})
    scene:addMaterial('chrome', {1.0, 1.0, 1.0}, 1.0)
    scene:addMaterial('water', {0.6, 0.6, 1.0}, 0.4, 0.7, 225)
    scene:addMaterial('glass', {1.0, 1.0, 1.0}, 0.5, 0.9, 200)
    scene:addMaterial('diamond', {1.0, 1.0, 1.0}, 0.5, 0.8, 125)
    scene:addMaterial('hidden', {1.0, 1.0, 1.0}, 1.0, 1.0, 250)

    scene:addObject('insideCube', 'room', {position = {0, 0, 0}}, {width = 100, height = 100, depth = 100})
    scene:addObject(
        'cube',
        'red',
        {position = {0, 10, -10}, scale = {1, 2, 1}, rotation = {math.pi / 4, math.pi / 4, 0}},
        {width = 10, height = 10, depth = 10}
    )
    scene:addObject('cylinder', 'green', {position = {0, 10, 10}}, {radius = 5, height = 10})
    scene:addObject('sphere', 'hidden', {position = {0, -10, 0}}, {radius = 5})

    scene:addLight(-20, -20, 0, nil, nil, nil, 1.2)
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
        local xSign = (scene.camera.pitch + math.pi / 2) % (2 * math.pi) < math.pi and 1 or -1
        scene:offsetCamera(nil, nil, nil, xSign * dx * viewAngleSensitivity, dy * viewAngleSensitivity)
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
    scene:addRelativePosition(relativePosOffset.x, relativePosOffset.y, relativePosOffset.z)
    -- scene.camera.roll = 0 + math.sin(t)
    -- scene:updateRotationMatrix()
end

function love.draw(dt)
    love.graphics.setShader()
    scene:draw(0, 0, love.graphics.getDimensions())
    love.graphics.print('FPS: ' .. love.timer.getFPS(), 10, 10)
end
