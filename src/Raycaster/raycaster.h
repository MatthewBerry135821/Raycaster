#ifndef RAYCASTER_H
#define RAYCASTER_H
#define ANGLEMULTIPLIER 8//how many steps there are between each degree. Lower values will create a smaller appvar higher values can look smoother. Should probably be left at 8 but if changed raycaster.inc also needs to be changed

extern void linkTilemap(uint8_t**, int numberOfSprites, uint8_t size, uint8_t bpp);
extern void setBPP(int bpp);
extern void setScreen(int x, int y, int width, int height, int fov);
extern uint8_t initializeEngine(uint8_t *map, int witdth, int height, int textured);
extern void castScreen(int, int, int);

extern uint8_t **spriteTilemap;
extern int renderFovAngle;
extern int renderFov;
extern int spriteBPP;
extern int numberOfSprites;
extern int spriteSize;
enum DrawMode{//textured(T/F) 1/3res(T/F)
	fullResTextured = 0b11,
	fullResLine = 0b01,
	thirdResTextured = 0b10,
	thirdResLine = 0b00,
};
#endif