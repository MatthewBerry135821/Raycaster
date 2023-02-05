assume	adl = 1
section .text

include "raycaster.inc"
include "ixVariables.inc"
include "fastRamLayout.inc"

public	_castScreen


macro setNextOctant
	ld b, a
	inc b
	ld c, ANGLEMULTIPLIER
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

	;copies size to memory accessable by ix for faster access and loading into 8 bit registers
	ld hl, (_spriteSize)
	ld (spriteSize), hl
	ld hl, (_spriteSizeReciprocal)
	ld (spriteSizeReciprocal), hl
	ld hl, (_spriteBPP)
	ld (spriteBPP), hl
	ld hl, (_drawMode)
	ld (drawMode), hl
	ld hl, (_renderFovAngle)
	bit 0, (drawMode)
	jr nz, noFovAdjust
		ld d, h
		ld e, 3
		mlt de
		ld h, e
		ld a, l
		add a, l
		jr nc, $+2+1
			inc h
		add a, l
		jr nc, $+2+1
			inc h
		ld l, a
	noFovAdjust:
	ld (renderFovAngle), hl
	;sets initial and end x positions based on the render width and x position
	ld de, (_screenWidth)
	ld hl, (_xOffset)
	ld (screenX), hl
	add hl, de
			bit 0, (drawMode);lowers the end position if third res so when width is not divisible by 3 it stops early instead of drawing over
			jr nz, $+2+1+1
				dec hl
				dec hl
	ld (screenXEnd), hl
	;sets the start of the fisheye correction to the starting angle (center of array - width*FOV/2)
	ld bc, (_screenWidth)
	srl b
	rr c
	ld hl, (_renderFovAngle)
	call HL_Times_BC_ShiftedDown
	ld de, 360*ANGLEMULTIPLIER/2
	ex hl, de
	sbc hl, de
	ex hl, de
	ld hl, (_fishEyeCorrectionTable)
	add hl, de
	add hl, de
	ld (fishEyeCorrectionTable), hl
	;sets the starting angle to be cast as direction-((screen width)/2)*fov
	ld bc, (_screenWidth)
	srl b
	rr c
	ld hl, (_renderFovAngle)
	call HL_Times_BC_ShiftedDown
	ex hl, de
	ld hl, (direction)
	sbc hl, de
	;corrects the angle if it becomes negative assuming direction was originally valid
	jr nc, $+2+4+1
	ld de, 360*ANGLEMULTIPLIER+1
	add hl, de
	ld (castAngle), hl
	
	call getOctant
	ld (octant), a
	setNextOctant
	;copies some functions to the cursor ram location to execute faster
	call _copyOctantToFastRam;copying the octant allows it to be called without checking the current octant except at the start and when the octant changes
	call _copyDiv16ToFastRam
	call setupSpriteFastRam
	call _setScreenBufferOffset

	
	xor a, a
	ld (angleIncCounter), a
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

		ld a, (renderFovAngle)
		;ld a, e

		sbc hl, hl
		ld l, (renderFovAngle+1)
		add a, (angleIncCounter)
		ld (angleIncCounter), a
		jr nc, $+2+1
			inc d
		
		ex hl, de
		;ld e, 1
		;bit 0, (drawMode)
		;jr nz, $+2+2
		;	ld e, 3
		;mlt de

		ld hl, (castAngle)
			add hl, de
		ld (castAngle), hl
		;corrects the distance to remove the fisheye effect 
		ld hl, (fishEyeCorrectionTable)
			add hl, de
			add hl, de
		ld  (fishEyeCorrectionTable), hl
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
		call DIV_16		
		
		;corrects the distance to remove the FOV effect
		ld bc, (_heightCorrection)
		call HL_Times_BC_ShiftedDown

		ld (wallHeight), hl

		;calls the drawing routine based on the current drawing mode
		bit 0, (drawMode)
		call z, thirdResDraw
		bit 0, (drawMode)
		jr z, thirdResSkip
			bit 1, (drawMode)
			call z, line
			bit 1, (drawMode)
			call nz, drawSpriteScaled
		thirdResSkip:

		;sets up variables for next loop and exits if the end of the screen has been drawn
		ld hl, (screenX)
		inc hl
		ld (screenX), hl

		ld de, (screenXEnd)
		or a, a
		sbc hl, de
		jp nc, exit

		ld hl, (castAngle)

		;checks if octant has changed and if not continues looping
		ld bc, (nextOctant)
		or a, a
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
thirdResDraw:
	;draws 3 rows of the wall (either scaled sprite or lines)
	bit 1, (drawMode)
	jr nz, $+2+3+1+1+3+3
		ld hl, (screenX)
		inc hl
		inc hl
		ld (screenX), hl
		ld hl, (wallHeight)
	bit 1, (drawMode)
	jp z, lineThirdRes

	ld hl, (wallHeight)
	call drawSpriteScaled
	
	ld hl, (screenX)
	inc hl
	ld (screenX), hl
	ld hl, (wallHeight)

	call drawSpriteScaled
	ld hl, (screenX)
	inc hl
	ld (screenX), hl
	ld hl, (wallHeight)
	
	jp drawSpriteScaled
ret
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
	ld de, 45*ANGLEMULTIPLIER
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
extern _spriteBPP
extern _renderFovAngle


extern HL_Times_BC_ShiftedDown



extern SCALE_UP_SIZE
extern SCALE_UP_CLIPPED_SIZE
extern SCALE_UP_LOOP_SIZE