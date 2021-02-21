local outerFolder = (...):match('(.-)[^%.]+$')

return {
    Scene = require(outerFolder .. 'scene'),
    Object = require(outerFolder .. 'scene-data.object'),
    Material = require(outerFolder .. 'scene-data.material'),
    Light = require(outerFolder .. 'scene-data.light')
}
