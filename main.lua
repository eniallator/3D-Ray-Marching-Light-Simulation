local Scene, scene = require 'src.scene'

function love.load()
    scene = Scene()
    scene:addCube(50, 10, -60, 40, 40, 40)
    scene:addCube(50, 10, 20, 40, 40, 40)
    scene:addSphere(70, -10, 40, 20)
end

function love.draw(dt)
    love.graphics.setShader()
    scene:draw(0, 0, love.graphics.getDimensions())
end
