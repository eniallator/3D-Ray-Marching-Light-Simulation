local classUtilities = require 'src.utils.class-utilities'

return function(args)
    local transformable = {}

    transformable.position =
        classUtilities.validateOrComplain(args.position, {'number', 'number', 'number'}, 'Invalid position')
    transformable.scale = classUtilities.validateOrDefault(args.scale, {1, 1, 1})
    transformable.rotationData = classUtilities.validateOrDefault(args.rotation, {0, 0, 0})
    transformable.rotationMatrix =
        classUtilities.rotationToMatrix(
        {
            yaw = transformable.rotationData[1],
            pitch = transformable.rotationData[2],
            roll = transformable.rotationData[3]
        }
    )

    function transformable:setPosition(x, y, z)
        self.position = classUtilities.validateOrDefault({x, y, z}, self.position)
    end
    function transformable:addWorldPosition(x, y, z)
        local offset = classUtilities.validateOrDefault({x, y, z}, {0, 0, 0})
        self.position = {
            self.position[1] + offset[1],
            self.position[2] + offset[2],
            self.position[3] + offset[3]
        }
    end
    function transformable:addRelativePosition(x, y, z)
        local offset = classUtilities.validateOrDefault({x, y, z}, {0, 0, 0})
        self.position = {
            self.position.x + offset[1] * self.rotationMatrix[1][1] + offset[2] * self.rotationMatrix[1][2] +
                offset[3] * self.rotationMatrix[1][3],
            self.position.y + offset[1] * self.rotationMatrix[2][1] + offset[2] * self.rotationMatrix[2][2] +
                offset[3] * self.rotationMatrix[2][3],
            self.position.z + offset[1] * self.rotationMatrix[3][1] + offset[2] * self.rotationMatrix[3][2] +
                offset[3] * self.rotationMatrix[3][3]
        }
    end
    function transformable:setScale(x, y, z)
        self.scale = classUtilities.validateOrDefault({x, y, z}, self.scale)
    end
    function transformable:setRotation(yaw, pitch, roll)
        self.rotationData = classUtilities.validateOrDefault({yaw, pitch, roll}, self.rotationData)
        self.rotationMatrix =
            classUtilities.rotationToMatrix(
            {yaw = self.rotationData[1], pitch = self.rotationData[2], roll = self.rotationData[3]}
        )
    end
    function transformable:addRotation(yaw, pitch, roll)
        local offset = classUtilities.validateOrDefault({yaw, pitch, roll}, {0, 0, 0})
        self.rotationData = {
            self.rotationData[1] + offset[1],
            self.rotationData[2] + offset[2],
            self.rotationData[3] + offset[3]
        }
        self.rotationMatrix =
            classUtilities.rotationToMatrix(
            {yaw = self.rotationData[1], pitch = self.rotationData[2], roll = self.rotationData[3]}
        )
    end

    return transformable
end
