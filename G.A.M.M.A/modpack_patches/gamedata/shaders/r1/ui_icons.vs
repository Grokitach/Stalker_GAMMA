#include "common.h"
#include "skin.h"

struct icon_pixel
{
    float4 position : POSITION;
    float2 tc : TEXCOORD0;
};

icon_pixel _main(v_model I)
{
    icon_pixel O;
    O.position = mul(m_WVP, I.pos);
    O.tc = I.tc.xy;
    return O;
}

// Use full skinning: SKIN_LQ would discard the second bone's influence.
#define SKIN_VF icon_pixel
#include "skin_main.h"
