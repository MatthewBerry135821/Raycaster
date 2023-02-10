#include <stdint.h>
#include "raycaster.h"
#include"spriteAdjust.h"

extern uint8_t **spriteTilemap;
extern int spriteSize;
extern int spriteBPP;

void convertSpriteBPP(const int bpp, const int numberOfSprites){//sets sprite to be used with different bpp. the same color will be repeated within a byte to draw multiple pixels at once effectively lowering the resolution
	int mask = 1;
	for(int i = bpp; i > 1; i--){
		mask <<= 1;
		mask += 1;
	}

	for(int i = 0; i < numberOfSprites; ++i){
		for(int j = 2; j < spriteSize*spriteSize+2; ++j){
			uint8_t color;
			color = spriteTilemap[i][j]&mask;
			spriteTilemap[i][j] = color;
			for(int k = bpp;  k < 8; k += bpp){
				spriteTilemap[i][j] += color<<k;
			}
		}
	}
}


