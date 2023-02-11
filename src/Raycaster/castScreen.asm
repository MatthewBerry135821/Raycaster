assume	adl = 1
section .text

include "raycaster.inc"
include "ixVariables.inc"
include "fastRamLayout.inc"

public	_castScreen


macro setNextOctant
	ld b, a
	inc b
	ld c, ANGLE_MULTIPLIER
	mlt bc
	ld b, 45
	mlt bc
	ld (nextOctant), bc
end macro

macro HLxC
	ld b, l;c*l
	ld l, c;h*c
	mlt bc
	mlt hl
	ld c, b
	ld b, 0
	add hl, bc
end macro

_castScreen:
	;saves ix and iy to be used for variable access and as an extra register
	ld (saveIX), ix
	ld (saveIY), iy
	ld ix, VARIABLE_MEMORY_START

	;saves arguments to IX variables
	pop bc
	pop hl
	ld (x), hl
	pop hl
	ld (y), hl
	pop hl
	ld (direction), hl
	push bc
	push bc
	push bc
	push bc

	;copies values to memory accessable by ix for faster access and loading into 8 bit registers
	ld hl, (_spriteSize)
	ld (spriteSize), hl
	ld hl, (_spriteSizeReciprocal)
	ld (spriteSizeReciprocal), hl
	ld hl, (_drawMode)
	ld (drawMode), hl
	ld hl, (_castAngleIncrement)
	ld (castAngleIncrement), hl
	ld hl, (_fovAngleIncrement)
	ld (fovAngleIncrement), hl

	;sets initial and end x positions based on the render width and x position
	ld de, (_screenWidth)
	ld hl, (_xOffset)
	ld (screenX), hl
	add hl, de
	ld (screenXEnd), hl

	;sets the start of the fisheye correction array to the starting angle (center of array - screenWidth*FOV/2)
	ld bc, (_screenWidth)
	srl b
	rr c
	ld hl, (fovAngleIncrement)
	call HL_Times_BC_ShiftedDown

	ld de, 120*ANGLE_MULTIPLIER/2
	ex hl, de
	sbc hl, de
	ex hl, de
	ld hl, (_fishEyeCorrectionTable)
	add hl, de
	add hl, de
	ld (fishEyeCorrectionTable), hl

	;sets the starting angle of the first line to be cast as direction-((screen width)/2)*fov increment
	ld bc, (_screenWidth)
	srl b
	rr c
	ld hl, (_castAngleIncrement)
	call HL_Times_BC_ShiftedDown
	ex hl, de	
	ld hl, (direction)
	sbc hl, de

	;corrects the angle if it becomes negative assuming direction was originally valid
	jr nc, $+2+4+1
		ld de, 360*ANGLE_MULTIPLIER+1
		add hl, de
	ld (castAngle), hl
	
	;loads the starting octant code 
	call getOctant
	ld (octant), a
	setNextOctant

	;copies some functions to the screen cursor ram location to execute faster
	call _copyOctantToFastRam;copying the octant also allows it to be called without checking the current octant except at the start and when the octant changes
	call _copyDiv16ToFastRam
	call setupSpriteFastRam
	call _setScreenBufferOffset

	
	xor a, a
	ld (castAngleIncrementCounter), a
	ld (fovAngleIncrementCounter), a
	mainLoopStart:
		;cast ray
		call OCTANT_FAST_RAM_START;returns a = partial position and a' = wall type
		;partial position is more or less which vertical slice of the wall is drawn but needs corrected based on sprite size since the size of a wall may not be equal to the sprite size
		ld b, (spriteSize)
			srl a
			sla b
		jr nc, $-2-2
		ld (wallSlice), a
		
		;loads pointer to the first pixel in the sprite for the wall hit
		ex af, af'
		ld (wallType), a

		ld hl, (_spriteTilemap)
		ld de, 0
		dec a;wall 1=sprite 0 since 0 is no wall
		ld e, a
		add hl, de
		add hl, de
		add hl, de
		ld de, (hl)
		inc de;skips width/height starting values 
		inc de
		ld (wallSprite), de

		;calculates distance and sets variables to next loops value
		ld hl, (_majorTable)
		ld de, (castAngle)
		add hl, de
		add hl, de
		ld bc, (hl)

		;corrects the distance to remove the fisheye effect 
		ld hl, (fishEyeCorrectionTable)
		ld de, (hl)

		ld hl, 0
		ld h, c
		srl h
		rr l
		
		ex hl, de
		ld b, l;c*l
		ld l, c;h*c
		mlt bc
		mlt hl
		ld c, b
		ld b, 0
		add hl, bc
		add hl, de
		ex hl, de
		
		ld bc, (distance)
		call DIV_16		;HL=DE/BC
		
		;corrects the height to remove the FOV effect
		ld bc, (_heightCorrection)
		call HL_Times_BC_ShiftedDown

		ld (wallHeight), hl

		;calls the drawing routine based on the current drawing mode
		bit 1, (drawMode)
		call z, line
		bit 1, (drawMode)
		call nz, drawSpriteScaled

		;sets up variables for next loop and exits if the end of the screen has been drawn
		ld hl, (screenX)
		inc hl
		ld (screenX), hl

		ld de, (screenXEnd)
		or a, a
		sbc hl, de
		jp nc, exit

		;moves the counter to see if the angle needs incremented more this iteration to fake decimal precision then adds the needed amount to the angle
		;moves the fisheye correction which is limited to 120 deg 
		ld de, 0
		ld e, (fovAngleIncrement+1)
		ld a, (fovAngleIncrement)
		add a, (fovAngleIncrementCounter)
		ld (fovAngleIncrementCounter), a
		jr nc, $+2+1
			inc e
		ld hl, (fishEyeCorrectionTable)
		add hl, de
		add hl, de
		ld  (fishEyeCorrectionTable), hl

		;moves the cast angle counter and cast angle by needed amount for the
		ld e, (castAngleIncrement+1)
		ld a, (castAngleIncrement)
		add a, (castAngleIncrementCounter)
		ld (castAngleIncrementCounter), a
		jr nc, $+2+1
			inc e
		ld hl, (castAngle)
		add hl, de
		ld (castAngle), hl

		;checks if octant has changed and if not continues looping
		ld bc, (nextOctant)
		sbc hl, bc
	jp c, mainLoopStart
	
	;sets up next octant before returning to loop
	ld a, (octant)
	inc a
	cp a, 8
	jr nz, $+2+1+2+3;sets octant and angle to 0 if octant becomes 8 
	xor a, a
	sbc hl, hl
	ld (castAngle), hl

	ld (octant), a
	setNextOctant
	
	call _copyOctantToFastRam
	jp mainLoopStart
		
	exit:
	ld IX, (saveIX)
	ld IY, (saveIY)
