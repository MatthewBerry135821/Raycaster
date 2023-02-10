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

macro octantTemplate xDirection, yDirection
	;ld de, (castAngle)
	;ld hl, 90*ANGLE_MULTIPLIER
	;xor a, a
	;sbc hl, de
	;ex hl, de
	loadTangent

	;finds the starting x position accounting for the starting y position being rounded to the side
	;starting y will be rounded in the opposite direction as it is traveling
	;starting x can be found by multiplying the y difference by tan and adding/subtracting it from x
	;(((-yPartial-1)*tan)>>8) +/- x
	ld a, (y)
	if yDirection = -1
		neg
		dec a
	end if
	ld e, a
	ld d, c
	mlt de
	ld e, d
	ld d, 0
	ld hl, (x)
	if xDirection = 1
		sbc hl, de
	else
		add hl, de
	end if

	yMajorVariableSetup

	if yDirection = -1
		inc b;if y is negative
	end if

	if xDirection = -1
		inc iyl; if x is negative
		sbc a, c
	else
		add a, c
	end if
	
	jr c, .moveX
	.loop:
		ex af, af'
		if yDirection = -1
			dec hl;hl points to map position
			dec b;tracks how much y moved
		else
			inc hl;hl points to map position
			inc b;tracks how much y moved
		end if
		cp a, (hl)
		jr nz, .hitY

		ex af, af'
		if xDirection = -1
			sbc a, c
		else
			add a, c
		end if
	jr nc, .loop
	.moveX:
		ex af, af'
		if xDirection = -1
			sbc hl, de
			dec iyl
		else
			add hl, de
			inc iyl
		end if
		cp a, (hl)
	jr z, .loop+1;+1 skips the ex af, af'

	.hitX:
		ld a, (hl)
		ex af, af'
		;find y distance traveled
		xor a, a
		ld e, a
		ld d, iyl
		ld hl, (x)
		if xDirection = 1
			ex hl, de
		end if
		sbc hl, de
		;calc x distance traveled
		ld bc, (tanReciprocalAngle)
		call HL_Times_BC_ShiftedDown
		
		ld (distance), hl
		ld a, (y)
		
		if yDirection = -1
			sub a, l
		else
			add a, l
		end if
		if xDirection = 1
			neg;makes sprite always render in the same direction;(1+,-)(6+,+)()
		end if
ret
	.hitY:
		ld a, (hl)
		ex af, af'
		;find x distance traveled
		xor a, a
		ld e, a
		ld d, b
		ld hl, (y)
		if yDirection = 1
			ex hl, de
		end if
		sbc hl, de
		ld (distance), hl
		;find the wall slice
		calcPartialMovement
		if xDirection = 1
			add a, (x)
		else
			sub a, (x)
		end if
		if yDirection <> xDirection
			neg;makes sprite always render in the same direction;(1+,-)(5-,+)()
		end if
ret
end macro

_octant1:
	ld de, (castAngle)
	ld hl, 90*ANGLE_MULTIPLIER
	xor a, a
	sbc hl, de
	ex hl, de
	octantTemplate 1, -1
endOfOctant1:

	
_octant2:
	ld hl, (castAngle)
	ld de, 90*ANGLE_MULTIPLIER
	xor a, a
	sbc hl, de
	ex hl, de
	octantTemplate -1, -1
endOfOctant2:

_octant5:
	ld hl, (castAngle)
	ld de, 270*ANGLE_MULTIPLIER
	xor a, a
	ex hl, de
	sbc hl, de
	ex hl, de
	octantTemplate -1, 1
endOfOctant5:

_octant6:
	ld hl, (castAngle)
	ld de, 270*ANGLE_MULTIPLIER
	xor a, a
	sbc hl, de
	ex hl, de
	octantTemplate 1, 1
