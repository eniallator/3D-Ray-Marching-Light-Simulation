# Material

[Back to RayMarcher](./RayMarcher.md)\
Is a data class which has a number of configurable properties.

## Constructor Arguments

- `colour`
  - **Type**: `{Number, Number, Number}` all numbers in range `[0, 1]`
  - **Default**: `{1, 1, 1}`
  - **Description**: RGB colour of the material.
- `reflectance`
  - **Type**: `Number` in range `[0, 1]`
  - **Default**: `0`
  - **Description**: How much light is reflected off of the material. This value is derived from transparency, using `reflectance * (1 - transparency)`.
- `transparency`
  - **Type**: `Number` in range `[0, 1]`
  - **Default**: `0`
  - **Description**: How much light is passed through the material.
- `speedOfLight`
  - **Type**: `Number`
  - **Default**: `300`
  - **Description**: Affects the angle of refraction.
- `glowStrength`
  - **Type**: `Number` in range `[0, 1]`
  - **Default**: `0`
  - **Description**: Maximum strength that the glow can be.
- `glowRange`
  - **Type**: `Number`
  - **Default**: `0`
  - **Description**: How far the glow reaches.
- `glowColour`
  - **Type**: `{number, number, number}` all numbers in range `[0, 1]`
  - **Default**: `{1, 1, 1}`
  - **Description**: RGB colour of the glow.

### Example Constructor

```lua
glass = RayMarcher.Material({
  colour = {0.776, 0.886, 0.89},
  reflectance = 1.0,
  transparency = 0.9,
  speedOfLight = 200,
  glowStrength = 0.1,
  glowRange = 2,
  glowColour = {1, 1, 0.3}
})
```
