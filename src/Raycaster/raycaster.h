#ifndef RAYCASTER_H
#define RAYCASTER_H
#include <stdint.h>
#define ANGLE_MULTIPLIER 10 //how many steps there are between each degree. Lower values will create a smaller appvar higher values can look smoother. Should probably be left at 8 but if changed raycaster.inc also needs to be changed
#define FOV_LIMIT 360*2//anything higher would require more angle bounds checking
#define MAX_FOV_FISHEYE_CORRECTION 120//any fov past this in degrees will be significantyl warped
enum DrawMode{//textured(T/F) 1/3res(T/F)
	textured = 0b11,
	line = 0b01,
};

uint8_t initializeEngine(uint8_t *map, int mapRowSize, uint8_t **tilemap, enum DrawMode mode);
void setScreen(int windowX, int windowY, int windowWidth, int windowHeight, uint8_t bpp, int fov);
void castScreen(int playerX, int playerY, int playerDirection);

void changeTilemap(uint8_t **tilemap);
void changeDrawMode(enum DrawMode Mode);
void changeFOV(int fov);

#endif