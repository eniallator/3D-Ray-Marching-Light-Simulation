local rayMarchingShader = love.graphics.newShader('src/ray-marcher.frag')
local shaderImage = love.graphics.newImage(love.image.newImageData(1, 1))

local OBJECT_HANDLERS = {
    ['cube'] = function(data)
        return {data.width, data.height, data.depth}
    end,
    ['insideCube'] = function(data)
        return {data.width, data.height, data.depth}
    end,
    ['sphere'] = function(data)
        return data.radius
    end,
    ['cylinder'] = function(data)
        return {data.radius, data.height}
    end
}

local function cross(vecA, vecB)
    return {
        x = vecA.y * vecB.z - vecA.z * vecB.y,
        y = vecA.z * vecB.x - vecA.x * vecB.z,
        z = vecA.x * vecB.y - vecA.y * vecB.x
    }
end

local function normalize(vec)
    local length = math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
    return {
        x = vec.x / length,
        y = vec.y / length,
        z = vec.z / length
    }
end

local function rotationToMatrix(rotation)
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

return function(args)
    args = args or {}

    local scene = {}
    scene.maxDistance = args.maxDistance
    scene.globalMinLight = args.globalMinLight or 0
    scene.collisionTolerance = args.collisionTolerance or 0.1
    scene.samplesPerPixelPerAxis = args.samplesPerPixelPerAxis or 2
    scene.maxReflections = args.maxReflections or 3
    scene.maxRefractionDepth = args.maxRefractionDepth or 4
    scene.spaceSpeedOfLight = args.spaceSpeedOfLight or 300
    scene.softShadowAngle = args.softShadowAngle or 0.0
    scene.ambientOcclusionSamples = args.ambientOcclusionSamples or 0
    scene.ambientOcclusionMaxHeight = args.ambientOcclusionMaxHeight or 0
    scene.ambientOcclusionStrength = args.ambientOcclusionStrength or 0

    scene.objects = {}
    scene.lights = {
        positions = {},
        colours = {},
        brightnesses = {},
        maxRange = args.lightMaxRange or 200
    }
    scene.materials = {
        indexLookup = {},
        colours = {},
        reflectances = {},
        speedsOfLight = {},
        transparencies = {},
        glowStrengths = {},
        glowRanges = {},
        glowColours = {}
    }
    scene.camera = {
        x = 0,
        y = 0,
        z = 0,
        yaw = 0,
        pitch = 0,
        roll = 0,
        viewPortDist = 1
    }

    function scene:addLight(position, colour, brightness)
        colour = colour or {}
        table.insert(self.lights.positions, position)
        table.insert(self.lights.colours, {colour[1] or 1, colour[2] or 1, colour[3] or 1, 1})
        table.insert(self.lights.brightnesses, brightness or 1)
    end

    function scene:addMaterial(
        name,
        colour,
        reflectance,
        transparency,
        speedOfLight,
        glowStrength,
        glowRange,
        glowColour)
        self.materials.indexLookup[name] = #self.materials.colours
        table.insert(self.materials.colours, {colour[1] or 1, colour[2] or 1, colour[3] or 1, 1})
        table.insert(self.materials.reflectances, reflectance or 0)
        table.insert(self.materials.transparencies, transparency or 0.0)
        table.insert(self.materials.speedsOfLight, speedOfLight or self.spaceSpeedOfLight - 1)
        table.insert(self.materials.glowStrengths, glowStrength or 0)
        table.insert(self.materials.glowRanges, glowRange or 0)
        table.insert(
            self.materials.glowColours,
            glowColour and {glowColour[1] or 1, glowColour[2] or 1, glowColour[3] or 1, 1} or {1, 1, 1, 1}
        )
    end

    function scene:addObject(type, material, transform, data)
        assert(OBJECT_HANDLERS[type] ~= nil, 'Object type "' .. type .. '" does not exist')
        if self.objects[type] == nil then
            self.objects[type] = {material = {}, position = {}, scale = {}, rotation = {}, data = {}}
        end

        local scale = transform.scale or {}
        local rotation = transform.rotation or {}

        table.insert(self.objects[type].material, self.materials.indexLookup[material])
        table.insert(self.objects[type].position, transform.position)
        table.insert(self.objects[type].scale, {scale[1] or 1, scale[2] or 1, scale[3] or 1})
        table.insert(
            self.objects[type].rotation,
            rotationToMatrix({yaw = rotation[1] or 0, pitch = rotation[2] or 0, roll = rotation[3] or 0})
        )
        table.insert(self.objects[type].data, OBJECT_HANDLERS[type](data))
    end

    function scene:updateRotationMatrix()
        self.camera.rotationMatrix = rotationToMatrix(self.camera)
    end

    function scene:setCamera(x, y, z, yaw, pitch, roll, viewPortDist)
        self.camera.x = x or self.camera.x
        self.camera.y = y or self.camera.y
        self.camera.z = z or self.camera.z
        self.camera.yaw = yaw or self.camera.yaw
        self.camera.pitch = pitch or self.camera.pitch
        self.camera.roll = roll or self.camera.roll
        self.camera.viewPortDist = viewPortDist or self.camera.viewPortDist
        if yaw or pitch or roll then
            self:updateRotationMatrix()
        end
    end

    function scene:offsetCamera(x, y, z, yaw, pitch, roll)
        self.camera.x = self.camera.x + (x or 0)
        self.camera.y = self.camera.y + (y or 0)
        self.camera.z = self.camera.z + (z or 0)
        self.camera.yaw = self.camera.yaw + (yaw or 0)
        self.camera.pitch = self.camera.pitch + (pitch or 0)
        self.camera.roll = self.camera.roll + (roll or 0)
        if yaw or pitch or roll then
            self:updateRotationMatrix()
        end
    end

    function scene:addRelativePosition(x, y, z)
        local mat = self.camera.rotationMatrix
        self.camera.x = self.camera.x + x * mat[1][1] + y * mat[1][2] + z * mat[1][3]
        self.camera.y = self.camera.y + x * mat[2][1] + y * mat[2][2] + z * mat[2][3]
        self.camera.z = self.camera.z + x * mat[3][1] + y * mat[3][2] + z * mat[3][3]
    end

    function scene:draw(x, y, width, height)
        local oldShader = love.graphics.getShader()

        love.graphics.setShader(rayMarchingShader)

        rayMarchingShader:send('dimensions', {width, height})
        rayMarchingShader:send('maxDistance', self.maxDistance)
        rayMarchingShader:send('globalMinLight', self.globalMinLight)
        rayMarchingShader:send('collisionTolerance', self.collisionTolerance)
        rayMarchingShader:send('samplesPerPixelPerAxis', self.samplesPerPixelPerAxis)
        rayMarchingShader:send('maxReflections', self.maxReflections)
        rayMarchingShader:send('maxRefractionDepth', self.maxRefractionDepth)
        rayMarchingShader:send('spaceSpeedOfLight', self.spaceSpeedOfLight)
        rayMarchingShader:send('softShadowAngle', self.softShadowAngle)
        rayMarchingShader:send('ambientOcclusionSamples', self.ambientOcclusionSamples)
        rayMarchingShader:send('ambientOcclusionMaxHeight', self.ambientOcclusionMaxHeight)
        rayMarchingShader:send('ambientOcclusionStrength', self.ambientOcclusionStrength)

        rayMarchingShader:send('cameraPos', {self.camera.x, self.camera.y, self.camera.z})
        rayMarchingShader:send('cameraRotationMatrix', self.camera.rotationMatrix)
        rayMarchingShader:send('cameraViewPortDist', self.camera.viewPortDist)

        if #self.lights.positions > 0 then
            rayMarchingShader:send('lightPositions', unpack(self.lights.positions))
            rayMarchingShader:send('lightColours', unpack(self.lights.colours))
            rayMarchingShader:send('lightBrightnesses', unpack(self.lights.brightnesses))
        end
        rayMarchingShader:send('lightCount', #self.lights.positions)
        rayMarchingShader:send('lightMaxRange', self.lights.maxRange)

        if #self.materials.colours > 0 then
            rayMarchingShader:send('materialColours', unpack(self.materials.colours))
            rayMarchingShader:send('materialReflectances', unpack(self.materials.reflectances))
            rayMarchingShader:send('materialSpeedsOfLight', unpack(self.materials.speedsOfLight))
            rayMarchingShader:send('materialTransparencies', unpack(self.materials.transparencies))
            rayMarchingShader:send('materialGlowStrengths', unpack(self.materials.glowStrengths))
            rayMarchingShader:send('materialGlowRanges', unpack(self.materials.glowRanges))
            rayMarchingShader:send('materialGlowColours', unpack(self.materials.glowColours))
        end

        for name, objectType in pairs(self.objects) do
            rayMarchingShader:send(name .. 'Count', #objectType.material)
            rayMarchingShader:send(name .. 'Material', unpack(objectType.material))
            rayMarchingShader:send(name .. 'Position', unpack(objectType.position))
            rayMarchingShader:send(name .. 'Data', unpack(objectType.data))
            rayMarchingShader:send(name .. 'Scale', unpack(objectType.scale))
            rayMarchingShader:send(name .. 'Rotation', unpack(objectType.rotation))
        end

        love.graphics.draw(shaderImage, x, y, 0, width / shaderImage:getWidth(), height / shaderImage:getHeight())

        love.graphics.setShader(oldShader)
    end

    scene:updateRotationMatrix()

    return scene
end
