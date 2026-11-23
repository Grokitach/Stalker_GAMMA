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
    O.position = mul(m_WVP, I.P);
    O.tc = I.tc.xy;
    return O;
}

#ifdef SKIN_NONE
icon_pixel main(v_model v) { return _main(v); }
#endif

#ifdef SKIN_0
icon_pixel main(v_model_skinned_0 v) { return _main(skinning_0(v)); }
#endif

#ifdef SKIN_1
icon_pixel main(v_model_skinned_1 v) { return _main(skinning_1(v)); }
#endif

#ifdef SKIN_2
icon_pixel main(v_model_skinned_2 v) { return _main(skinning_2(v)); }
#endif

#ifdef SKIN_3
icon_pixel main(v_model_skinned_3 v) { return _main(skinning_3(v)); }
#endif

#ifdef SKIN_4
icon_pixel main(v_model_skinned_4 v) { return _main(skinning_4(v)); }
#endif
