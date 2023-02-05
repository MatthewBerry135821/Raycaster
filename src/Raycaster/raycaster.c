#include <math.h>
#include <fileioc.h>

#include "raycaster.h"

#define TODEG (0.0174533)

int spriteSize;
int spriteSizeReciprocal;
int spriteBPP;
int renderFovAngle;
int renderFov;
int screenAddressingWidth;

int mapWidth;
int mapHeight;
uint8_t *mapPtr;

uint16_t *fishEyeCorrectionTable;
uint16_t *tanTable;
uint16_t *tanReciprocalTable;
uint16_t *majorTable;
uint16_t heightCorrection;

int drawMode;
uint8_t **spriteTilemap;
int numberOfSprites;

int screenHeight;
int screenWidth;
int xOffset;
int yOffset;


uint8_t loadTables();//returns 0 on success
uint8_t createTables();//returns 0 on success



uint8_t initializeEngine(uint8_t *map, int witdth, int height, int textured){//returns 0 on success
	mapPtr = map;
	mapWidth = witdth;
	mapHeight = height;
	drawMode = textured;
	if(loadTables() != 0){
		createTables();
		return loadTables();
	}
	return 0;
}

void linkTilemap(uint8_t** tiles, int amount, uint8_t size, uint8_t bpp){//links a tilemap for the raycaster to use as wall sprites
	setBPP(bpp);
	numberOfSprites = amount;
	spriteTilemap = tiles;
	spriteSize = size;
	spriteSizeReciprocal = 256/(spriteSize/2);
	screenAddressingWidth = 320/(8/spriteBPP);
}

void setScreen(int x, int y, int width, int height, int fov){//sets the screen offsets and dimensions
	yOffset = y*320/(8/spriteBPP);
	screenHeight = height/2;
	xOffset = x;
	screenWidth = width;
	if(fov>120)fov=120;
	renderFovAngle = (fov*ANGLEMULTIPLIER*256)/screenWidth;
	renderFov = fov;
	heightCorrection = 64*0xFF/(fov*(320/(8/spriteBPP))/screenWidth);//multiplied to wall height to correct for fov, screen width, and bpp causing shrunk walls
}

uint8_t loadTables(){//loads trig table from an appvar
	int appvarSlot;
	int appvarSize = (360*ANGLEMULTIPLIER*2+90*ANGLEMULTIPLIER*2)*sizeof(uint16_t);
	char name[8] = "RAYTRIG0";

	name[7] = 65+ANGLEMULTIPLIER;
	appvarSlot = ti_Open(name, "r");

	if(appvarSlot == 0){
		return 2;
	}
	if(appvarSize != ti_GetSize(appvarSlot)){
		ti_Close(appvarSlot);
		return 1;
	}
	
	majorTable = ti_GetDataPtr(appvarSlot);
	fishEyeCorrectionTable = majorTable+(360*ANGLEMULTIPLIER);
	tanTable = fishEyeCorrectionTable+(360*ANGLEMULTIPLIER);
	tanReciprocalTable = tanTable+(90*ANGLEMULTIPLIER);
	
	return 0;
}

uint8_t createTables(){//creates trig tables
	int appvarSlot;
	int appvarSize = (360*ANGLEMULTIPLIER*2+90*ANGLEMULTIPLIER*2)*sizeof(uint16_t);
	char name[8] = "RAYTRIG0";

	name[7] = 65+ANGLEMULTIPLIER;
	appvarSlot = ti_Open(name, "w+");
	
	if(appvarSlot == 0){
		return 2;
	}
	if(ti_Resize(appvarSize, appvarSlot) != appvarSize){
		return 1;
	}
	majorTable = ti_GetDataPtr(appvarSlot);
	fishEyeCorrectionTable = majorTable+(360*ANGLEMULTIPLIER);
	tanTable = fishEyeCorrectionTable+(360*ANGLEMULTIPLIER);
	tanReciprocalTable = tanTable+(90*ANGLEMULTIPLIER);
	
	for(int i = 0; i < (360*ANGLEMULTIPLIER);++i){
		int octant = i/(45*ANGLEMULTIPLIER);
		if(octant == 0 || octant == 3 || octant == 4 || octant == 7){
			majorTable[i] = abs((int)round(cos((float)i/ANGLEMULTIPLIER*TODEG)*0xFF));
		}else{
			majorTable[i] = abs((int)round(sin((float)i/ANGLEMULTIPLIER*TODEG)*0xFF));
		}
	}
	for(int i = 0; i < (90*ANGLEMULTIPLIER);++i){
		tanTable[i] = tan((float)i/ANGLEMULTIPLIER*TODEG)*255.0;
		tanReciprocalTable[i] = 0xFFFF/tanTable[i];
	}

	for(int i = 0; i<=360*ANGLEMULTIPLIER/2;++i){
		fishEyeCorrectionTable[i] = (int)round(0x8000/cos((float)(360*ANGLEMULTIPLIER/2-i)/ANGLEMULTIPLIER*TODEG)-0x8000);
		fishEyeCorrectionTable[(360*ANGLEMULTIPLIER)-i] = fishEyeCorrectionTable[i];
	}

	ti_Close(appvarSlot);
	return 0;
}