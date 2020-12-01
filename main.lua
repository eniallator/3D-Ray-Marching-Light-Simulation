local Scene, scene = require 'src.scene'
local keys = require 'src.keys'
local viewAngleSensitivity = 0.005
local positionSensitivity = 30

function love.load()
    scene =
        Scene(
        {
            maxDistance = math.sqrt(100 * 100 * 3),
            globalMinLight = 0.2,
            collisionTolerance = 0.1,
            samplesPerAxis = 3,
            lightMaxRange = 200
        }
    )
    scene:addInsideCube(0, 0, 0, 100, 100, 100)
    scene:addCube(0, 10, -10, 10, 10, 10)
    scene:addCylinder(0, 10, 10, 5, 10)
    scene:addSphere(0, -10, 10, 5)
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
end

function love.draw(dt)
    love.graphics.setShader()
    scene:draw(0, 0, love.graphics.getDimensions())
end
