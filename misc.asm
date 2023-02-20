section	.text,"ax",@progbits
	assume	adl = 1

include "raycaster.inc"
include "ixVariables.inc"
include "fastRamLayout.inc"

public _div16ASMCall
public _divLbyBCx256
public _copyDiv16ToFastRam
public HL_Times_BC_ShiftedDown
public _setBPP

_setBPP:
	pop bc
	pop de
	push de
	push bc

	ld	hl,0xE30000+0x018+0
	ld	a,(hl)
	and a, 0xF1
	
	ld d, 0

	srl e
	jr c, skipBpp0
		inc d
		srl e
	jr nc, $-2-1
	skipBpp0:
	or a, a
	sla d
	add a, d
	ld	(hl),a
ret


HL_Times_BC_ShiftedDown:;multiplies hl and bc with the result in hl (alters HL, BC, DE)
	ld d, c
	ld e, l
	ld l, b
	push hl
	
	ld l, c
	ld c, e
	mlt bc
	mlt hl
	mlt de
	ld e, d
	ld d, 0
	add hl, bc
	add hl, de

	pop de
	mlt de
	ld d, e
	ld e, 0
	add hl, de
ret


_div16ASMCall:;divided DE by BC, HL is result and DE is remainder
	xor a 
	sbc hl,hl

	ld a,d
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	cpl 
	ld d,a
_divLbyBCx256:
	ld a,e
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	adc hl,hl 
	sbc hl,bc 
	jr nc,$+3 
		add hl,bc
	rla 
	cpl 
	ld e,a
	ex hl, de
ret
_div16End:

_copyDiv16ToFastRam:
	ld bc, _div16End-_div16ASMCall
	ld hl, _div16ASMCall
	ld de, DIV_16
	ldir
ret


extern SCALE_UP_SIZE
extern SCALE_UP_CLIPPED_SIZE
extern SCALE_UP_LOOP_SIZE