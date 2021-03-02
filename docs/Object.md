# Object

A data class containing properties and methods for all objects

## Method Index

- [object:setData](#objectsetData)
- [object:setPosition](#objectsetPosition)
- [object:addAbsolutePosition](#objectaddAbsolutePosition)
- [object:addRelativePosition](#objectaddRelativePosition)
- [object:setScale](#objectsetScale)
- [object:setRotation](#objectsetRotation)
- [object:addRotation](#objectaddRotation)

## Constructor Arguments

- `type`
  - **Type**: `String` one of the following: `('cube', 'insideCube', 'sphere', 'cylinder', 'mandelbulb')`
  - **Required**
  - **Description**: Defines what type of object to render.
- `material`
  - **Type**: `Material`
  - **Required**
  - **Description**: What type of material to render the object with.
- `data`
  - **Type**: `Table` containing custom properties for the `type` of object. Properties defined:
    - `cube`: `{width = Number > 0, height = Number > 0, depth = Number > 0}`
    - `insideCube`: `{width = Number > 0, height = Number > 0, depth = Number > 0}`
    - `sphere`: `{radius = Number > 0}`
    - `cylinder`: `{radius = Number > 0, height = Number > 0}`
    - `mandelbulb`: `{power = Number > 0, iterations = Number (Integer) > 0, boundingRadius = Number > 0}`
  - **Required**
  - **Description**: Defines the properties for each of the object types.
- `position`
  - **Type**: `{Number, Number, Number}`
  - **Required**
  - **Description**: Centre position of the object.
- `scale`
  - **Type**: `{Number, Number, Number}`
  - **Default**: `{1, 1, 1}`
  - **Description**: Object's scale using x, y, and z properties.
- `rotation`
  - **Type**: `{Number, Number, Number}`
  - **Default**: `{0, 0, 0}`
  - **Description**: Object's rotation using yaw, pitch, and roll properties.

### Example Constructor

```lua
room = RayMarcher.Object({
    type = 'insideCube',
    material = roomMaterial,
    data = {width = 100, height = 100, depth = 100},
    position = {0, 0, 0},
    scale = {1, 2, 3},
    rotation = {0, math.pi / 2, math.pi / 2},
})
```

## Object Methods

### **object:setData**

Sets new data for the current object.

_**Arguments**_:

- `newData`
  - **Type**: `ObjectData` see the `data` [constructor argument](#constructor-arguments) for types
  - **Description**: New data to set.

_**Example Usage**_:

```lua
cube:setData({width = 10, height = 15, depth = 20})
```

### **object:setPosition**

Sets the object's position in the scene.

_**Arguments**_:

- `x`
  - **Type**: `Number`
  - **Default**: Current `x` coordinate
  - **Description**: The object's `x` coordinate
- `y`
  - **Type**: `Number`
  - **Default**: Current `y` coordinate
  - **Description**: The object's `y` coordinate
- `z`
  - **Type**: `Number`
  - **Default**: Current `z` coordinate
  - **Description**: The object's `z` coordinate

_**Example Usage**_:

```lua
object:setPosition(1, 2, 3)
```

### **object:addAbsolutePosition**

Adds an absolute position to the object's current position.

_**Arguments**_:

- `x`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: The value to add to the object's `x` coordinate
- `y`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: The value to add to the object's `y` coordinate
- `z`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: The value to add to the object's `z` coordinate

_**Example Usage**_:

```lua
object:addAbsolutePosition(4, 5, 6)
```

### **object:addRelativePosition**

Adds a relative position in the direction the object is facing, to the object's current position.

_**Arguments**_:

- `x`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: How far forward to move the object.
- `y`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: How far left to move the object.
- `z`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: How far down to move the object.

_**Example Usage**_:

```lua
object:addRelativePosition(7, 8, 9)
```

### **object:setScale**

Sets the object's current scale

_**Arguments**_:

- `x`
  - **Type**: `Number`
  - **Default**: Current `x` scale
  - **Description**: New `x` scale to set.
- `y`
  - **Type**: `Number`
  - **Default**: Current `y` scale
  - **Description**: New `y` scale to set.
- `z`
  - **Type**: `Number`
  - **Default**: Current `z` scale
  - **Description**: New `z` scale to set.

_**Example Usage**_:

```lua
object:setScale(4, 5, 6)
```

### **object:setRotation**

Sets the object's current rotation.

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
object:setRotation(math.pi/2, -math.pi/2, 0)
```

### **object:addRotation**

Adds a rotation to the object's current rotation.

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
object:addRotation(0.1, 0.2, 0.3)
```
