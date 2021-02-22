# Light

A data class which has properties for lights to shine on the scene

## Constructor Arguments

- `position`
  - **Type**: `{Number, Number, Number}`
  - **Required**
  - **Description**: Position of the centre of the light.
- `colour`
  - **Type**: `{Number, Number, Number, Number}` all numbers in range `[0, 1]`
  - **Default**: `{1, 1, 1, 1}`
  - **Description**: RGBA colour of the light to shine.
- `brightness`
  - **Type**: `Number` > `0`
  - **Default**: `1`
  - **Description**: How bright the light is.

### Example Constructor

```lua
light = RayMarcher.Light({
    position = {-20, -20, 0},
    colour = {1, 0.75, 0.8},
    brightness = 1.2
})
```
