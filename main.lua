local Scene, scene = require 'src.scene'

function love.load()
    scene = Scene()
end

function love.draw(dt)
    love.graphics.setShader()
    scene:draw(0, 0, love.graphics.getDimensions())
end
