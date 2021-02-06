local classUtilities = require 'src.utils.class-utilities'
local rayMarchingShader = love.graphics.newShader('src/ray-marcher.frag')
local shaderImage = love.graphics.newImage(love.image.newImageData(1, 1))

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

return function(args)
    args = args or {}

    local scene = {}
    scene.maxDistance = args.maxDistance
    scene.globalMinLight = args.globalMinLight or 0
    scene.lightMaxRange = args.lightMaxRange or 200
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
    scene.lights = {}
    scene.materials = {}
    scene.camera = {
        x = 0,
        y = 0,
        z = 0,
        yaw = 0,
        pitch = 0,
        roll = 0,
        viewPortDist = 1
    }
    scene.cache = {}

    function scene:registerLight(light)
        assert(light.class == 'Light', 'Tried registering a non-light as a light')
        table.insert(self.lights, light)
    end
    function scene:registerMaterial(material)
        assert(material.class == 'Material', 'Tried registering a non-material as a material')
        table.insert(self.materials, material)
    end
    function scene:registerObject(object)
        assert(object.class == 'Object', 'Tried registering a non-object as an object')
        table.insert(self.objects, object)
    end

    function scene:loadLights()
        self.cache.lights = {position = {}, colour = {}, brightness = {}}
        local i
        for i = 1, #self.lights do
            local light = self.lights[i]
            table.insert(self.cache.lights.position, light.position)
            table.insert(self.cache.lights.colour, light.colour)
            table.insert(self.cache.lights.brightness, light.brightness)
        end
    end
    function scene:loadMaterials()
        self.cache.materials = {
            colour = {},
            reflectance = {},
            speedOfLight = {},
            transparency = {},
            glowStrength = {},
            glowRange = {},
            glowColour = {}
        }
        self.cache.materialLookup = {}
        local i
        for i = 1, #self.materials do
            local material = self.materials[i]
            self.cache.materialLookup[tostring(material)] = i - 1

            table.insert(self.cache.materials.colour, material.colour)
            table.insert(self.cache.materials.reflectance, material.reflectance)
            table.insert(self.cache.materials.speedOfLight, material.speedOfLight)
            table.insert(self.cache.materials.transparency, material.transparency)
            table.insert(self.cache.materials.glowStrength, material.glowStrength)
            table.insert(self.cache.materials.glowRange, material.glowRange)
            table.insert(self.cache.materials.glowColour, material.glowColour)
        end
    end
    function scene:loadObjects()
        self.cache.objects = {}
        local i
        for i = 1, #self.objects do
            local object = self.objects[i]
            if self.cache.objects[object.type] == nil then
                self.cache.objects[object.type] = {
                    material = {},
                    position = {},
                    rotationMatrix = {},
                    scale = {},
                    data = {}
                }
            end

            local materialId = self.cache.materialLookup[tostring(object.material)]
            assert(materialId, 'Tried loading an object with an unknown material')
            table.insert(self.cache.objects[object.type].material, materialId)
            table.insert(self.cache.objects[object.type].position, object.position)
            table.insert(self.cache.objects[object.type].rotationMatrix, object.rotationMatrix)
            table.insert(self.cache.objects[object.type].scale, object.scale)
            table.insert(self.cache.objects[object.type].data, object.data)
        end
    end

    function scene:loadAllData()
        self:loadLights()
        self:loadMaterials()
        self:loadObjects()
    end

    function scene:updateRotationMatrix()
        self.camera.rotationMatrix = classUtilities.rotationToMatrix(self.camera)
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
        rayMarchingShader:send('lightMaxRange', self.lightMaxRange)
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

        rayMarchingShader:send('lightCount', #self.cache.lights.position)
        if #self.cache.lights.position > 0 then
            rayMarchingShader:send('lightPositions', unpack(self.cache.lights.position))
            rayMarchingShader:send('lightColours', unpack(self.cache.lights.colour))
            rayMarchingShader:send('lightBrightnesses', unpack(self.cache.lights.brightness))
        end

        if #self.cache.materials.colour > 0 then
            rayMarchingShader:send('materialColours', unpack(self.cache.materials.colour))
            rayMarchingShader:send('materialReflectances', unpack(self.cache.materials.reflectance))
            rayMarchingShader:send('materialSpeedsOfLight', unpack(self.cache.materials.speedOfLight))
            rayMarchingShader:send('materialTransparencies', unpack(self.cache.materials.transparency))
            rayMarchingShader:send('materialGlowStrengths', unpack(self.cache.materials.glowStrength))
            rayMarchingShader:send('materialGlowRanges', unpack(self.cache.materials.glowRange))
            rayMarchingShader:send('materialGlowColours', unpack(self.cache.materials.glowColour))
        end

        for name, objectType in pairs(self.cache.objects) do
            rayMarchingShader:send(name .. 'Count', #objectType.material)
            rayMarchingShader:send(name .. 'Material', unpack(objectType.material))
            rayMarchingShader:send(name .. 'Position', unpack(objectType.position))
            rayMarchingShader:send(name .. 'Data', unpack(objectType.data))
            rayMarchingShader:send(name .. 'Scale', unpack(objectType.scale))
            rayMarchingShader:send(name .. 'Rotation', unpack(objectType.rotationMatrix))
        end

        love.graphics.draw(shaderImage, x, y, 0, width / shaderImage:getWidth(), height / shaderImage:getHeight())

        love.graphics.setShader(oldShader)
    end

    scene:updateRotationMatrix()

    return scene
end
