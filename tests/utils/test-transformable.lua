local test = {}

local Transformable = require 'src.utils.transformable'

function test.addAbsolutePosition()
    local transformable = Transformable({position = {1, 2, 3}})
    transformable:addAbsolutePosition(3, 2, 1)
    assertEquals(transformable.position, {4, 4, 4})
end

function test.addRelativePosition()
    local transformable = Transformable({position = {1, 2, 3}})
    transformable.rotationMatrix = {{0, 0, 1}, {0, 1, 0}, {1, 0, 0}}
    transformable:addRelativePosition(3, 2, 1)
    assertEquals(transformable.position, {2, 4, 6})
end

function test.addRotation()
    local transformable = Transformable({position = {0, 0, 0}, rotation = {1, 2, 3}})
    transformable:addRotation(3, 2, 1)
    assertEquals(transformable.rotationData, {4, 4, 4})
end

return test
