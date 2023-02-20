assume	adl = 1
section .text

include "raycaster.inc"
include "ixVariables.inc"
include "fastRamLayout.inc"

public	_castRay
_castRay:
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
	;ld (direction), hl
	ld (castAngle), hl
	push bc
	push bc
	push bc
	push bc

	;copies values to memory accessable by ix for faster access and loading into 8 bit registers
	ld hl, (_mapPtr)
	ld (mapPtr), hl

	;loads the starting octant code. this must be directly before _copyOctantToFastRam (a must be set to the octant when called)
	call getOctant

	;copies some functions to the screen cursor ram location to execute faster
	call _copyOctantToFastRam;copying the octant also allows it to be called without checking the current octant except at the start and when the octant changes



		call OCTANT_FAST_RAM_START;returns a = partial position and a' = wall type
		
		
		;calculates distance and sets variables to next loops value
		ld hl, (majorTable)
		ld de, (castAngle)
		add hl, de
		ld c, (hl); 0.8 fixed point value for sin/cos depending on the octant
		ld bc, (distance)
		call _div16ASMCall;HL=DE/BC
	exit:
	ld IX, (saveIX)
	ld IY, (saveIY)
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

extern getOctant
extern _div16ASMCall
extern _mapPtr
extern	_copyOctantToFastRam





extern SCALE_UP_SIZE
extern SCALE_UP_CLIPPED_SIZE
extern SCALE_UP_LOOP_SIZE