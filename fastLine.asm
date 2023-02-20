section	.text,"ax",@progbits
	assume	adl = 1


include "ixVariables.inc"
include "raycaster.inc"
	
public	_line

_GetColorValue             equ 0021BACh
__imulu		equ 000158h

lcdLpbase		equ 0014h
mpLcdRange		equ 0E30000h
mpLcdLpbase		equ mpLcdRange + lcdLpbase
CurrentBuffer      := mpLcdLpbase


public lineThirdRes
public line

line:
	ld hl, (wallHeight)
	ld de, (_screenHeight)
	ld b, l
	or a, a
	sbc hl, de
	jr c, $+2+4+1
		ld a, (_screenHeight)
		ld b, a
	ld de, 3
	ld hl, (wallSprite)
	add hl, de
	ld a, (hl)

	ld hl, (screenBufferOffset)
	ld de, (_screenAddressingWidth)
	rr d
	rr e
	ld d, b
	mlt de
	or a, a
	sbc hl, de
	sbc hl, de
	ld de, (screenX)
	add hl, de
	ld de, (_screenAddressingWidth)

	srl b
	jr nc, skipQuarter
		srl b
		jr nc, skipHalfJump
		jr loop
	skipQuarter:
		srl b
		jr nc, skipQuarterJump2
		jr skipQuarterJump1

	loop:
		ld (hl), a
		add hl, de
		ld (hl), a
		add hl, de
			skipQuarterJump1:
		ld (hl), a
		add hl, de
		ld (hl), a
		add hl, de
			skipHalfJump:
		ld (hl), a
		add hl, de
		ld (hl), a
		add hl, de
			skipQuarterJump2:
		ld (hl), a
		add hl, de
		ld (hl), a
		add hl, de
	djnz loop
ret

lineThirdRes:
	ld hl, (wallHeight)
	ld de, (_screenHeight)
	ld b, l
	or a, a
	sbc hl, de
	jr c, $+2+4+1
		ld a, (_screenHeight)
		ld b, a
	ld de, 3
	ld hl, (wallSprite)
	add hl, de
	ld a, (hl)
	ld (color), a
	ld (color+1), a
	ld (color+2), a
	ld hl, (screenBufferOffset)
	
	ld de, (_screenAddressingWidth)
	rr d
	rr e
	ld d, b
	mlt de
	or a, a
	sbc hl, de
	sbc hl, de
	ld de, (screenX)
	add hl, de

	ld (saveSP), sp
	ld sp, (_screenAddressingWidth)
	ld de, (color)

	srl b
	jr nc, skipQuarterThirdRes
		srl b
		jr nc, skipHalfJumpThirdRes
		jr loopThirdRes
	skipQuarterThirdRes:
		srl b
		jr nc, skipQuarterJump2ThirdRes
		jr skipQuarterJump1ThirdRes

	loopThirdRes:
		ld (hl), de
		add hl, sp
		ld (hl), de
		add hl, sp
			skipQuarterJump1ThirdRes:
		ld (hl), de
		add hl, sp
		ld (hl), de
		add hl, sp
			skipHalfJumpThirdRes:
		ld (hl), de
		add hl, sp
		ld (hl), de
		add hl, sp
			skipQuarterJump2ThirdRes:
		ld (hl), de
		add hl, sp
		ld (hl), de
		add hl, sp
	djnz loopThirdRes
	ld sp, (saveSP)
ret
color:
	rb 3
saveSP:
	rb 3


extern _screenAddressingWidth
extern _screenHeight