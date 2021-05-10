# 3D-Ray-Marching-Light-Simulation

The source code for my final year project in university.

[Docs](./docs/RayMarcher.md)

## Running Instructions (Windows)

To run this project, firstly download and extract [LÖVE 11.3](https://love2d.org/#download).
Once it is extracted, there should be a `love.exe` file, simply drag and drop the entire outer project folder onto that executable, and it should launch the project.

## To Run Success Criteria

`main.lua` is the entry point for this game engine, so you need to:
Copy the desired success criteria scene into the base level folder and name it `main.lua` (you will have to rename the current `main.lua`).

## To Test

You must have luafilesystem installed, as the test runner uses this.
Once you have this dependency, run the following command:

```properties
lua test.lua
```
