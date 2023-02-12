section	.text,"ax",@progbits
	assume	adl = 1

include "raycaster.inc"
include "ixVariables.inc"
include "fastRamLayout.inc"

public 	_copyOctantToFastRam
	
;finds the how far the minor direction should be in the wall (or what slice will be drawn)
;expects hl to be major distance traveled
;result is stored in a
macro calcPartialMovement
	ld c, (tanAngle)	
	ld b, l;c*l
	ld l, c;h*c
	mlt bc
	mlt hl
	ld a, b
	add a, l
end macro

;loads the tangent and the reciprocal of the tangent so it can be accessed faster
;expects angle in de
;tangent will be in c
macro loadTangent
	ld hl, (_tanReciprocalTable);tanReciprocalAngle should be 8.8 fixed
	add hl, de
	add hl, de
	ld bc, (hl)
	ld (tanReciprocalAngle), bc
	
	ld hl, (_tanTable);tanAngle should be 0.8 fixed
	add hl, de
	ld c, (hl)
	ld (tanAngle), c
end macro

;expects x to be the major direction the starting y position in hl
macro xMajorVariableSetup
	ld e, h
	ld b, (x+1);b should be major position
	ld iyl, e;iyl should be minor position
	xor a;Alt a needs to be 0 for checking against a wall to determine if the ray has hit
	ex af, af'
	ld a, l;A is set to the partial value of the minor position for the counter to determing when minor position moves a full space
	ld hl, (mapPtr);Sets the y position in the map (y is sequential in memory)
	add hl, de
	ld e, (mapRowSize);Sets the x position in the map (x is multiplied by the row size the get is position in memory)
	ld d, (x+1)
	mlt de
	add hl, de;map position should be stored in hl
	ld de, (mapRowSize);rowSize needs to be in de for the loop to traverse the map
end macro

;expects y to be the major direction the starting x position in hl
macro yMajorVariableSetup;expects rayY in hl, tangent in BC
	ld e, (mapRowSize)
	ld d, h
	ld b, (y+1);b should be major position
	ld iyl, d;iyl should be minor position
	xor a;Alt a is used to compare if there is a wall at the current position and needs to be 0 (or whatever represents no wall)
	ex af, af'
	ld a, l;the other a is also used as a counter to track when the minor position gets moved
	ld hl, (mapPtr)
	mlt de
	add hl, de
	ld d, 0;sets x position in map
	ld e, b
	add hl, de;map position should be stored in hl
	ld e, (mapRowSize);rowSize needs to be in de for the loop to traverse the map
end macro


;copies an octant to the cursor ram for faster execution and calling all octants with the same instruction
;expects the octant to be copied in a
_copyOctantToFastRam:
	ld l, a
	ld h, copyOctant1-copyOctant0
	mlt hl
	ld de, startOfCopying
	add hl, de
	ld de, OCTANT_FAST_RAM_START
	jp (hl)
	startOfCopying:
	copyOctant0:
	ld bc, endOfOctant0 - _octant0
	ld hl, _octant0
	ldir
	ret
	copyOctant1:
	ld bc, endOfOctant1 - _octant1
	ld hl, _octant1
	
	ldir
	ret
	copyOctant2:
	ld bc, endOfOctant2 - _octant2
	ld hl, _octant2
	ldir
	ret
	copyOctant3:
	ld bc, endOfOctant3 - _octant3
	ld hl, _octant3
	ldir
	ret
	copyOctant4:
	ld bc, endOfOctant4 - _octant4
	ld hl, _octant4
	ldir
	ret
	copyOctant5:
	ld bc, endOfOctant5 - _octant5
	ld hl, _octant5
	ldir
	ret
	copyOctant6:
	ld bc, endOfOctant6 - _octant6
	ld hl, _octant6
	ldir
	ret
	copyOctant7:
	ld bc, endOfOctant7 - _octant7
	ld hl, _octant7
	ldir
	ret

