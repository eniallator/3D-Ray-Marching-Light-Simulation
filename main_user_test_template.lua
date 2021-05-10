local RayMarcher = require 'src.ray-marcher'
local keys = require 'src.utils.keys'
local viewAngleSensitivity, positionSensitivity = 0.005, 30

local scene, sphere
function love.load()
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
        local xSign = (scene.camera.rotationData[2] + math.pi / 2) % (2 * math.pi) < math.pi and 1 or -1
        local relativeRotationOffset = {
            yaw = xSign * dx * viewAngleSensitivity,
            pitch = dy * viewAngleSensitivity
        }
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
end

function love.draw(dt)
    love.graphics.print('FPS: ' .. love.timer.getFPS(), 10, 10)
end
