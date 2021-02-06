local classUtilities = require 'src.class-utilities'
local OBJECT_HANDLERS = {
    ['cube'] = function(data)
        return classUtilities.validateOrComplain(
            {data.width, data.height, data.depth},
            {'number', 'number', 'number'},
            'Invalid cube data'
        )
    end,
    ['insideCube'] = function(data)
        return classUtilities.validateOrComplain(
            {data.width, data.height, data.depth},
            {'number', 'number', 'number'},
            'Invalid insideCube data'
        )
    end,
    ['sphere'] = function(data)
        return classUtilities.validateOrComplain(data.radius, 'number', 'Invalid sphere data')
    end,
    ['cylinder'] = function(data)
        return classUtilities.validateOrComplain(
            {data.radius, data.height},
            {'number', 'number'},
            'Invalid cylinder data'
        )
    end
}

return function(args)
    local object = {class = 'Object'}

    assert(args.material and args.material.class == 'Material', 'Objects must have a material argument!')
    assert(OBJECT_HANDLERS[args.type] ~= nil, 'Object type "' .. args.type .. '" does not exist')
    object.type = args.type
    object.material = args.material
    object.data = OBJECT_HANDLERS[args.type](args.data)

    local rotation = classUtilities.validateOrDefault(args.rotation, {0, 0, 0})
    object.rotationMatrix =
        classUtilities.rotationToMatrix({yaw = rotation[1], pitch = rotation[2], roll = rotation[3]})
    object.scale = classUtilities.validateOrDefault(args.scale, {1, 1, 1})
    object.position =
        classUtilities.validateOrComplain(args.position, {'number', 'number', 'number'}, 'Invalid object position')

    function object:setRotation(yaw, pitch, roll)
        self.rotationMatrix = classUtilities.rotationToMatrix({yaw = yaw, pitch = pitch, roll = roll})
    end

    return object
end