;this macro generates the code to cast a ray in a given octant
;casting the ray will expect castAngle to be an angle that falls within the called octant and x/y to be 8.8 fixed point values for the position to cast from
;(distance) will be set to the major distance traveled, a to the slice of the wall to be drawn, and a' to the type of wall to be drawn
macro octantTemplate minorSign, majorSign, majorDirection
	if majorDirection = y
		minorDirection = x
	else
		minorDirection = y
	end if
	loadTangent

	;finds the starting x position accounting for the starting y position being rounded to the side
	;starting y will be rounded in the opposite direction as it is traveling
	;starting x can be found by multiplying the y difference by tan and adding/subtracting it from x
	;(((-yPartial-1)*tan)>>8) +/- x

	ld a, (majorDirection)
	if majorSign = -1
		neg
		dec a
	end if
	ld e, a
	ld d, c
	mlt de
	ld e, d
	ld d, 0
	ld hl, (minorDirection)
	if minorSign = 1
		sbc hl, de
	else
		add hl, de
	end if

	if majorDirection = y
		yMajorVariableSetup
	else
		xMajorVariableSetup
	end if

	if majorSign = -1
		inc b;if y is negative
	end if

	if minorSign = -1
		inc iyl; if x is negative
		sbc a, c
	else
		add a, c
	end if
	
	jr c, .moveMinor
	.loop:
		ex af, af'
		if majorSign = -1
			if majorDirection = y
				dec hl;hl points to map position
			else
				sbc hl, de
			end if
			dec b;tracks how much major dir moved
		else
			if majorDirection = y
				inc hl;hl points to map position
			else
				add hl, de
			end if
			inc b;tracks how much major dir moved
		end if
		cp a, (hl)
		jr nz, .hitMajor

		ex af, af'
		if minorSign = -1
			sbc a, c
		else
			add a, c
		end if
	jr nc, .loop
	.moveMinor:
		ex af, af'
		if minorSign = -1
			if majorDirection = y
				sbc hl, de
			else
				dec hl;hl points to map position
			end if
			dec iyl;tracks how far minor dir has moved
		else
			if majorDirection = y
				add hl, de
			else
				inc hl;hl points to map position
			end if
			inc iyl
		end if
		cp a, (hl)
	jr z, .loop+1;+1 skips the ex af, af'

	.hitMinor:
		ld a, (hl);the type of wall hit should be stored in the alt a register
		ex af, af'
		;find minor distance traveled as |start position - end position|
		xor a, a
		ld e, a
		ld d, iyl
		ld hl, (minorDirection)
		if minorSign = 1;ex hl, de must be used instead of loading the values to the appropriate registers becuase ld h, iyl is invalid
			ex hl, de
		end if
		sbc hl, de

		;find major distance traveled as (minor distance)/tan(angle) or (minor distance) * (1/tan(angle))
		ld bc, (tanReciprocalAngle)
		call HL_Times_BC_ShiftedDown
		ld (distance), hl;distance must always be stored at the major distance traveled
		;finds the part of the wall to draw based on the direction that did not hit (is in between sides)
		ld a, (majorDirection);the part of the wall to be draw should be stored in the a register
		if majorSign = -1;adds/subtracts the partial minor distance traveld based on minor direction
			sub a, l
		else
			add a, l
		end if

		if majorDirection = y;fixes sign shenanigans which could result in the texture being flipped
			if minorSign = -1
				neg
			end if
		else
			if minorSign = 1
				neg
			end if
		end if
ret
	.hitMajor:
		ld a, (hl);the type of wall hit should be stored in the alt a register
		ex af, af'
		;find major distance traveled as |start position - end position|
		xor a, a
		if majorSign = 1;does sign checking since each octant will only go one direction we can just swap the order
			sbc hl, hl
			ld h, b
			ld de, (majorDirection)
		else
			ld e, a
			ld d, b
			ld hl, (majorDirection)
		end if
		sbc hl, de
		ld (distance), hl
		;find the wall slice to be drawn which is stored in the a register
		calcPartialMovement
		if minorSign = 1;adds/subtracts the partial minor distance traveld based on minor direction
			add a, (minorDirection)
		else
			sub a, (minorDirection)
		end if
		
		if majorDirection = y;fixes sign shenanigans which could result in the texture being flipped
			if majorSign = minorSign
				neg
			end if
		else
			if majorSign <> minorSign
				neg
			end if
		end if
ret
end macro

_octant1:
	ld de, (castAngle)
	ld hl, 90*ANGLE_MULTIPLIER
	xor a, a
	sbc hl, de
	ex hl, de
	octantTemplate 1, -1, y
endOfOctant1:

	
_octant2:
	ld hl, (castAngle)
	ld de, 90*ANGLE_MULTIPLIER
	xor a, a
	sbc hl, de
	ex hl, de
	octantTemplate -1, -1, y
endOfOctant2:

_octant5:
	ld hl, (castAngle)
	ld de, 270*ANGLE_MULTIPLIER
	xor a, a
	ex hl, de
	sbc hl, de
	ex hl, de
	octantTemplate -1, 1, y
endOfOctant5:

_octant6:
	ld hl, (castAngle)
	ld de, 270*ANGLE_MULTIPLIER
	xor a, a
	sbc hl, de
	ex hl, de
	octantTemplate 1, 1, y
endOfOctant6:

_octant0:;returns partial wall pos in a and wall type in a'
	ld de, (castAngle);set angle as angle within octant
	octantTemplate -1, 1, x
endOfOctant0:	

_octant3:
	ld de, (castAngle);set angle as angle within octant
	ld hl, 180*ANGLE_MULTIPLIER
	or a, a
	sbc hl, de
	ex hl,de
	octantTemplate -1, -1, x
endOfOctant3:
	
_octant4:
	ld hl, (castAngle);set angle as angle within octant
	ld de, 180*ANGLE_MULTIPLIER
	or a, a
	sbc hl, de
	ex hl, de
	octantTemplate 1, -1, x
endOfOctant4:

_octant7:
	ld de, (castAngle);set angle as angle within octant
	ld hl, 360*ANGLE_MULTIPLIER
	or a, a
	sbc hl, de

	ex hl, de
	octantTemplate 1, 1, x
endOfOctant7:


extern _mapRowSize

extern _tanReciprocalTable
extern _tanTable
extern HL_Times_BC_ShiftedDown
	
extern SCALE_UP_SIZE
extern SCALE_UP_CLIPPED_SIZE
extern SCALE_UP_LOOP_SIZE