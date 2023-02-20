variables := ix
variableOffset = 0
macro declare name, size
	name = (variables+variableOffset)
	variableOffset = variableOffset + size
end macro

declare screenPosition, 3
declare direction, 3
declare x, 3
declare y, 3

declare	octant, 3
declare distance, 3
declare wallHeight, 3
declare wallSlice, 3
declare wallSprite, 3
declare fishEyeCorrectionAngle, 3
declare screenX, 3
declare screenXEnd, 3
declare castAngle, 3
declare octantAddress, 3

declare fishEyeCorrectionTable, 3
declare tanReciprocalAngle, 3
declare tanAngle, 3
declare nextOctant, 3
declare spriteIncAmount, 3
declare spritePtrPlusOffset, 3
declare screenBufferOffset, 3
declare drawStartPoint, 3

declare spriteSize, 3
declare spriteSizeReciprocal, 3
declare spriteTilemap, 3
declare drawMode, 3
declare castAngleIncrement, 3
declare castAngleIncrementCounter, 3
declare fovAngleIncrement, 3
declare fovAngleIncrementCounter, 3
declare mapRowSize, 3
declare mapPtr, 3
declare majorTable, 3

if variableOffset >= 127
        err 'IX range exceeded'
end if