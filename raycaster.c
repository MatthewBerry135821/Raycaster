#include "raycaster.h"

#include <math.h>
#include <fileioc.h>
#include <debug.h>

#define TODEG (0.0174533)

int spriteSize;
int spriteSizeReciprocal;

int spriteBPP;
int castAngleIncrement;
int fovAngleIncrement;
int renderFov;
int screenAddressingWidth;

int mapRowSize;
uint8_t *mapPtr;

uint16_t *fishEyeCorrectionTable;
uint8_t *tanTable;
uint16_t *tanReciprocalTable;
uint8_t *majorTable;
uint16_t heightCorrection;

int drawMode;
uint8_t **spriteTilemap;
int screenHeight;
int screenWidth;
int xOffset;
int yOffset;


uint8_t loadTables();//returns 0 on success
uint8_t createTables();//returns 0 on success
extern void setBPP(int bpp);
void calculateCastScreenValues();

uint8_t initializeEngine(uint8_t *map, int mapSize, uint8_t **tilemap, enum DrawMode mode){//returns 0 on success
	drawMode = mode;
	mapPtr = map;
	mapRowSize = mapSize;
	changeTilemap(tilemap);
	if(loadTables() != 0){
		createTables();
		return loadTables();
	}
	return 0;
}

void setScreen(int windowX, int windowY, int windowWidth, int windowHeight, uint8_t bpp, int fov){//sets the screen offsets and dimensions
	setBPP(bpp);
	changeFOV(fov);
	spriteBPP = bpp;
	screenAddressingWidth = 320/(8/spriteBPP);
	yOffset = windowY*320/(8/spriteBPP);
	screenHeight = windowHeight/2;
	xOffset = windowX;
	screenWidth = windowWidth/(8/spriteBPP);
	screenAddressingWidth = 320/(8/bpp);

	calculateCastScreenValues();
}

void changeTilemap(uint8_t** tilemap){//links a tilemap for the raycaster to use as wall sprites
	spriteTilemap = tilemap;
	spriteSize = **tilemap;
	spriteSizeReciprocal = 256/(spriteSize/2);
}


void changeDrawMode(enum DrawMode mode){
	drawMode = mode;
}
void changeFOV(int fov){
	if(fov > FOV_LIMIT){
		fov = FOV_LIMIT;
	}
	renderFov = fov;
	calculateCastScreenValues();
}
void calculateCastScreenValues(){
	castAngleIncrement = (renderFov*ANGLE_MULTIPLIER*256)/screenWidth;
	if(renderFov > MAX_FOV_FISHEYE_CORRECTION){
		fovAngleIncrement = (MAX_FOV_FISHEYE_CORRECTION*ANGLE_MULTIPLIER*256)/screenWidth;
	}else{
		fovAngleIncrement = castAngleIncrement;
	}
	heightCorrection = 64*0xFF/(renderFov*(320/(8/spriteBPP))/screenWidth);//multiplied to wall height to correct for fov, screen width, and bpp causing shrunk walls
}
uint8_t loadTables(){//loads trig table from an appvar
	int appvarSlot;
	int appvarSize = (120*ANGLE_MULTIPLIER+90*ANGLE_MULTIPLIER)*sizeof(uint16_t)+(360*ANGLE_MULTIPLIER+90*ANGLE_MULTIPLIER)*sizeof(uint8_t);
	char name[8] = "RAYTRIG0";

	name[7] = 65+ANGLE_MULTIPLIER;
	appvarSlot = ti_Open(name, "r");

	if(appvarSlot == 0){
		return 2;
	}
	if(appvarSize != ti_GetSize(appvarSlot)){
		ti_Close(appvarSlot);
		return 1;
	}
	
	majorTable = ti_GetDataPtr(appvarSlot);
	fishEyeCorrectionTable = majorTable+(360*ANGLE_MULTIPLIER)+1;
	tanTable = fishEyeCorrectionTable+(120*ANGLE_MULTIPLIER)+1;
	tanReciprocalTable = tanTable+(90*ANGLE_MULTIPLIER)+1;
	
	return 0;
}

uint8_t createTables(){//creates trig tables
	int appvarSlot;
	int appvarSize = (120*ANGLE_MULTIPLIER+90*ANGLE_MULTIPLIER)*sizeof(uint16_t)+(360*ANGLE_MULTIPLIER+90*ANGLE_MULTIPLIER)*sizeof(uint8_t);
	char name[8] = "RAYTRIG0";

	name[7] = 65+ANGLE_MULTIPLIER;
	appvarSlot = ti_Open(name, "w+");
	
	if(appvarSlot == 0){
		return 2;
	}
	if(ti_Resize(appvarSize, appvarSlot) != appvarSize){
		return 1;
	}
	majorTable = ti_GetDataPtr(appvarSlot);
	fishEyeCorrectionTable = majorTable+(360*ANGLE_MULTIPLIER)+1;
	tanTable = fishEyeCorrectionTable+(120*ANGLE_MULTIPLIER)+1;
	tanReciprocalTable = tanTable+(90*ANGLE_MULTIPLIER)+1;
	
	for(int i = 0; i < (360*ANGLE_MULTIPLIER);++i){
		int octant = i/(45*ANGLE_MULTIPLIER);
		if(octant == 0 || octant == 3 || octant == 4 || octant == 7){
			majorTable[i] = abs((int)round(cos((float)i/ANGLE_MULTIPLIER*TODEG)*0xFF));
		}else{
			majorTable[i] = abs((int)round(sin((float)i/ANGLE_MULTIPLIER*TODEG)*0xFF));
		}
	}
	for(int i = 0; i < (90*ANGLE_MULTIPLIER);++i){
		tanTable[i] = tan((float)i/ANGLE_MULTIPLIER*TODEG)*255.0;
		tanReciprocalTable[i] = 0xFFFF/tanTable[i];
	}
	for(int i = 60*ANGLE_MULTIPLIER; i >= 0;--i){
		fishEyeCorrectionTable[i] = (int)round(0x7FFF/cos((float)(60*ANGLE_MULTIPLIER-i)/ANGLE_MULTIPLIER*TODEG));//cos(0)-cos(60) wont go below 0.50 so multiplying the reciprocal by 2^15 is the highest that wont overflow. it should be 2^16 or 2^8 but spriteSizeReciprocal is made twice as big to make up for it
		fishEyeCorrectionTable[(120*ANGLE_MULTIPLIER)-i] = fishEyeCorrectionTable[i];
	}
	ti_Close(appvarSlot);
	return 0;
}