<pre>
A Raycasting library built in eZ80 Assembly and C for the TI-84 Plus CE. This is intended to be used in simple first-person games like a 3d maze or a simplified Wolfenstein 3-D. To use this library in a project look over the soon_to_be_linked docs or soon_to_be_linked guide.

Current capabilities include:
  -Casting a scene to the render window given the camera (players) position and direction
  -Using a tilemap for textures
  -Changing the size and position of the render window
  -Setting the FOV
  -Changing the screen between 8, 4, 2, 1 bpp modes (this also sets rendering to full, half, quarter, eighth resolution)
  -A simple method to convert sprites to the appropriate bpp and format
  -Changing the render mode between textured and colored walls as well as a full and third resolution for both
  
Capability limitations (most of these can be added for a speed cost if there is interest):
  -No direct support for half walls or animations (these could likely be faked by casting the scene multiple times with different maps and view positions/settings)
  -No support for arbitrary wall shapes/sizes/angles
  -No support for advanced graphic effects like transparency or reflections
  -Does not include support for object/enemy sprite or manipulation (if added these would likely be their own library) 

Usage limitations:
  -Requires [CE Libraries](https://github.com/CE-Programming/libraries)
  -Library source code must be included requiring projects to be made with C support
  -The first time a program using this library is run there is significant load time while an appvar of data needed for fast calculations is created
   -Contents of the screen cursor image (E30800h) may be overwritten anytime time the library is used (and always will be overwritten when the screen is cast)
   
Planned features/changes:
  -Add useful documentation
  -Remove or shorten appvar creation loading time on the first run
  -Convert to a shared library
  -Single ray casting features (distance to wall, position wall is hit, etc)
</pre>