endOfOctant6:
	loadTangent

	;sets rayX accounting for the difference between Y and rayY
	ld a, (y)
	ld e, a
	ld d, c
	mlt de
	ld e, d
	ld d, 0
	ld hl, (x)
	sbc hl, de

	yMajorVariableSetup

	;inc b;if y is negative
	;inc iyl; if x is negative

	add a, c
	jr c, moveX6
	loop6:
		ex af, af'
		inc hl
		inc b
		cp a, (hl)
		jr nz, hitY6

		ex af, af'
		add a, c
	jr nc, loop6
	moveX6:
		ex af, af'
		add hl, de
		inc iyl
		cp a, (hl)
	jr z, loop6+1;+1 skips the ex af, af'

	hitX6:
		ld a, (hl)
		ex af, af'
		;find y distance traveled
		xor a, a
		ld e, a
		ld d, iyl
		ex hl, de
		ld de, (x)
		sbc hl, de
		;calc x distance traveled
		ld bc, (tanReciprocalAngle)
		call HL_Times_BC_ShiftedDown
		
		ld (distance), hl
		ld a, (y)
		add a, l
		neg
ret
	hitY6:
		ld a, (hl)
		ex af, af'
		;find x distance traveled
		xor a, a
		sbc hl, hl
		ld h, b
		ld de, (y)
		sbc hl, de
		ld (distance), hl
		;find the wall slice
		calcPartialMovement
		add a, (x)
		;neg
ret
;endOfOctant6:


_octant0:;returns partial wall pos in a and wall type in a'
	ld de, (castAngle);set angle as angle within octant
	loadTangent

	;sets rayY accounting for the difference between X and rayX
	ld a, (x)
	ld e, a
	ld d, c
	mlt de
	ld e, d
	ld d, 0
	ld hl, (y)
	add hl, de
	
	xMajorVariableSetup
	;inc b;if x is negative
	inc iyl; if y is negative

	sbc a, c
	jr c, moveY
	loop:
		ex af, af'
		add hl, de
		inc b
		cp a, (hl)
		jr nz, hitX

		ex af, af'
		sbc a, c
	jr nc, loop
	moveY:
		dec hl
		dec iyl
		ex af, af'
		cp a, (hl)
	jr z, loop+1;+1 skips the ex af, af'

	hitY:
		ld a, (hl)
		ex af, af'
		;find y distance traveled
		xor a, a
		ld e, a
		ld d, iyl
		ld hl, (y)
		sbc hl, de
		;calc x distance traveled
		ld bc, (tanReciprocalAngle)
		call HL_Times_BC_ShiftedDown
		
		ld (distance), hl
		ld a, l
		add a, (x)
		neg	
ret
	hitX:
		ld a, (hl)
		ex af, af'
		;find x distance traveled
		xor a, a
		sbc hl, hl
		ld h, b
		ld de, (x)
		sbc hl, de
		ld (distance), hl
		;find the wall slice
		calcPartialMovement
		sub a, (y)
		;neg
ret
endOfOctant0:
	

_octant3:
	ld de, (castAngle);set angle as angle within octant
	ld hl, 180*ANGLE_MULTIPLIER
	or a, a
	sbc hl, de
	ex hl,de
	loadTangent

	;sets rayY accounting for the difference between X and rayX
	ld a, (x)
		neg
		dec a
	ld e, a
	ld d, c
	mlt de
	ld e, d
	ld d, 0
	ld hl, (y)
	add hl, de
	
	xMajorVariableSetup

	inc b;if x is negative
	inc iyl; if y is negative
	sub a, c
	jr c, moveY3
	loop3:
		ex af, af'
		sbc hl, de
		dec b
		cp a, (hl)
		jr nz, hitX3

		ex af, af'
		sub a, c
	jr nc, loop3
	moveY3:
		dec hl
		dec iyl
		ex af, af'
		cp a, (hl)
	jr z, loop3+1;+1 skips the ex af, af'

	hitY3:
		ld a, (hl)
		ex af, af'

		;find y distance traveled
		xor a, a
		ld e, a
		ld d, iyl
		
		ld hl, (y)
		sbc hl, de
		;calc x distance traveled
		ld bc, (tanReciprocalAngle)
		call HL_Times_BC_ShiftedDown
		
		ld (distance), hl
		ld a, l
		sub a, (x)
		;neg		
