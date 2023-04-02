//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// UIDetect 2.1.0 header file by brussell
// License: CC BY 4.0
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*
Description:
UIDetect can be used to automatically toggle shaders depending on the visibility of UI elements.
It's useful for games, where one wants to use effects like DOF, CA or AO, which however shouldn't
be active when certain UI elements are displayed (e.g. inventory, map, dialoque boxes, options
menu etc.). Multiple UIs can be defined, while each is characterized by a number of user-defined 
pixels and their corresponding color values (RGB). Basically, the detection algorithm works this way:

IF ((UI1_Pixel1_Detected = true) AND (UI1_Pixel2_Detected = true) AND ... ) THEN {UI1_Detected = true}
IF ((UI1_Detected = true) OR (UI2_Detected = true) OR ... ) THEN {UI_Deteced = true}
IF (UI_Detected = true) THEN {EFFECTS = false}

Requirements and drawbacks:
-the UI elements that should be detected must be opaque and static, meaning  moving or transparent
 UIs don't work with this shader
-changing graphical settings of the game most likely result in different UI pixel values,
 so set up your game properly before using UIDetect (especially resolution and anti-aliasing)

Getting suitable UI pixel values:
-take a screenshot without any shaders when the UI is visible
-open the screenshot in an image processing tool
-look for a static and opaque area in the UI layer that is usually out of reach for user actions
 like the mouse cursor, tooltips etc. (preferably somewhere in a corner of the screen)
-use a color picker tool and choose two, three or more pixels (the more the better), which are near
 to each other but  differ greatly in color and brightness, and note the pixels coordinates and RGB
 values (thus choose pixels that  do not likely occur in non-UI game situations, so that effects
 couldn't get toggled accidently when there is no UI visible)
-write the pixels coordinates and UI number into the array "UIPixelCoord_UINr"
-write the pixels RGB values into the array "UIPixelRGB"
-set the total number of pixels used via the "PIXELNUMBER" parameter

Show Pixel Mode:
-sometimes it's possible that the screenshots pixel values don't match with the one from the game,
 so if UIDetect can't detect an UI pixel, even if it should, use "UIDetect_ShowPixel" to get the real
 color value of a pixel 
-UIDetect_ShowPixel must be the first and only effect in the load order when used
-set the pixel position via the ReShade-GUI, take a screenshot and use a color picker tool to get the
 correct RGB value

UI RGB mask:
-instead of disabling shaders for the whole screen when UI pixels become visible, it's possible
 to use UI masks to spare only the UI area
-up to 3 UI masks, one for each color channel, can be defined in the image file "UIDetectMaskRGB.png"
-these 3 UI masks correspond with the first 3 UIs defined in "UIPixelCoord_UINr" (all following UIs, 
 starting with 4, don't use masks and disable shaders for the whole screen) 
-enabled via the "UIDetect_USE_MASK" preprocessor definition

Creating an UI RGB mask (with Gimp):
-create a new file with the same dimension as your game resolution
-select Color -> Components -> Decompose to get every color channel as a separate layer
-open a screenshot with the UI visible as a separate file
-draw the UI area, that should be masked, black and everything else white (a quick way is to first
 use Color -> Levels for this)
-copy and paste it onto one of the separated RGB-channel layers and anchor the floating selection
-repeat the procedure with the other color channel layers or fill them black, thus masking the whole
 screen 
-select Color -> Components -> Compose to combine the RGB channel again
-export the image as "UIDetectMaskRGB.png" and move it into the Textures folder

Required shader load order:
-UIDetect                               -> must be first in load order (needs unaltered backbuffer)
... shaders that affect UIs
-UIDetect_Before                        -> place before effects that shouldn't affect UI
... shaders that should not affect UIs
-UIDetect_After                         -> place after effects that shouldn't affect UI
... shaders that affect UIs

*/

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef UIDetect_USE_RGB_MASK
    #define UIDetect_USE_RGB_MASK  0       // [0 or 1] Enable RGB UI mask (description above) 
#endif

#ifndef UIDetect_INVERT
    #define UIDetect_INVERT        0       // [0 or 1] Enable Inverted Mode (only show effects when 
#endif                                     // UI is visible)

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//Game: COD4:MW
//Resolution: 1920x1080

#define PIXELNUMBER 8

static const float3 UIPixelCoord_UINr[PIXELNUMBER]=
{
    float3(495,111,1),  //TAB - Mission details
    float3(496,111,1),
    float3(1589,522,2), //ESC - Menu
    float3(1589,523,2),
    float3(300,54,3),   //Options, Controls
    float3(300,55,3),
    float3(1238,174,4), //Main Menu
    float3(1273,174,4),
};

static const float3 UIPixelRGB[PIXELNUMBER]=
{
    float3(255,204,102),
    float3(255,204,102),
    float3(255,204,102),
    float3(255,204,102),
    float3(255,204,102),
    float3(255,204,102),
    float3(255,255,250),
    float3(255,255,249),
};
