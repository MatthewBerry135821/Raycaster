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
/**
 * @brief initial setup of various aspects of the Raycaster. This should be called before anything else
 * 
 * @param mapData pointer to the map data
 * @param mapRowSize the width or the map or the number of columns if the map was viewed as a table
 * @param tilemap 
 * @param mode 
 * @return uint8_t 
 */
uint8_t initializeEngine(uint8_t *mapData, int mapRowSize, uint8_t **tilemap, enum DrawMode mode);

/**
 * @brief Sets aspects of the screen. This needs to be called before castScreen
 * 
 * @param windowX 
 * @param windowY 
 * @param windowWidth 
 * @param windowHeight 
 * @param bpp 
 * @param fov 
 */
void setScreen(int windowX, int windowY, int windowWidth, int windowHeight, uint8_t bpp, int fov);
/**
 * @brief draws the screen based on position and direction
 * 
 * @param playerX 
 * @param playerY 
 * @param playerDirection 
 */
void castScreen(int playerX, int playerY, int playerDirection);
/**
 * @brief casts a single ray and returns the distance it traveled before hitting a wall
 * 
 * @param playerX 
 * @param playerY 
 * @param playerDirection 
 * @return short int 
 */
short int castRay(int playerX, int playerY, int playerDirection);

void changeTilemap(uint8_t **tilemap);
void changeDrawMode(enum DrawMode Mode);
void changeFOV(int fov);

#endif