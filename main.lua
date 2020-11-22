local Scene, scene = require 'src.scene'
local keys = require 'src.keys'
local viewAngleSensitivity = 0.005
local positionSensitivity = 50

function love.load()
    scene = Scene()
    scene:addCube(30, 10, -10, 10, 10, 10)
    scene:addCube(30, 10, 10, 10, 10, 10)
    scene:addInsideCube(0, 0, 0, 100, 100, 100)
    scene:addSphere(30, -10, 10, 5)
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
        scene:offsetCamera(nil, nil, nil, -dx * viewAngleSensitivity, -dy * viewAngleSensitivity)
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
    if keys.state.q then
        relativePosOffset.y = relativePosOffset.y + positionSensitivity * dt
    end
    if keys.state.e then
        relativePosOffset.y = relativePosOffset.y - positionSensitivity * dt
    end
    if keys.state.a then
        relativePosOffset.z = relativePosOffset.z + positionSensitivity * dt
    end
    if keys.state.d then
        relativePosOffset.z = relativePosOffset.z - positionSensitivity * dt
    end
    scene:addRelativePosition(relativePosOffset.x, relativePosOffset.y, relativePosOffset.z)
end

function love.draw(dt)
    love.graphics.setShader()
    scene:draw(0, 0, love.graphics.getDimensions())
end
