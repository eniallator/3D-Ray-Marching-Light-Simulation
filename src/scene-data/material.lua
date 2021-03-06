local srcFolder = (...):match('(.-)[^%.]+$')
srcFolder = srcFolder:sub(1, -2):match('(.-)[^%.]+$')

local classUtilities = require(srcFolder .. 'utils.class-utilities')

return function(args)
    local material = {class = 'Material'}

    args = args or {}
    material.colour = classUtilities.validateOrDefault(args.colour, {1, 1, 1})
    table.insert(material.colour, 1)
    material.reflectance = classUtilities.validateOrDefault(args.reflectance, 0)
    material.transparency = classUtilities.validateOrDefault(args.transparency, 0)
    material.speedOfLight = classUtilities.validateOrDefault(args.speedOfLight, 300)
    material.glowStrength = classUtilities.validateOrDefault(args.glowStrength, 0)
    material.glowRange = classUtilities.validateOrDefault(args.glowRange, 0)
    material.glowColour = classUtilities.validateOrDefault(args.glowColour, {1, 1, 1})
    table.insert(material.glowColour, 1)

    return material
end