ret
nextAngle:
db 0
db 0
db 0
drawSpriteScaled:
	;jumps to drawing routine based on if it needs to be clipped and if the sprite is scaling up or down
	or a, a
	ld de, (_screenHeight)
	sbc hl, de
	jp nc, SCALE_UP_CLIPPED_FAST_RAM_START;this may be used for scaling down with large sprites/short screens, this works but is less efficient than a scaled down clipped routine could be
	add hl, de

	ld de, (spriteSize)
	sbc hl, de
	jp c, _drawSpriteScaledDown
	jp SCALE_UP_FAST_RAM_START



getOctant:
;input:
;hl = angle
;out:
;a = octant angle is in
	
	ld de, 45*ANGLE_MULTIPLIER
	xor a,a
	sbc	hl ,de
	ret c;0
	inc a
	sbc	hl ,de
	ret c;1
	inc a
	sbc	hl ,de
	ret c;2
	inc a
	sbc	hl ,de
	ret c;3
	inc a
	sbc	hl ,de
	ret c;4
	inc a
	sbc	hl ,de
	ret c;5
	inc a
	sbc	hl ,de
	ret c;6
	inc a
	sbc	hl ,de
	ret c;7
	inc a
ret

saveIX:
dw 0
db 0
saveIY:
dw 0
db 0
saveSP:
dw 0
db 0
		extern _fovAngleIncrement

extern lineThirdRes
extern _drawMode
extern _majorTable
extern _fishEyeCorrectionTable
extern _heightCorrection

extern _spriteTilemap
extern  _screenHeight
extern _xOffset
extern _screenWidth
	
extern setupSpriteFastRam
extern _setScreenBufferOffset
extern	_copyDiv16ToFastRam
extern	_drawSpriteScaledDown

extern line

extern	_copyOctantToFastRam


extern _spriteSizeReciprocal
extern _spriteSize
extern _castAngleIncrement


extern HL_Times_BC_ShiftedDown



extern SCALE_UP_SIZE
extern SCALE_UP_CLIPPED_SIZE
extern SCALE_UP_LOOP_SIZE