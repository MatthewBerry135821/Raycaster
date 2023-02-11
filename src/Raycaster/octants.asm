section	.text,"ax",@progbits
	assume	adl = 1

include "raycaster.inc"
include "ixVariables.inc"
include "fastRamLayout.inc"

public 	_copyOctantToFastRam
	
macro calcPartialMovement
	ld c, (tanAngle)	
	ld b, l;c*l
	ld l, c;h*c
	mlt bc
	mlt hl
	ld a, b
	add a, l
end macro


macro loadTangent;expects angle in de
	ld hl, (_tanReciprocalTable)
	add hl, de
	add hl, de
	ld bc, (hl)
	ld (tanReciprocalAngle), bc
	
	ld hl, (_tanTable)
	add hl, de
	add hl, de
	ld bc, (hl)
	ld (tanAngle), bc
end macro


macro xMajorVariableSetup
	ld e, h
	ld b, (x+1)
	ld iyl, e
	xor a
	ex af, af'
	ld a, l
	ld hl, (_mapPtr)
	add hl, de
	ld de, (_mapRowSize)
	ld d, (x+1)
	mlt de
	add hl, de
	ld de, (_mapRowSize)
end macro

macro yMajorVariableSetup:;expects rayY in hl, tangent in BC
	ld de, (_mapRowSize)
	ld d, h
	ld b, (y+1)
	ld iyl, d
	xor a
	ex af, af'
	ld a, l
	ld hl, (_mapPtr)
	mlt de
	add hl, de
	ld d, 0
	ld e, b
	add hl, de
	ld de, (_mapRowSize)
end macro


	
_copyOctantToFastRam:
	ld l, a
	ld h, 4+4+2+1
	mlt hl
	ld de, $+4+1+4+1
	add hl, de
	ld de, OCTANT_FAST_RAM_START
	jp (hl)
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
		ld a, (hl)
		ex af, af'
		;find y distance traveled
		xor a, a
		ld e, a
		ld d, iyl
		ld hl, (minorDirection)
		if minorSign = 1
			ex hl, de
		end if
		sbc hl, de
		;calc x distance traveled
		ld bc, (tanReciprocalAngle)
		call HL_Times_BC_ShiftedDown
		
		ld (distance), hl
		ld a, (majorDirection)
		
		if majorSign = -1
			sub a, l
		else
			add a, l
		end if
		if majorDirection = y
			if minorSign = -1
				neg;makes sprite always render in the same direction;(1+,-)(6+,+)()
			end if
		else
			if minorSign = 1
				neg;makes sprite always render in the same direction;(1+,-)(6+,+)()
			end if
		end if
ret
	.hitMajor:
		ld a, (hl)
		ex af, af'
		;find x distance traveled
		xor a, a
		ld e, a
		ld d, b
		ld hl, (majorDirection)
		if majorSign = 1
			ex hl, de
		end if
		sbc hl, de
		ld (distance), hl
		;find the wall slice
		calcPartialMovement
		if minorSign = 1
			add a, (minorDirection)
		else
			sub a, (minorDirection)
		end if
		
		if majorDirection = y
			if majorSign = minorSign
				neg;makes sprite always render in the same direction;(1+,-)(5-,+)	(3-,-)(7+,+)
			end if
		else
			if majorSign <> minorSign
				neg;makes sprite always render in the same direction;(1+,-)(5-,+)	(3-,-)(7+,+)
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


extern _mapWidth
extern _mapRowSize
extern _mapPtr

extern _tanReciprocalTable
extern _tanTable
extern HL_Times_BC_ShiftedDown
	
extern SCALE_UP_SIZE
extern SCALE_UP_CLIPPED_SIZE
extern SCALE_UP_LOOP_SIZE