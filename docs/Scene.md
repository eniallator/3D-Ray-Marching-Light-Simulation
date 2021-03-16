# Scene Class

This will hold all of the configured scene properties as well as the configured objects. It also contains the camera data as well.

## Method Index

- [scene:registerLight](#sceneregisterLight)
- [scene:registerMaterial](#sceneregisterMaterial)
- [scene:registerObject](#sceneregisterObject)
- [scene:loadLights](#sceneloadLights)
- [scene:loadMaterials](#sceneloadMaterials)
- [scene:loadObjects](#sceneloadObjects)
- [scene:loadAllData](#sceneloadAllData)
- [scene:draw](#scenedraw)
- [scene.camera:setPosition](#scenecamerasetPosition)
- [scene.camera:addAbsolutePosition](#scenecameraaddAbsolutePosition)
- [scene.camera:addRelativePosition](#scenecameraaddRelativePosition)
- [scene.camera:setRotation](#scenecamerasetRotation)
- [scene.camera:addRotation](#scenecameraaddRotation)

## Constructor Arguments

- `maxDistance`
  - **Type**: `Number` > `0`
  - **Default**: `200`
  - **Description**: Max view distance that the camera can see.
- `globalMinLight`
  - **Type**: `Number` in range `[0, 1]`
  - **Default**: `0`
  - **Description**: Minimum global light level throughout the scene.
- `lightMaxRange`
  - **Type**: `Number` > `0`
  - **Default**: `200`
  - **Description**: Max range a light can shine.
- `collisionTolerance`
  - **Type**: `Number` > `0`
  - **Default**: `0.1`
  - **Description**: Controls how detailed (and how sharp things like edges are) the scene is. Lower values take more time to compute, but yields a more detailed scene.
- `samplesPerPixelPerAxis`
  - **Type**: `Number (Integer)` > `0`
  - **Default**: `2`
  - **Description**: For anti-aliasing - How many samples to take for blending.
- `maxReflections`
  - **Type**: `Number (Integer)` > `0`
  - **Default**: `3`
  - **Description**: Max reflections a ray can have.
- `maxRefractionDepth`
  - **Type**: `Number (Integer)` > `0`
  - **Default**: `4`
  - **Description**: How many object boundaries (e.g if the object is transparent, when the ray meets the object and goes into it, that counts as crossing a boundary) a ray can cross.
- `spaceSpeedOfLight`
  - **Type**: `Number` > `0`
  - **Default**: `300`
  - **Description**: Speed of light for rays when they aren't inside an object.
- `softShadowAngle`
  - **Type**: `Number` in range `[0, pi]`
  - **Default**: `0`
  - **Description**: How large the soft shadows are when light shines on objects
- `ambientOcclusionSamples`
  - **Type**: `Number (Integer)` ≥ `0`
  - **Default**: `0`
  - **Description**: how many samples to take when computing the ambient occlusion. The more samples, the better the blend, but also more time to compute.
- `ambientOcclusionMaxHeight`
  - **Type**: `Number` > `0`
  - **Default**: `0`
  - **Description**: How far away the last sample will be for computing ambient occlusion.
- `ambientOcclusionStrength`
  - **Type**: `Number` in range `[0, 1]`
  - **Default**: `0`
  - **Description**: How dark a fully occluded spot will be
- `numRefractionAngleIntervals`
  - **Type**: `Number (Integer)` > `0`
  - **Default**: `64`
  - **Description**: How many angles a refracted ray can have - more angles means more accurate refraction, but more initial computation and storage.

### Example Constructor

```lua
scene = RayMarcher.Scene({
    maxDistance = 300,
    globalMinLight = 0.15,
    collisionTolerance = 0.01,
    samplesPerPixelPerAxis = 3,
    lightMaxRange = 200,
    maxReflections = 3,
    maxRefractionDepth = 3,
    spaceSpeedOfLight = 300,
    softShadowAngle = 0.02,
    ambientOcclusionSamples = 5,
    ambientOcclusionMaxHeight = 3,
    ambientOcclusionStrength = 0.2
})
```

## Scene Methods

### **scene:registerLight**

Adds a light to the scene.

_**Arguments**_:

- `light`
  - **Type**: `Light`
  - **Description**: Light to add.

_**Example Usage**_:

```lua
scene:registerLight(light)
```

### **scene:registerMaterial**

Adds a material to the scene.

_**Arguments**_:

- `material`
  - **Type**: `Material`
  - **Description**: Material to add.

_**Example Usage**_:

```lua
scene:registerMaterial(material)
```

### **scene:registerObject**

Adds an object to the scene.

_**Arguments**_:

- `object`
  - **Type**: `Object`
  - **Description**: Object to add.

_**Example Usage**_:

```lua
scene:registerObject(object)
```

### **scene:loadLights**

Loads and prepares all lights in the scene to be ready for drawing.

_**Example Usage**_:

```lua
scene:loadLights()
```

### **scene:loadMaterials**

Loads and prepares all materials in the scene to be ready for drawing.

_**Example Usage**_:

```lua
scene:loadMaterials()
```

### **scene:loadObjects**

Loads and prepares all objects in the scene to be ready for drawing. This method must be called _after_ the [scene:loadMaterials](#scene:loadMaterials) method.

_**Example Usage**_:

```lua
scene:loadObjects()
```

### **scene:loadAllData**

Loads lights, materials, and objects.

_**Example Usage**_:

```lua
scene:loadAllData()
```

### **scene:draw**

Draws the scene on to the window.

_**Arguments**_:

- `x`
  - **Type**: `Number (Integer)`
  - **Description**: Left most `x` coordinate to start drawing from.
- `y`
  - **Type**: `Number (Integer)`
  - **Description**: Top most `y` coordinate to start drawing from.
- `width`
  - **Type**: `Number (Integer)`
  - **Description**: Width of the viewport.
- `height`
  - **Type**: `Number (Integer)`
  - **Description**: Height of the viewport.

_**Example Usage**_:

```lua
scene:draw(10, 20, 300, 200)
```

## Camera

This exists as an attribute on the scene object (accessed through `scene.camera`)

## Camera Methods

### **scene.camera:setPosition**

Sets the camera's position in the scene.

_**Arguments**_:

- `x`
  - **Type**: `Number`
  - **Default**: Current `x` coordinate
  - **Description**: The camera's `x` coordinate
- `y`
  - **Type**: `Number`
  - **Default**: Current `y` coordinate
  - **Description**: The camera's `y` coordinate
- `z`
  - **Type**: `Number`
  - **Default**: Current `z` coordinate
  - **Description**: The camera's `z` coordinate

_**Example Usage**_:

```lua
scene.camera:setPosition(1, 2, 3)
```

### **scene.camera:addAbsolutePosition**

Adds an absolute position to the camera's current position.

_**Arguments**_:

- `x`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: The value to add to the camera's `x` coordinate
- `y`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: The value to add to the camera's `y` coordinate
- `z`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: The value to add to the camera's `z` coordinate

_**Example Usage**_:

```lua
scene.camera:addAbsolutePosition(4, 5, 6)
```

### **scene.camera:addRelativePosition**

Adds a relative position in the direction the camera is facing, to the camera's current position.

_**Arguments**_:

- `x`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: How far forward to move the camera.
- `y`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: How far left to move the camera.
- `z`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: How far down to move the camera.

_**Example Usage**_:

```lua
scene.camera:addRelativePosition(7, 8, 9)
```

### **scene.camera:setRotation**

Sets the camera's current rotation.

_**Arguments**_:

- `yaw`
  - **Type**: `Number`
  - **Default**: Current `yaw` value
  - **Description**: The `yaw` value to set
- `pitch`
  - **Type**: `Number`
  - **Default**: Current `pitch` value
  - **Description**: The `pitch` value to set
- `roll`
  - **Type**: `Number`
  - **Default**: Current `roll` value
  - **Description**: The `roll` value to set

_**Example Usage**_:

```lua
scene.camera:setRotation(math.pi/2, -math.pi/2, 0)
```

### **scene.camera:addRotation**

Adds a rotation to the camera's current rotation.

_**Arguments**_:

- `yaw`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: The `yaw` value to add
- `pitch`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: The `pitch` value to add
- `roll`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: The `roll` value to add

_**Example Usage**_:

```lua
scene.camera:addRotation(0.1, 0.2, 0.3)
```
