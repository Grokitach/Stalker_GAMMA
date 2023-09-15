/*=============================================================================

    Copyright (c) Pascal Gilcher. All rights reserved.

 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 
=============================================================================*/

#pragma once 

//HDR input handling, as far as that's possible...

#define BUFFER_COLOR_SPACE_WTF      0
#define BUFFER_COLOR_SPACE_SRGB     1
#define BUFFER_COLOR_SPACE_SCRGB    2
#define BUFFER_COLOR_SPACE_ST2084   3 //PQ
#define BUFFER_COLOR_SPACE_HLG      4 //Hybrid Log-Gamma - who actually uses that?

/*=============================================================================
	Perceptual Quantizer
=============================================================================*/

//IN: non-linear signal value [0, 1]
//OUT: linearized signal Y also in [0, 1] as we're not doing HDR scaling here!
float3 pq_linearize(float3 E)
{
    //using inverse values here for more accurate transform
    const float i_m1 = 6.27739463602;
    const float i_m2 = 0.0126833135157;
    const float c1 = 107.0/128.0;
    const float c2 = 2413.0/128.0;
    const float c3 = 2392.0/128.0;

    E = saturate(E);
    E = pow(E, i_m2);
    return pow(abs(max(0.0, E - c1) * rcp(c2 - c3 * E)), i_m1);
}

//IN: Y [0, 1]
//OUT: nonlinear E [0, 1]
float3 pq_delinearize(float3 Y)
{
    const float m1 = 1305.0/8192.0;
    const float m2 = 2523.0/32.0;
    const float c1 = 107.0/128.0;
    const float c2 = 2413.0/128.0;
    const float c3 = 2392.0/128.0;

    Y = saturate(Y);
    Y = pow(Y, m1);

    float3 E = mad(Y, c2, c1) * rcp(mad(Y, c3, 1));
    return pow(abs(E), m2);    
}







