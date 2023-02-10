section	.text,"ax",@progbits
assume	adl = 1

include "raycaster.inc"
include "ixVariables.inc"
include "fastRamLayout.inc"
	
public	_drawSpriteScaledDown

public	_drawSpriteScaledUp
public endOfDrawSpriteScaledUp

public	_drawSpriteScaledUpClipped
public endOfDrawSpriteScaledUpClipped

public scaleUpLoop_Clipped
public endOfScaleUpLoop_Clipped


public _setScreenBufferOffset
public setupSpriteFastRam


public SCALE_UP_SIZE
public SCALE_UP_CLIPPED_SIZE
public SCALE_UP_LOOP_SIZE
SCALE_UP_SIZE := endOfDrawSpriteScaledUp-_drawSpriteScaledUp
SCALE_UP_CLIPPED_SIZE := endOfDrawSpriteScaledUpClipped-_drawSpriteScaledUpClipped
SCALE_UP_LOOP_SIZE := (MAX_SCALE-1)*2+endOfScaleUpLoop_Clipped-scaleUpLoop_Clipped


SCALE_UP_LOOP_END := SCALE_UP_LOOP_FAST_RAM_START+MAX_SCALE*2+endOfScaleUpLoop_Clipped-endOfDrawPixels
incdecDE_FAST_RAM := SCALE_UP_LOOP_END-(endOfScaleUpLoop_Clipped-incdecDE)


lcdLpbase		:= 0014h
mpLcdRange		:= 0E30000h
mpLcdLpbase		:= mpLcdRange + lcdLpbase
CurrentBuffer      := mpLcdLpbase


stackPointer:
rb 3

_setScreenBufferOffset:;* move math to setScreen
	;sets start of draw location (offset for y screen render position)
	;start of buffer + (_screenHeight-height)*320 + _yOffset + x
	ld a, (_screenHeight)
	ld hl, (_screenAddressingWidth)
	rr h
	rr l
	ld h, a
	mlt hl
	add hl, hl
	ld de, (_yOffset)
	add hl, de

	ld de, (CurrentBuffer)
	add hl, de

	ld (screenBufferOffset), hl
ret

setupSpriteFastRam:
	;copy scale down
	;ld bc, endOfDrawSpriteScaledDown-_drawSpriteScaledDown
	;ld hl, _drawSpriteScaledDown
	;ld de, SCALE_DOWN_FAST_RAM_START
	;ldir

	;copy scale up w/0 render loop
	;using different method for non clipped
	ld bc, endOfDrawSpriteScaledUp-_drawSpriteScaledUp
	ld hl, _drawSpriteScaledUp
	ld de, SCALE_UP_FAST_RAM_START
	ldir

	;copy scale up clipped w/0 render loop
	ld bc, endOfDrawSpriteScaledUpClipped-_drawSpriteScaledUpClipped
	ld hl, _drawSpriteScaledUpClipped
	ld de, SCALE_UP_CLIPPED_FAST_RAM_START
	ldir
	
	;make/copy shared scale up (and clipped) loop
	ld bc, endOfScaleUpLoop_Clipped-scaleUpLoop_Clipped
	ld hl, scaleUpLoop_Clipped
	ld de, SCALE_UP_LOOP_FAST_RAM_START
	ldir

	
	;copies pixel drawing a crapload of times
	ld bc, MAX_SCALE*2
	ld hl, scaleUpLoop_Clipped
	ld de, SCALE_UP_LOOP_FAST_RAM_START
	ldi
	ldi
	ld hl, SCALE_UP_LOOP_FAST_RAM_START
	ldir

	ld c, endOfScaleUpLoop_Clipped-endOfDrawPixels
	ld hl, endOfDrawPixels
	ldir
	;doesnt copy jr/jp for looping
	;doesnt copy return code
	;these need copied by scaling function every call
ret


