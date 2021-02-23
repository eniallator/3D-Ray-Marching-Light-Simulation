local srcFolder = (...):match('(.-)[^%.]+$')
srcFolder = srcFolder:sub(1, -2):match('(.-)[^%.]+$')

local classUtilities = require(srcFolder .. 'utils.class-utilities')

return function(args)
    local light = {class = 'Light'}

    light.position =
        classUtilities.validateOrComplain(
        args.position,
        {'number', 'number', 'number'},
        'Lights must have a position argument'
    )
    light.colour = classUtilities.validateOrDefault(args.colour, {1, 1, 1, 1})
    light.brightness = classUtilities.validateOrDefault(args.brightness, 1)

    return light
end
