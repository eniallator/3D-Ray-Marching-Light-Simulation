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
    scene.maxDistance = args.maxDistance or 130
    scene.collisionTolerance = args.collisionTolerance or 0.1

    scene.objects = {
        cube = {},
        insideCube = {},
        sphere = {},
        cylinder = {}
    }
    scene.lights = {}
    scene.camera = {
        x = 0,
        y = 0,
        z = 0,
        yaw = 0,
        pitch = 0,
        viewPortDist = 1
    }

    function scene:addCube(x, y, z, width, height, depth)
        table.insert(self.objects.cube, {x, y, z})
        table.insert(self.objects.cube, {width, height, depth})
    end

    function scene:addInsideCube(x, y, z, width, height, depth)
        table.insert(self.objects.insideCube, {x, y, z})
        table.insert(self.objects.insideCube, {width, height, depth})
    end

    function scene:addSphere(x, y, z, radius)
        table.insert(self.objects.sphere, {x, y, z, radius})
    end

    function scene:addCylinder(x, y, z, radius, height)
        table.insert(self.objects.cylinder, {x, y, z})
        table.insert(self.objects.cylinder, {radius, height, 0})
    end

    function scene:updateDirNorm()
        local xzlen = math.cos(self.camera.pitch)
        self.camera.dirNorm = {
            x = xzlen * math.cos(self.camera.yaw),
            y = math.sin(self.camera.pitch),
            z = xzlen * math.sin(-self.camera.yaw)
        }
    end

    function scene:setCamera(x, y, z, yaw, pitch, viewPortDist)
        self.camera.x = x or self.camera.x
        self.camera.y = y or self.camera.y
        self.camera.z = z or self.camera.z
        self.camera.yaw = yaw or self.camera.yaw
        self.camera.pitch = pitch or self.camera.pitch
        self.camera.viewPortDist = viewPortDist or self.camera.viewPortDist
        if yaw or pitch then
            self:updateDirNorm()
        end
    end

    function scene:offsetCamera(x, y, z, yaw, pitch)
        self.camera.x = self.camera.x + (x or 0)
        self.camera.y = self.camera.y + (y or 0)
        self.camera.z = self.camera.z + (z or 0)
        self.camera.yaw = self.camera.yaw + (yaw or 0)
        self.camera.pitch = self.camera.pitch + (pitch or 0)
        if yaw or pitch then
            self:updateDirNorm()
        end
    end

    function scene:addRelativePosition(x, y, z)
        local xAxis = self.camera.dirNorm
        local zAxis = normalize(cross(xAxis, {x = 0, y = 1, z = 0}))
        local yAxis = normalize(cross(xAxis, zAxis))
        self.camera.x = self.camera.x + x * xAxis.x - y * yAxis.x + z * zAxis.x
        self.camera.y = self.camera.y + x * xAxis.y - y * yAxis.y + z * zAxis.y
        self.camera.z = self.camera.z + x * xAxis.z - y * yAxis.z + z * zAxis.z
    end

    function scene:draw(x, y, width, height)
        local oldShader = love.graphics.getShader()

        love.graphics.setShader(rayMarchingShader)

        rayMarchingShader:send('aspectRatio', width / height)
        rayMarchingShader:send('maxDistance', self.maxDistance)
        rayMarchingShader:send('collisionTolerance', self.collisionTolerance)

        rayMarchingShader:send('cameraPos', {self.camera.x, self.camera.y, self.camera.z})
        rayMarchingShader:send('cameraDirNorm', {self.camera.dirNorm.x, self.camera.dirNorm.y, self.camera.dirNorm.z})
        rayMarchingShader:send('cameraViewPortDist', self.camera.viewPortDist)

        for name, data in pairs(self.objects) do
            if #data > 0 then
                rayMarchingShader:send(name .. 'Data', unpack(data))
                rayMarchingShader:send(name .. 'Count', #data)
            end
        end

        love.graphics.draw(shaderImage, x, y, 0, width / shaderImage:getWidth(), height / shaderImage:getHeight())

        love.graphics.setShader(oldShader)
    end

    scene:updateDirNorm()

    return scene
end