_drawSpriteScaledDown:
	ld bc, (wallHeight)
	;gets the sprite scale as 8.8 fixed
	ld de, 0
	ld d, (spriteSize)
	srl d
	rr e
	call DIV_16;de/bc
	ld (spriteIncAmount), hl

	;sets drawing location
	ld hl, (screenBufferOffset)
	ld de, (_screenAddressingWidth)
	rr d
	rr e
	ld d, c
	mlt de
	sbc hl, de
	sbc hl, de
	ld de, (screenX)
	add hl, de

	exx;sets variables for scaling
		ld l, (wallSlice)
		ld h, (spriteSize)
		mlt hl
		ld bc, (wallSprite)
		add hl, bc
		xor a, a

		ld bc, (spriteIncAmount)
		ld de, (spriteIncAmount-2)
		ld e, a
		ld d, a
		ld iy, 0

		ld c, b
		ld b, a
	exx
	ld de, (_screenAddressingWidth)
	ld b, c
	drawLoop:;loops height times drawing a pixel to the screen
		exx
			; loads pixel, then adds to counter, and moves sprite pointer by needed amount
			ld a, (hl)
			add iy, de
			adc hl, bc
		exx

		ld (hl), a
		add hl, de

		exx
			ld a, (hl)
			add iy, de
			adc hl, bc
		exx

		ld (hl), a
		add hl, de
	djnz drawLoop
	ret
endOfDrawSpriteScaledDown:

_drawSpriteScaledUp:
	ld (stackPointer), sp

	;gets pointer the the section of the sprite to draw
	ld l, (wallSlice)
	ld h, (spriteSize)
	mlt hl
	ld bc, (wallSprite)
	add hl, bc
	ld (spritePtrPlusOffset), hl
	
	;calculates the sprite scale
	ld c, (wallHeight)
	ld b, (spriteSizeReciprocal)
	mlt bc
	ld (spriteIncAmount), bc

	;copies looping and exit code to loop
	ld hl, SCALE_UP_LOOP_END
	ld (hl), 0x30;loop using jr nc
	inc hl
		ld a, -(endOfScaleUpLoop_Clipped-endOfDrawPixels+2);+2 is for jr
		sub a, b
		sub a, b
	ld (hl), a;loop jump size
	inc hl
	ld (hl), 0xED;ld sp, ()
	inc hl
	ld (hl), 0x7B;ld sp, ()
	inc hl
	ld de, stackPointer
	ld (hl), de
	ld a, 0xC9;ret
	ld (SCALE_UP_LOOP_END+4+3), a


	ld a, 0x13
	ld (incdecDE_FAST_RAM), a
	;sets draw location
	ld hl, (screenBufferOffset)
	ld de, (_screenAddressingWidth)
	rr d
	rr e
	ld d, (wallHeight)
	mlt de
	sbc hl, de
	sbc hl, de
	ld de, (screenX)
	add hl, de

	;sets registers to loop values
	ld sp, (_screenAddressingWidth)
	
	add hl, sp

	ld de, (spritePtrPlusOffset)

	ld bc, (spriteIncAmount-2)
	xor a, a
	ld b, a
	ld c, a
	ld iy, 0xffffff
	exx
		ld de, (spriteIncAmount)
		sbc hl, hl
		ld h, (wallHeight)
		add hl, hl
		sbc hl, de
	exx

	
	ld a, (de);load first pixel
	jp SCALE_UP_LOOP_END;jumps to the loop instruction
endOfDrawSpriteScaledUp:



