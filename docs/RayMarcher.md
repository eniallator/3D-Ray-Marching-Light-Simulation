# RayMarcher

Has 4 main classes:

- [**RayMarcher.Scene**](./Scene.md) - Can contain objects and be configured with a range of properties.
- [**RayMarcher.Material**](./Material.md) - Stores properties to do with materials
- [**RayMarcher.Object**](./Object.md) - Can one of any of the implemented objects. All objects must a material.
- [**RayMarcher.Light**](./Light.md) - Shines light on the scene.

## Example Usage

```lua
local RayMarcher = require 'path.to.RayMarcher'
local Scene = RayMarcher.Scene()
```
