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
    scene.collisionTolerance = args.collisionTolerance or 0.1
    scene.samplesPerAxis = args.samplesPerAxis or 2
    scene.maxReflections = args.maxReflections or 3
    scene.maxRefractionDepth = args.maxRefractionDepth or 3
    scene.spaceSpeedOfLight = args.spaceSpeedOfLight or 300

    scene.objects = {
        cube = {data = {}, material = {}},
        insideCube = {data = {}, material = {}},
        sphere = {data = {}, material = {}},
        cylinder = {data = {}, material = {}}
    }
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
        transparencies = {}
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

    function scene:addLight(x, y, z, r, g, b, brightness)
        table.insert(self.lights.positions, {x, y, z})
        table.insert(self.lights.colours, {r or 1, g or 1, b or 1, 1})
        table.insert(self.lights.brightnesses, brightness or 1)
    end

    function scene:addMaterial(name, r, g, b, reflectance, transparency, speedOfLight)
        self.materials.indexLookup[name] = #self.materials.colours
        table.insert(self.materials.colours, {r or 1, g or 1, b or 1, 1})
        table.insert(self.materials.reflectances, reflectance or 0)
        table.insert(self.materials.transparencies, transparency or 0.0)
        table.insert(self.materials.speedsOfLight, speedOfLight or self.spaceSpeedOfLight)
    end

    function scene:addCube(material, x, y, z, width, height, depth)
        table.insert(self.objects.cube.material, self.materials.indexLookup[material] or -1)
        table.insert(self.objects.cube.data, {x, y, z})
        table.insert(self.objects.cube.data, {width, height, depth})
    end

    function scene:addInsideCube(material, x, y, z, width, height, depth)
        table.insert(self.objects.insideCube.material, self.materials.indexLookup[material] or -1)
        table.insert(self.objects.insideCube.data, {x, y, z})
        table.insert(self.objects.insideCube.data, {width, height, depth})
    end

    function scene:addSphere(material, x, y, z, radius)
        table.insert(self.objects.sphere.material, self.materials.indexLookup[material] or -1)
        table.insert(self.objects.sphere.data, {x, y, z, radius})
    end

    function scene:addCylinder(material, x, y, z, radius, height)
        table.insert(self.objects.cylinder.material, self.materials.indexLookup[material] or -1)
        table.insert(self.objects.cylinder.data, {x, y, z})
        table.insert(self.objects.cylinder.data, {radius, height, 0})
    end

    function scene:updateRotationMatrix()
        local cos_yaw = math.cos(self.camera.yaw)
        local sin_yaw = math.sin(self.camera.yaw)
        local cos_pitch = math.cos(self.camera.pitch)
        local sin_pitch = math.sin(self.camera.pitch)
        local cos_roll = math.cos(self.camera.roll)
        local sin_roll = math.sin(self.camera.roll)
        self.camera.rotationMatrix = {
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
        rayMarchingShader:send('samplesPerAxis', self.samplesPerAxis)
        rayMarchingShader:send('maxReflections', self.maxReflections)

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
        end

        for name, objectType in pairs(self.objects) do
            if #objectType.data > 0 then
                rayMarchingShader:send(name .. 'Data', unpack(objectType.data))
                rayMarchingShader:send(name .. 'Material', unpack(objectType.material))
                rayMarchingShader:send(name .. 'Count', #objectType.data)
            end
        end

        love.graphics.draw(shaderImage, x, y, 0, width / shaderImage:getWidth(), height / shaderImage:getHeight())

        love.graphics.setShader(oldShader)
    end

    scene:updateRotationMatrix()

    return scene
end