_drawSpriteScaledUpClipped:;height, i

	ld (stackPointer), sp
	;gets pointer to the center of the section of the sprite to draw 

	ld l, (wallSlice)
	ld h, (spriteSize)
	mlt hl
	ld bc, (wallSprite)
	add hl, bc
	ld de, (spriteSize)
	srl e
	dec de
	add hl, de
	ld (spritePtrPlusOffset), hl
	;gets scale(8.8 fixed)
	ld hl, (wallHeight)
	ld de, 0x00FFFF
	sbc hl, de
	add hl, de
	jr c, $+2+4
		ld hl, 0x00FFFF

	ld c, (spriteSizeReciprocal)
	ld b, l;c*l
	ld l, c;h*c
	mlt bc
	mlt hl
	ld a, l
	add a, b
	cp a, 119;caps scale to 120x
	jr c, $+2+2+2
		ld c, 0
		ld a, 120
	inc h
	dec h
	jr z, $+2+2+2
		ld c, 0
		ld a, 120
	ld b, a
	ld (spriteIncAmount), bc


	;copies looping and exit code to loop
	cp a, (127-(endOfScaleUpLoop_Clipped-scaleUpLoop_Clipped-+2))/2;checks if 
	jr nc, jpJump
		ld hl, SCALE_UP_LOOP_END
		ld (hl), 0x30;jr nc
		inc hl
		add a, a
		add a, endOfScaleUpLoop_Clipped-endOfDrawPixels+2
		neg
		ld (hl), a;loop jump size
		inc hl
		
		ld (hl), 0xC3;jp
		inc hl
		ld de, done
		ld (hl), de

	jr skipJumpSet
	jpJump:
		ld a, 0xD2;jp nc
		ld (SCALE_UP_LOOP_END), a;loop jump size
		sbc hl, hl
		ld l, b
		add hl, hl
		ex hl, de
		ld hl, SCALE_UP_LOOP_FAST_RAM_START+MAX_SCALE*2
		sbc hl, de
		ld (SCALE_UP_LOOP_END+1), hl;loop jump location
		
		ld hl, SCALE_UP_LOOP_END+4
		ld (hl), 0xC3;jp
		inc hl
		ld de, done
		ld (hl), de
	skipJumpSet:

	;sets add/dec in loop to move through sprite based on draw direction
	ld a, 0x1B
	ld (incdecDE_FAST_RAM), a

	;sets SP how many bytes need added/subtracted from pointer to move drawing position vertically
	ld hl, 0
	ld de, (_screenAddressingWidth)
	or a, a
	sbc hl, de
	ld sp, hl


	ld hl, (screenBufferOffset)
	ld de, (screenX)
	add hl, de; adds x offset
	ld (drawStartPoint), hl

	;sets registers to loop values
	add hl, sp
	ld de, (spritePtrPlusOffset)
	ld bc, (spriteIncAmount-2)
	xor a, a
	ld b, a
	ld c, a
	ld iy, 0xffffff

	exx
		sbc hl, hl
		ld a, (_screenHeight)
		ld h, a
		ld de, (spriteIncAmount)
		sbc hl, de
		dec de;accounts for carry being set in first half
		ld b, 1
	exx
	ld a, (de);load first pixel then goes to drawing loop
	jp SCALE_UP_LOOP_END
endOfDrawSpriteScaledUpClipped:


done:
	exx
		dec b
		jr nz, exit
		inc de
		add hl, de
		ld a, h		
		cp a, 0
		jr z, noTopPixels
	exx

	ld b, a
	ld a, (de)
	topPixels:
		ld (hl), a
		add hl, sp
	djnz topPixels

	exx
	noTopPixels:
		ld a, (_screenHeight)
		ld h, a
		xor a, a
		ld l, a
		sbc hl, de
	exx
	
	ld sp, (_screenAddressingWidth)
	ld hl, (drawStartPoint)
	ld de, (spritePtrPlusOffset)
	inc de

	ld a, 0x13
	ld (incdecDE_FAST_RAM), a
	
	ld iy, 0xffffff
	ld a, (de);load first pixel then returns to loop to draw other half of the sprite
	
	jp SCALE_UP_LOOP_END
exit:
		add hl, de
		ld a, h
		cp a, 0
		jr z, noBottomPixels
	exx

	ld b, a
	ld a, (de)
	bottomPixels:
		ld (hl), a
		add hl, sp
	djnz bottomPixels
	noBottomPixels:
	ld sp, (stackPointer)
ret

scaleUpLoop_Clipped:
	;loads pixel color into a, vertically draws scale rounded down many pixels, moves partial scale counter and when needed draws and extra pixels, then moves for how many times it should loop and returns when down
	
	drawPixels:
		ld (hl), a
		add hl, sp
	endOfDrawPixels:
		add iy, bc
		jr nc, $+2+1+1
			ld (hl), a
			add hl, sp

		incdecDE:
		dec de
		ld a, (de)
		exx
			sbc hl, de
		exx
	endOfScaleUpLoop_Clipped:
	;jr or jp added depending on scale amount

	exitScaleUpLoop_Clipped:
		jp done
	endOfScaleUpLoopExit_Clipped:

	exitScaleUpLoop_NonClipped:
		ld sp, (stackPointer)
		ret
	endOfScaleUpLoopExit_NonClipped:


extern _yOffset
extern _screenHeight
extern _spriteTilemap
extern _screenAddressingWidth