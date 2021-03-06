local srcFolder = (...):match('(.-)[^%.]+$')
srcFolder = srcFolder:sub(1, -2):match('(.-)[^%.]+$')

local classUtilities = require(srcFolder .. 'utils.class-utilities')
local Transformable = require(srcFolder .. 'utils.transformable')

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
    end,
    ['mandelbulb'] = function(data)
        return classUtilities.validateOrComplain(
            {data.iterations, data.power, data.boundingRadius},
            {'number', 'number', 'number'},
            'Invalid mandelbulb data'
        )
    end
}

return function(args)
    local object = Transformable(args)
    object.class = 'Object'

    assert(args.material and args.material.class == 'Material', 'Objects must have a material argument!')
    assert(OBJECT_HANDLERS[args.type] ~= nil, 'Object type "' .. args.type .. '" does not exist')
    object.type = args.type
    object.material = args.material
    object.data = OBJECT_HANDLERS[args.type](args.data)

    function object:setData(newData)
        self.data = OBJECT_HANDLERS[self.type](newData)
    end

    return object
end
