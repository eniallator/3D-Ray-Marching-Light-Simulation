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
    local cos_yaw = math.cos(rotation.yaw)
    local sin_yaw = math.sin(rotation.yaw)
    local cos_pitch = math.cos(rotation.pitch)
    local sin_pitch = math.sin(rotation.pitch)
    local cos_roll = math.cos(rotation.roll)
    local sin_roll = math.sin(rotation.roll)
    return {
        {
            cos_yaw * cos_pitch,
            cos_yaw * sin_pitch * sin_roll - sin_yaw * cos_roll,
            cos_yaw * sin_pitch * cos_roll + sin_yaw * sin_roll
        },
        {
            sin_yaw * cos_pitch,
            sin_yaw * sin_pitch * sin_roll + cos_yaw * cos_roll,
            sin_yaw * sin_pitch * cos_roll - cos_yaw * sin_roll
        },
        {
            -sin_pitch,
            cos_pitch * sin_roll,
            cos_pitch * cos_roll
        }
    }
end

return classUtilities
