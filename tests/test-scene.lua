love = {
    graphics = {
        newShader = function()
            return 'shader'
        end,
        newImage = function()
            return 'image'
        end
    },
    image = {
        newImageData = function()
            return {
                setPixel = function()
                end
            }
        end
    }
}
local Scene = require 'src.scene'

local test = {}

function test.registerObject_valid()
    local scene = Scene()
    scene:registerObject({class = 'Object'})
    assert(#scene.objects == 1)
end

function test.registerObject_invalid()
    local scene = Scene()
    local success, msg =
        pcall(
        function()
            scene:registerObject({class = 'Material'})
        end
    )
    assert(not success, msg)
end

function test.loadLights()
    local scene = Scene()
    scene:registerLight({class = 'Light', position = {1, 2, 3}, colour = {3, 2, 1}, brightness = 0.5})
    scene:registerLight({class = 'Light', position = {4, 5, 6}, colour = {6, 5, 4}, brightness = 1})
    scene:loadLights()
    assertEquals(
        scene.cache.lights,
        {refreshed = true, position = {{1, 2, 3}, {4, 5, 6}}, colour = {{3, 2, 1}, {6, 5, 4}}, brightness = {0.5, 1}}
    )
end

function test.loadMaterials()
    local scene = Scene()
    local mat1 = {
        class = 'Material',
        colour = {1, 2, 3},
        reflectance = 1,
        speedOfLight = 2,
        transparency = 3,
        glowStrength = 4,
        glowRange = 5,
        glowColour = {3, 2, 1}
    }
    local mat2 = {
        class = 'Material',
        colour = {4, 5, 6},
        reflectance = 6,
        speedOfLight = 7,
        transparency = 8,
        glowStrength = 9,
        glowRange = 10,
        glowColour = {6, 5, 4}
    }
    scene:registerMaterial(mat1)
    scene:registerMaterial(mat2)
    scene:loadMaterials()
    assertEquals(
        scene.cache.materials,
        {
            colour = {{1, 2, 3}, {4, 5, 6}},
            reflectance = {1, 6},
            speedOfLight = {2, 7},
            transparency = {3, 8},
            glowStrength = {4, 9},
            glowRange = {5, 10},
            glowColour = {{3, 2, 1}, {6, 5, 4}},
            refreshed = true,
            refractionAngles = 'image',
            refractionIndex = {1, 2},
            transparentMaterials = {mat1, mat2}
        }
    )
end

function test.loadObjects()
    local scene = Scene()
    local mat1 = {}
    local mat2 = {}
    scene.cache.materialLookup = {[tostring(mat1)] = 1, [tostring(mat2)] = 2}
    scene:registerObject(
        {
            class = 'Object',
            type = 'foo',
            material = mat1,
            position = {1, 2, 3},
            rotationMatrix = 1,
            scale = {3, 2, 1},
            data = 2
        }
    )
    scene:registerObject(
        {
            class = 'Object',
            type = 'bar',
            material = mat2,
            position = {4, 5, 6},
            rotationMatrix = 3,
            scale = {6, 5, 4},
            data = 4
        }
    )
    scene:loadObjects()
    assertEquals(
        scene.cache.objects,
        {
            refreshed = true,
            foo = {
                material = {1},
                position = {{1, 2, 3}},
                rotationMatrix = {1},
                scale = {{3, 2, 1}},
                data = {2}
            },
            bar = {
                material = {2},
                position = {{4, 5, 6}},
                rotationMatrix = {3},
                scale = {{6, 5, 4}},
                data = {4}
            }
        }
    )
end

return test
