local rayMarchingShader = love.graphics.newShader('src/ray-marcher.frag')
local shaderImage = love.graphics.newImage(love.image.newImageData(1, 1))

return function(args)
    args = args or {}

    local scene = {}
    scene.maxDistance = args.maxDistance or 500
    scene.collisionTolerance = args.collisionTolerance or 0.1

    scene.objects = {}
    scene.lights = {}
    scene.camera = {
        x = 0,
        y = 0,
        z = 0,
        yaw = 0,
        pitch = 0,
        fov = math.pi * 5 / 6
    }

    function scene:setCamera(x, y, z, yaw, pitch)
        self.camera.x = x or self.camera.x
        self.camera.y = y or self.camera.y
        self.camera.z = z or self.camera.z
        self.camera.yaw = yaw or self.camera.yaw
        self.camera.pitch = pitch or self.camera.pitch
    end

    function scene:draw(x, y, width, height)
        local oldShader = love.graphics.getShader()

        love.graphics.setShader(rayMarchingShader)

        rayMarchingShader:send('maxDistance', self.maxDistance)
        rayMarchingShader:send('collisionTolerance', self.collisionTolerance)
        rayMarchingShader:send('cameraPos', {self.camera.x, self.camera.y, self.camera.z})
        rayMarchingShader:send('cameraRotation', {self.camera.yaw, self.camera.pitch})
        rayMarchingShader:send('cameraFov', self.camera.fov)

        love.graphics.draw(shaderImage, x, y, 0, width / shaderImage:getWidth(), height / shaderImage:getHeight())

        love.graphics.setShader(oldShader)
    end

    return scene
end
