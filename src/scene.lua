local outerFolder = (...):match('(.-)[^%.]+$')

local Transformable = require(outerFolder .. 'utils.transformable')
local classUtilities = require(outerFolder .. 'utils.class-utilities')

local rayMarchingShader = love.graphics.newShader('src/ray-marcher.frag')
local shaderImage = love.graphics.newImage(love.image.newImageData(1, 1))

return function(args)
    args = args or {}

    local scene = {}
    scene.maxDistance = args.maxDistance or 200
    scene.globalMinLight = args.globalMinLight or 0
    scene.lightMaxRange = args.lightMaxRange or 200
    scene.collisionTolerance = args.collisionTolerance or 0.1
    scene.samplesPerPixelPerAxis = args.samplesPerPixelPerAxis or 2
    scene.maxReflections = args.maxReflections or 3
    scene.maxRefractionDepth = args.maxRefractionDepth or 4
    scene.spaceSpeedOfLight = args.spaceSpeedOfLight or 300
    scene.softShadowAngle = args.softShadowAngle or 0
    scene.ambientOcclusionSamples = args.ambientOcclusionSamples or 0
    scene.ambientOcclusionMaxHeight = args.ambientOcclusionMaxHeight or 0
    scene.ambientOcclusionStrength = args.ambientOcclusionStrength or 0
    scene.numRefractionAngleIntervals = args.numRefractionAngleIntervals or 64
    scene.configRefreshed = true

    scene.objects = {}
    scene.lights = {}
    scene.materials = {}
    scene.cache = {}

    scene.camera = Transformable({position = {0, 0, 0}})
    scene.camera.scale = nil
    scene.camera.setScale = nil
    scene.camera.viewportDist = 1

    function scene.camera:setViewportDist(dist)
        scene.camera.viewportDist = dist
    end

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
        self.cache.lights = {position = {}, colour = {}, brightness = {}, refreshed = true}
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
            glowColour = {},
            refractionIndex = {},
            transparentMaterials = {},
            refreshed = true
        }
        if self.cache.objects then
            self.cache.objects.refreshed = true
        end
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
            if material.transparency > 0 then
                table.insert(self.cache.materials.transparentMaterials, material)
                table.insert(self.cache.materials.refractionIndex, #self.cache.materials.transparentMaterials)
            else
                table.insert(self.cache.materials.refractionIndex, 0)
            end
        end
        -- Generating a lookup table of angles of refraction
        if #self.cache.materials.transparentMaterials > 0 then
            local refractionAngles =
                love.image.newImageData(
                (1 + #self.cache.materials.transparentMaterials) * #self.cache.materials.transparentMaterials,
                math.ceil(self.numRefractionAngleIntervals / 4)
            )
            local i, j, k, l
            for i = 0, #self.cache.materials.transparentMaterials do
                local outerSpeed =
                    i == 0 and self.spaceSpeedOfLight or self.cache.materials.transparentMaterials[i].speedOfLight
                for j = 1, #self.cache.materials.transparentMaterials do
                    local innerSpeed =
                        j == i and self.spaceSpeedOfLight or self.cache.materials.transparentMaterials[j].speedOfLight
                    local n = innerSpeed / outerSpeed
                    for k = 0, math.ceil(self.numRefractionAngleIntervals / 4) - 1 do
                        local pixel = {}
                        for l = 0, math.min(3, self.numRefractionAngleIntervals - k * 4) do
                            local cosI = (k * 4 + l) / (self.numRefractionAngleIntervals - 1)
                            local cosRSqr = 1 - (n * n * (1 - cosI * cosI))
                            table.insert(pixel, cosRSqr > 0 and math.sqrt(cosRSqr) or 0)
                        end
                        for l = 1, 4 - #pixel do
                            table.insert(pixel, 0)
                        end
                        refractionAngles:setPixel(
                            i * #self.cache.materials.transparentMaterials + j - 1,
                            k,
                            unpack(pixel)
                        )
                    end
                end
            end
            self.cache.materials.refractionAngles = love.graphics.newImage(refractionAngles)
        end
    end

    function scene:loadObjects()
        assert(self.cache.materialLookup, 'Tried loading objects before materials. Must load materials first!')
        self.cache.objects = {refreshed = true}
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

    function scene:draw(x, y, width, height)
        assert(#self.objects > 0 and self.cache.objects, 'Tried drawing without objects being loaded')
        assert(#self.materials > 0 and self.cache.materials, 'Tried drawing without materials being loaded')
        assert(#self.lights > 0 and self.cache.lights, 'Tried drawing without lights being loaded')

        local oldShader = love.graphics.getShader()

        love.graphics.setShader(rayMarchingShader)

        rayMarchingShader:send('dimensions', {width, height})

        if self.configRefreshed then
            self.configRefreshed = false
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
        end

        rayMarchingShader:send('cameraPos', {self.camera.position[1], self.camera.position[2], self.camera.position[3]})
        rayMarchingShader:send('cameraRotationMatrix', self.camera.rotationMatrix)
        rayMarchingShader:send('cameraViewportDist', self.camera.viewportDist)

        if self.cache.lights.refreshed then
            self.cache.lights.refreshed = false
            rayMarchingShader:send('lightCount', #self.cache.lights.position)
            if #self.cache.lights.position > 0 then
                rayMarchingShader:send('lightPositions', unpack(self.cache.lights.position))
                rayMarchingShader:send('lightColours', unpack(self.cache.lights.colour))
                rayMarchingShader:send('lightBrightnesses', unpack(self.cache.lights.brightness))
            end
        end

        if self.cache.materials.refreshed and #self.cache.materials.colour > 0 then
            self.cache.materials.refreshed = false
            rayMarchingShader:send('materialColours', unpack(self.cache.materials.colour))
            rayMarchingShader:send('materialReflectances', unpack(self.cache.materials.reflectance))
            rayMarchingShader:send('materialSpeedsOfLight', unpack(self.cache.materials.speedOfLight))
            rayMarchingShader:send('materialTransparencies', unpack(self.cache.materials.transparency))
            rayMarchingShader:send('materialGlowStrengths', unpack(self.cache.materials.glowStrength))
            rayMarchingShader:send('materialGlowRanges', unpack(self.cache.materials.glowRange))
            rayMarchingShader:send('materialGlowColours', unpack(self.cache.materials.glowColour))
            rayMarchingShader:send('materialRefractionIndex', unpack(self.cache.materials.refractionIndex))
            rayMarchingShader:send('materialRefractionAngles', self.cache.materials.refractionAngles)
            rayMarchingShader:send('numTransparentMaterials', #self.cache.materials.transparentMaterials)
            rayMarchingShader:send('numRefractionAngleIntervals', self.numRefractionAngleIntervals)
        end

        if self.cache.objects.refreshed then
            self.cache.objects.refreshed = false
            for name, objectType in pairs(self.cache.objects) do
                if name ~= 'refreshed' then
                    rayMarchingShader:send(name .. 'Count', #objectType.material)
                    rayMarchingShader:send(name .. 'Material', unpack(objectType.material))
                    rayMarchingShader:send(name .. 'Position', unpack(objectType.position))
                    rayMarchingShader:send(name .. 'Data', unpack(objectType.data))
                    rayMarchingShader:send(name .. 'Scale', unpack(objectType.scale))
                    rayMarchingShader:send(name .. 'Rotation', unpack(objectType.rotationMatrix))
                end
            end
        end

        love.graphics.draw(shaderImage, x, y, 0, width / shaderImage:getWidth(), height / shaderImage:getHeight())

        love.graphics.setShader(oldShader)
    end

    return scene
end