ret
		
	hitX3:
		ld a, (hl)
		ex af, af'
		;find x distance traveled
		xor a, a
		ld e, a
		ld d, b
		ld hl, (x)
		sbc hl, de
		ld (distance), hl
		;find the wall slice
		calcPartialMovement
		sub a, (y)
		neg
ret
endOfOctant3:

_octant4:
	ld hl, (castAngle);set angle as angle within octant
	ld de, 180*ANGLE_MULTIPLIER
	or a, a
	sbc hl, de
	ex hl, de

loadTangent
	;sets rayY accounting for the difference between X and rayX
	ld a, (x)
		neg
		dec a
	ld e, a
	ld d, c
	mlt de
	ld e, d
	ld d, 0
	ld hl, (y)
	sbc hl, de

	xMajorVariableSetup
	;end up calculation/var setup

	inc b;if x is negative
	;inc iyl; if y is negative
	add a, c
	jr c, moveY4
	loop4:
		ex af, af'
		sbc hl, de
		dec b
		cp a, (hl)
		jr nz, hitX4

		ex af, af'
		add a, c
	jr nc, loop4
	moveY4:
		inc hl
		inc iyl
		ex af, af'
		cp a, (hl)
	jr z, loop4+1;+1 skips the ex af, af'

	hitY4:
		ld a, (hl)
		ex af, af'
		;find y distance traveled
		xor a, a
		ld e, a
		ld d, iyl
		ld hl, (y)
		ex hl, de
		sbc hl, de
		;calc x distance traveled
		ld bc, (tanReciprocalAngle)
		call HL_Times_BC_ShiftedDown
		
		ld (distance), hl
		ld a, l
		sub a, (x)
		neg
ret
	hitX4:
		ld a, (hl)
		ex af, af'
		;find x distance traveled
		xor a, a
		ld e, a
		ld d, b
		ld hl, (x)
		sbc hl, de
		ld (distance), hl
		;find the wall slice
		calcPartialMovement
		add a, (y)
		;neg
ret
endOfOctant4:

_octant7:
	ld de, (castAngle);set angle as angle within octant
	ld hl, 360*ANGLE_MULTIPLIER
	or a, a
	sbc hl, de

	ex hl, de
	loadTangent

	;sets rayY accounting for the difference between X and rayX
	ld a, (x)
	ld e, a
	ld d, c
	mlt de
	ld e, d
	ld d, 0
	ld hl, (y)
	sbc hl, de

	xMajorVariableSetup
	
	;inc b;if x is negative
	;inc iyl; if y is negative

	adc a, c
	jr c, moveY7
	loop7:
		ex af, af'
		add hl, de
		inc b
		cp a, (hl)
		jr nz, hitX7

		ex af, af'
		adc a, c
	jr nc, loop7
	moveY7:
		inc hl
		inc iyl
		ex af, af'
		cp a, (hl)
	jr z, loop7+1;+1 skips the ex af, af'

	hitY7:
		ld a, (hl)
		ex af, af'
		;find y distance traveled
		xor a, a
		ld e, a
		ld d, iyl
		ex hl, de
		ld de, (y)
		sbc hl, de
		;calc x distance traveled
		ld bc, (tanReciprocalAngle)
		call HL_Times_BC_ShiftedDown
		
		ld (distance), hl
		ld a, l
		add a, (x)	
ret
	hitX7:
		ld a, (hl)
		ex af, af'
		;find x distance traveled
		xor a, a
		sbc hl, hl
		ld h, b
		ld de, (x)
		sbc hl, de
		ld (distance), hl
		;find the wall slice
		calcPartialMovement
		add a, (y)
		neg				
ret
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