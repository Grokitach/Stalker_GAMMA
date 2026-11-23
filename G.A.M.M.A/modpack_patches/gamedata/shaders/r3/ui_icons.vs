#include "common.h"
#include "skin.h"

v2p_bumped _main( v_model I )
{
	v2p_bumped O;

	//Hpos and texcoord
	O.hpos = mul(m_WVP, I.P);
	O.tcdh = float4(I.tc.xyyy);

	//Hemi
	float3 Nw = mul((float3x3)m_W, I.N.xyz);
	float3 hc_pos = (float3)hemi_cube_pos_faces;
	float3 hc_neg = (float3)hemi_cube_neg_faces;
	float3 hc_mixed = (Nw < 0) ? hc_neg : hc_pos;
	float hemi_val = dot( hc_mixed, abs(Nw) );
	hemi_val = saturate(hemi_val);

	//TBN
	O.M1 = normalize(mul((float3x3)m_WV, I.T.xyz));
	O.M2 = normalize(mul((float3x3)m_WV, I.B.xyz));
	O.M3 = normalize(mul((float3x3)m_WV, I.N.xyz));

	//Position
	float3 Pe = mul(m_WV, I.P);
	O.position = float4(Pe, hemi_val); //Use L_material.x for old behaviour;

	return	O;
}

/////////////////////////////////////////////////////////////////////////
#ifdef 	SKIN_NONE
v2p_bumped	main(v_model v) 		{ return _main(v); 		}
#endif

#ifdef 	SKIN_0
v2p_bumped	main(v_model_skinned_0 v) 	{ return _main(skinning_0(v)); }
#endif

#ifdef	SKIN_1
v2p_bumped	main(v_model_skinned_1 v) 	{ return _main(skinning_1(v)); }
#endif

#ifdef	SKIN_2
v2p_bumped	main(v_model_skinned_2 v) 	{ return _main(skinning_2(v)); }
#endif

#ifdef	SKIN_3
v2p_bumped	main(v_model_skinned_3 v) 	{ return _main(skinning_3(v)); }
#endif

#ifdef	SKIN_4
v2p_bumped	main(v_model_skinned_4 v) 	{ return _main(skinning_4(v)); }
#endif

FXVS;
