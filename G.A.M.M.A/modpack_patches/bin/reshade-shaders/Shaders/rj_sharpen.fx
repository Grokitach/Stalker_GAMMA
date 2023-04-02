/*------------------.
| :: Description :: |
'-------------------/

	rj_sharpen.fx

	Author: Robert Jessop	
	License: MIT

	About:
	
	Standalone version of Sharpen algorithm from Glamayre.
	
	* Fast (uses just 5 bilinear samples to get 9 pixels)
	* Autodetected HDR Support (Requires reshade 5.1)
	* Better shapes and than the textbook algorithm (it sharpens away from the outliers, and little towards the median of the 4 surrounding pixels.)
	* Maintains local brightness by operating in linear color, and limiting sharpness near black or white, and sharpening the area around isolated points.
	    
	Bugs: 
	* In Reshade 5.1.0 it won't detect if the game is switched between HDR and SDR while running. This bug is fixed in the next version of reshade after 5.1.0.
	
	History:
	(*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
	
	Version 1.0 - this.
    
*/


/*---------------.
| :: Includes :: |
'---------------*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

namespace rj_sharpen {

//Correct color space conversions (especially PQ) can be slow. A fast approximation is okay because we apply the conversion one way, apply our effects, then apply the opposite conversion - so inaccuracies in fast mode mostly cancel out. Most effects don't need perfect linear color, just something pretty close. Set to false for highest accuracy.
	
#ifndef FAST_COLOR_SPACE_CONVERSION
	#define FAST_COLOR_SPACE_CONVERSION true
#endif

//Based on ITU specification BT.2408 our default is 203. This should match what your game is configure to use.
#ifndef HDR_WHITELEVEL
	#define HDR_WHITELEVEL 203
#endif


uniform float sharp_strength < __UNIFORM_SLIDER_FLOAT1
	ui_category = "rj_sharpen";
	ui_min = 0; ui_max = 2; ui_step = .05;	
	ui_label = "Sharpen strength";
> = 0.75;


uniform int sharp_size < 
    ui_category = "Advanced Tuning and Configuration";
	ui_type = "combo";
    ui_label = "Kernel size";
	ui_items = "3x3\0"
	           "5x5\0";
	ui_tooltip = "Selecting 5x5 makes the effect bigger but may be less accurate for fine details. \n\n5x5 mode only actually samples 17 of the 25 pixels. 5x5 is just as fast as 3x3, but might be lower quality than competing algorithms with 5x5 kernels";
> = 0;

	
// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}


///////////////////////////////////////////////////////////////
// Color space conversions
//////////////////////////////////////////////////////////////

float3 sRGBtoLinearAccurate(float3 r) {
	return (r<=.04045) ? (r/12.92) : pow(abs(r+.055)/1.055, 2.4);	
}

float3 sRGBtoLinearFastApproximation(float3 r) {
	//pow is slow, use square (gamma 2.0), but with sRGB toe.
	return max(r/12.92, r*r);
}

float3 sRGBtoLinear(float3 r) {
#if BUFFER_COLOR_BIT_DEPTH > 8 
	if(FAST_COLOR_SPACE_CONVERSION) r = sRGBtoLinearFastApproximation(r);
	else r = sRGBtoLinearAccurate(r);
#endif
	return r;
}

float3 linearToSRGBAccurate(float3 r) {
	return (r<=.0031308) ? (r*12.92) : (1.055*pow(abs(r), 1.0/2.4) - .055);	
}

float3 linearToSRGBFastApproximation(float3 r) {
	//pow is slow, use square (gamma 2.0), but with sRGB toe.
	return min(r*12.92, sqrt(r));
}


float3 linearToSRGB(float3 r) {
#if BUFFER_COLOR_BIT_DEPTH > 8 
	if(FAST_COLOR_SPACE_CONVERSION) r = linearToSRGBFastApproximation(r);
	else r = linearToSRGBAccurate(r);
#endif
	//If we used the 8-bit hardware conversion do nothing - we've already done it.
	return r;
}


float3 PQtoLinearAccurate(float3 r) {
		//HDR10 we need to convert between PQ and linear. https://en.wikipedia.org/wiki/Perceptual_quantizer
		const float m1 = 1305.0/8192.0;
		const float m2 = 2523.0/32.0;
		const float c1 = 107.0/128.0;
		const float c2 = 2413.0/128.0;
		const float c3 = 2392.0/128.0;
		//Unneccessary max commands are to prevent compiler warnings, which might scare users.
		float3 powr = pow(max(r,0),1.0/m2);
		r = pow(max( max(powr-c1, 0) / ( c2 - c3*powr ), 0) , 1.0/m1);		
				
		return r * 10000.0/HDR_WHITELEVEL;	//PQ output is 0-10,000 nits, but we want to rescale to 80 nits = 1 to match sRGB and scRGB range.
}

float3 PQtoLinearFastApproximation(float3 r) {
		//Approx PQ. pow is slow, Use square near zero, then x^4 for mid, x^8 for high
		//I invented this - constants chosen by eye by comparing graphs of the curves. might be possible to optimise further to minimize % error.
		float3 square = r*r;
		float3 quad = square*square;
		float3 oct = quad*quad;
		r= max(max(square/340.0, quad/6.0), oct);
		
		return r * 10000.0/HDR_WHITELEVEL;	//PQ output is 0-10,000 nits, but we want to rescale to 80 nits = 1 to match sRGB and scRGB range.
}

float3 PQtoLinear(float3 r) {
	if(FAST_COLOR_SPACE_CONVERSION) r = PQtoLinearFastApproximation(r);
	else r = PQtoLinearAccurate(r);
	return r;
}

float3 linearToPQAccurate(float3 r) {
		//HDR10 we need to convert between PQ and linear. https://en.wikipedia.org/wiki/Perceptual_quantizer
		const float m1 = 1305.0/8192.0;
		const float m2 = 2523.0/32.0;
		const float c1 = 107.0/128.0;
		const float c2 = 2413.0/128.0;
		const float c3 = 2392.0/128.0;	
		
		//PQ output is 0-10,000 nits, but we want to rescale to 80 nits = 1 to match sRGB and scRGB range.
		r = r*(HDR_WHITELEVEL/10000.0); 
		
		//Unneccessary max commands are to prevent compiler warnings, which might scare users.		
		float3 powr = pow(max(r,0),m1);
		r = pow(max( ( c1 + c2*powr ) / ( 1 + c3*powr ), 0 ), m2);	
		return r;	
}

float3 linearToPQFastApproximation(float3 r) {
		//Approx PQ. pow is slow, sqrt faster, Use square near zero, then x^4 for mid, x^8 for high 
		//I invented this - constants chosen by eye by comparing graphs of the curves. might be possible to optimise further to minimize % error.
		
		//PQ output is 0-10,000 nits, but we want to rescale to 80 nits = 1 to match sRGB and scRGB range.
		r = r*(HDR_WHITELEVEL/10000.0); 
		
		float3 squareroot = sqrt(r);
		float3 quadroot = sqrt(squareroot);
		float3 octroot = sqrt(quadroot);
		r = min(octroot, min(sqrt(sqrt(6.0))*quadroot, sqrt(340.0)*squareroot ) );
		return r;
}

float3 linearToPQ(float3 r) {
	if(FAST_COLOR_SPACE_CONVERSION) r = linearToPQFastApproximation(r);
	else r = linearToPQAccurate(r);
	return r;
}

//Hybrid Log Gamma. From ITU REC BT.2100
// Untested: I think it's just used for video - I don't think any games use it?
//Simplified - assuming 1000 nit peak display luminance and no black level lift.
float3 linearToHLG(float3 r) {
	r = r*HDR_WHITELEVEL/1000;
	float a = 0.17883277;
	float b = 0.28466892; // 1-4a
	float c = 0.55991073; // .5-a*ln(4a)
	float3 s=sqrt(3*r);
	return (s<.5) ? s : ( log(12*r - b)*a+c);	
}

float3 HLGtoLinear(float3 r) {
	float a = 0.17883277;
	float b = 0.28466892; // 1-4a
	float c = 0.55991073; // .5-a*ln(4a)
	r = (r<.5) ? r*r/3.0 : ( ( exp( (r - c)/a) + b) /12.0);
	return r * 1000/HDR_WHITELEVEL;
	
}

//Color space conversion. 
float3 toLinearColorspace(float3 r) {
	if(BUFFER_COLOR_SPACE == 2) r = r*(80.0/HDR_WHITELEVEL);		
	else if(BUFFER_COLOR_SPACE == 3) r = PQtoLinear(r);
	else if(BUFFER_COLOR_SPACE == 4) r = HLGtoLinear(r);
	else r= sRGBtoLinear(r);
	return r;
}

float3 toOutputColorspace(float3 r) {
	if(BUFFER_COLOR_SPACE == 2) r=r*(HDR_WHITELEVEL/80.0); //scRGB is already linear
	else if(BUFFER_COLOR_SPACE == 3) r = linearToPQ(r);
	else if(BUFFER_COLOR_SPACE == 4) r = linearToHLG(r);
	else r= linearToSRGB(r);
	
	return r;
}


///////////////////////////////////////////////////////////////
// END OF Color space conversions
///////////////////////////////////////////////////////////////


sampler2D samplerColor
{
	// The texture to be used for sampling.
	Texture = ReShade::BackBufferTex;
#if BUFFER_COLOR_BIT_DEPTH > 8 || BUFFER_COLOR_SPACE > 1
	SRGBTexture = false;
#else
	SRGBTexture = true;
#endif
};


float4 getBackBufferLinear(float2 texcoord) {	 	

	float4 c = tex2D( samplerColor, texcoord);	
	c.rgb = toLinearColorspace(c.rgb);
	return c;
}



float3 rj_sharpen_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	//centre (original pixel)
	float3 c = getBackBufferLinear(texcoord).rgb;	
			
		//Average of the four nearest pixels to each diagonal.
		float3 ne = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*float2(.5+sharp_size,.5+sharp_size)).rgb;
		float3 sw = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*float2(-.5-sharp_size,-.5-sharp_size)).rgb;
		float3 se = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*float2(.5+sharp_size,-.5-sharp_size)).rgb;
		float3 nw = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*float2(-.5-sharp_size,.5+sharp_size)).rgb;
		
		float3 area = ne+sw+se+nw;
		
		// multiplier to convert rgb to perceived brightness	
		static const float3 luma = float3(0.2126, 0.7152, 0.0722);
		
		//sharpen... 
		//This is sharp gives slightly more natural looking shapes - the min+max trick effectively means the final output is weighted a little towards the median of the 4 surrounding values.
		float3 sharp_diff = 2*c+area - 3*(max(max(ne,nw),max(se,sw)) + min(min(ne,nw),min(se,sw)));	
		sharp_diff = dot(luma,sharp_diff);
						
		area = .25*area;
		
		//avoid sharpennng so far the value clips at 0 or 1
		float3 max_sharp=min(area,c);			
						
		if(BUFFER_COLOR_BIT_DEPTH == 8 || BUFFER_COLOR_SPACE == 1) {
			//Only if not HDR then also limit sharpness near c==1.
			max_sharp = min(max_sharp, 1-max(area,c));					
		} 
			
		//finally limit total sharpness to .25 - this helps prevent oversharpening in mid-range and HDR modes
		max_sharp = min(max_sharp, .25);
			
		//This is a bit like reinhard tonemapping applied to sharpness - smoother than clamping. steepness of curve chosen via our sharp_strength 
		sharp_diff = sharp_diff / (rcp(sharp_strength)+abs(sharp_diff)/(max_sharp+0.00001));
			
		//apply sharpen
		c = c+sharp_diff ;	
	
	c = toOutputColorspace(c);
  
	return c;
}


technique rj_sharpen 
{	
	pass rj_sharpen
	{
		VertexShader = PostProcessVS;
		PixelShader = rj_sharpen_PS;
				
		// SDR or HDR mode?
#if BUFFER_COLOR_BIT_DEPTH > 8 || BUFFER_COLOR_SPACE > 1
			SRGBWriteEnable = false;
#else
			SRGBWriteEnable = true;
#endif
	}		
	
}




//END OF NAMESPACE
}
