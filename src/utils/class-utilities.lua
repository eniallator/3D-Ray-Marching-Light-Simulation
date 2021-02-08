local classUtilities = {}

classUtilities.validateOrDefault = function(value, default)
    if type(default) ~= type(value) then
        return default
    elseif type(value) ~= 'table' then
        return value
    end

    local tbl = {}
    for key, defaultValue in pairs(default) do
        if value[key] == nil or type(value[key]) ~= type(defaultValue) then
            tbl[key] = defaultValue
        else
            tbl[key] = classUtilities.validateOrDefault(value[key], defaultValue)
        end
    end
    return tbl
end

classUtilities.validateOrComplain = function(value, types, message)
    if types == type(value) and type(value) ~= 'table' then
        return value
    end
    if type(types) ~= 'table' and types == type(value) then
        error(message)
    end

    for key, defaultType in pairs(types) do
        if value[key] == nil or type(value[key]) ~= defaultType then
            error(message)
        else
            classUtilities.validateOrComplain(value[key], defaultType, message)
        end
    end

    return value
end

classUtilities.rotationToMatrix = function(rotation)
    local cosYaw = math.cos(rotation.yaw)
    local sinYaw = math.sin(rotation.yaw)
    local cosPitch = math.cos(rotation.pitch)
    local sinPitch = math.sin(rotation.pitch)
    local cosRoll = math.cos(rotation.roll)
    local sinRoll = math.sin(rotation.roll)
    return {
        {
            cosYaw * cosPitch,
            cosYaw * sinPitch * sinRoll - sinYaw * cosRoll,
            cosYaw * sinPitch * cosRoll + sinYaw * sinRoll
        },
        {
            sinYaw * cosPitch,
            sinYaw * sinPitch * sinRoll + cosYaw * cosRoll,
            sinYaw * sinPitch * cosRoll - cosYaw * sinRoll
        },
        {
            -sinPitch,
            cosPitch * sinRoll,
            cosPitch * cosRoll
        }
    }
end

return classUtilities