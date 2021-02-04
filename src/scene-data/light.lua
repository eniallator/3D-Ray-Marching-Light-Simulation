local classUtilities = require 'src.class-utilities'

return function(args)
    local light = {class = 'Light'}

    light.position = classUtilities.validateOrComplain(args.position, {'number', 'number', 'number'})
    light.colour = classUtilities.validateOrDefault(args.colour, {1, 1, 1, 1})
    light.brightness = classUtilities.validateOrDefault(args.brightness, 1)

    return light
end
