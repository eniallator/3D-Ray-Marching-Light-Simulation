local outerFolder = (...):match('(.-)[^%.]+$')

local classUtilities = require(outerFolder .. 'class-utilities')

return function(args)
    local transformable = {}

    transformable.position =
        classUtilities.validateOrComplain(args.position, {'number', 'number', 'number'}, 'Invalid position')
    transformable.scale = classUtilities.validateOrDefault(args.scale, {1, 1, 1})
    transformable.rotationData = classUtilities.validateOrDefault(args.rotation, {0, 0, 0})
    transformable.rotationMatrix = classUtilities.rotationToMatrix(unpack(transformable.rotationData))

    function transformable:setPosition(xOrVec, y, z)
        local pos = classUtilities.getOverloadedVector({xOrVec, y, z})
        self.position = classUtilities.validateOrDefault(pos, self.position)
    end

    function transformable:addAbsolutePosition(xOrVec, y, z)
        local pos = classUtilities.getOverloadedVector({xOrVec, y, z})
        local offset = classUtilities.validateOrDefault(pos, {0, 0, 0})
        self.position = {
            self.position[1] + offset[1],
            self.position[2] + offset[2],
            self.position[3] + offset[3]
        }
    end

    function transformable:addRelativePosition(xOrVec, y, z)
        local pos = classUtilities.getOverloadedVector({xOrVec, y, z})
        local offset = classUtilities.validateOrDefault(pos, {0, 0, 0})
        self.position = {
            self.position[1] + offset[1] * self.rotationMatrix[1][1] + offset[2] * self.rotationMatrix[1][2] +
                offset[3] * self.rotationMatrix[1][3],
            self.position[2] + offset[1] * self.rotationMatrix[2][1] + offset[2] * self.rotationMatrix[2][2] +
                offset[3] * self.rotationMatrix[2][3],
            self.position[3] + offset[1] * self.rotationMatrix[3][1] + offset[2] * self.rotationMatrix[3][2] +
                offset[3] * self.rotationMatrix[3][3]
        }
    end

    function transformable:setScale(xOrVec, y, z)
        local scale = classUtilities.getOverloadedVector({xOrVec, y, z})
        self.scale = classUtilities.validateOrDefault(scale, self.scale)
    end

    function transformable:setRotation(yawOrVec, pitch, roll)
        local rot = classUtilities.getOverloadedVector({yawOrVec, pitch, roll})
        self.rotationData = classUtilities.validateOrDefault(rot, self.rotationData)
        self.rotationMatrix = classUtilities.rotationToMatrix(unpack(self.rotationData))
    end

    function transformable:addRotation(yawOrVec, pitch, roll)
        local rot = classUtilities.getOverloadedVector({yawOrVec, pitch, roll})
        local offset = classUtilities.validateOrDefault(rot, {0, 0, 0})
        self.rotationData = {
            self.rotationData[1] + offset[1],
            self.rotationData[2] + offset[2],
            self.rotationData[3] + offset[3]
        }
        self.rotationMatrix = classUtilities.rotationToMatrix(unpack(self.rotationData))
    end

    return transformable
end
