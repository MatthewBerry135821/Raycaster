/**
 * @file raycaster.h
 */

#ifndef RAYCASTER_H
#define RAYCASTER_H
#include <stdint.h>

///How many steps there are between each degree. Lower values will create a smaller appvar while higher values may look smoother. Should typically be left at default to reduce the amount of different appvars needed. If this is changed raycaster.inc also needs to be updated to match
#define ANGLE_MULTIPLIER 10 

///Max FOV that can be set, anything above this will be capped to it. If this is increased castScreen may be unstable and lower cap values are likely better implemented in the calling program 
#define FOV_LIMIT 720 

///If FOV is above this the fisheye effect will not be correctly compensated for and the result may be significantly warped
#define MAX_FOV_FISHEYE_CORRECTION 120 

/// Experimental feature for handling different methods of casting and drawing the screen. Values other than textured may be unstable and usage may change
enum DrawMode{
	textured = 0b11,
	line = 0b01,
};
/**
 * @brief This sets up initial values and loads (or generates) needed data for the raycaster. This should be called before any other raycaster functions.
 * 
 * @param mapData A pointer the the map data where 0 represents no wall and any other 8 bit value corresponds to a 1 indexed sprite in the tilemap (e.g. a value of 1 would be the first sprite) or pallet color if sprites are not being used (e.g. if line drawMode is used)
 * @param mapRowSize The number of elements in each row of the map. This would be the second value in a typical C 2d array.
 * @param tilemap A pointer to a tilemap of square sprites which will be rotated 90 degrees counter-clockwise when drawn compared to the gfx library. This should be null if sprites are not being used.
 * @param mode The drawing mode of the engine textured will use the tilemap to draw textured walls. Values other than textured are experimental and may be changed or removed. Other options currently include 'line' for solid colored walls
 * @return Returns 0 if successful and a different uint8_t value if something failed
 */
uint8_t initializeEngine(uint8_t *mapData, int mapRowSize, uint8_t **tilemap, enum DrawMode mode);

/**
 * @brief This sets the area for the raycaster to draw to and should be called at least once before the screen is cast for the first time and can be called again at anytime to change the screen area.
 * 
 * @param windowX An integer value for the X offset of the render area compared to the LCD. A positive values moves right, negative left. There is no bounds checking and should be done manually by setting windowWidth accordingly. This should not be greater than 320 without good reason.
 * @param windowY An integer value for the Y offset of the render area compared to the LCD. A positive values moves down, negative up. There is no bounds checking and should be done manually by setting windowHeight accordingly. This should not be greater than 240 without good reason.
 * @param windowWidth An integer value for the width of the window. This will automatically be adjusted for different bpp states so 320 will always appear to be the full width of the lcd. This should not be greater than (320 - windowX) without good reason.
 * @param windowHeight 	An integer value for the height of the window. 240 will always appear to be the full height of the lcd. This should not be greater than (240 - windowY) without good reason.
 * @param bpp The bit per pixel mode of the screen (8, 4, 2, 1). This should probably be 8 if the graphx library is used. For values other than 8 walls will be rendered at lower resolution (half-res for 4bpp, quarter-res for 2bpp, ect.)
 * @param fov The field of view in degrees, can be any integer between 0 and FOV_LIMIT (higher values will simply be capped to FOV_LIMIT)
 * @remark There will be little to no checks to ensure the screen has not been set to draw to random/invalid memory. All values are expected to be valid and will likey overwrite memory and crash if not.
 */
void setScreen(int windowX, int windowY, int windowWidth, int windowHeight, uint8_t bpp, int fov);
/**
 * @brief draws the screen based on position and direction
 * 
 * @param playerX The X position to cast the screen from ie where the player/camera is standing. This is in 8.8 fix point format so the bottom 8 bits represents position within a tile and top 8 bits represent the tile within the map
 * @param playerY The Y position to cast the screen from ie where the player/camera is standing. Values should be in the same format as playerX
 * @param playerDirection The direction to cast the screen ie where the player/camera is looking. This should be a value between 0-360*ANGLE_MULTIPLIER
 * @remark The position can be converted from a floating point representation by multiplying by 0x100 or 256 and rounding.
 * @remark The angle of the direction is also a fixed point format but instead of 8.8 it is dependant on the ANGLE_MULTIPLIER macro. This means it can be treated the same as playerX/Y but when converting from float multiply by ANGLE_MULTIPLIER instead of 0x100
 */
void castScreen(uint16_t playerX, uint16_t playerY, uint16_t playerDirection);
/**
 * @brief casts a single ray and returns the distance it traveled before hitting a wall
 * 
 * @param playerX The X position to cast the ray from ie where the player/camera is standing. This is in 8.8 fix point format so the bottom 8 bits represents position within a tile and top 8 bits represent the tile within the map
 * @param playerY The Y position to cast the ray from ie where the player/camera is standing. Values should be in the same format as playerX
 * @param playerDirection The direction to cast the ray ie where the player/camera is looking. This should be a value between 0-360*ANGLE_MULTIPLIER
 * @return short int 
* @remark all parameters are the same as those for castScreen though instead of casting the entire screen it will cast a single ray
 */
short int castRay(uint16_t playerX, uint16_t playerY, uint16_t playerDirection);

/**
 * @brief changes the tilemap being used to texture walls
 * 
 * @param tilemap pointer to the new tilemap in the same format used by initializeEngine
 */
void changeTilemap(uint8_t **tilemap);

/**
 * @brief changes the draw mode of the engine
 * 
 * @param Mode The new draw mode to be used. If change to a mode that uses textures the tilemap must be set (ifnot already set by initializeEngine or changeTilemap) before cast screen is called again if it
 */
void changeDrawMode(enum DrawMode Mode);

/**
 * @brief Changes the FOV for drawing the screen
 * 
 * @param fov The field of view in degrees, can be any integer between 0 and FOV_LIMIT (higher values will simply be capped to FOV_LIMIT)
 */
void changeFOV(int fov);

#endif