//#ifndef NGL_HYBRID_MODE
 #define NGL_HYBRID_MODE 0
//#endif
//#ifndef HQ_DENOISER
 #define HQ_DENOISER 0
//#endif

//#if HQ_DENOISER
// #include "NGLighting-Shader - SVGF.fxh"
//#else
 #include "NGLighting-Shader.fxh"
//#endif

technique NGLighting<
	ui_label = "NiceGuy Lighting (GI/Reflection)";
	ui_tooltip = "            NiceGuy Lighting 0.9.2 beta            \n"
				 "                  ||By Ehsan2077||                 \n"
				 "|Use with ReShade_MotionVectors at quarter detail.|\n"
				 "|And    don't   forget    to   read   the   hints.|";
>
{
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = GBuffer1;
		RenderTarget0 = SSSR_NormTex;
		RenderTarget1 = SSSR_RoughTex;
	}
#if SMOOTH_NORMALS > 0
	pass SmoothNormalHpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNH;
		RenderTarget = SSSR_NormTex1;
	}
	pass SmoothNormalVpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNV;
		RenderTarget = SSSR_NormTex;
	}
#endif //SMOOTH_NORMALS
#if __RENDERER__ >= 0xa000 // If DX10 or higher
	pass LowResGBuffer
	{
		VertexShader = PostProcessVS;
		PixelShader = CopyGBufferLowRes;
		RenderTarget0 = SSSR_LowResNormTex;
		RenderTarget1 = SSSR_LowResDepthTex;
	}
#endif //RESOLUTION_SCALE
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = RayMarch;
		RenderTarget0 = SSSR_ReflectionTex;
	}
#if HQ_DENOISER
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = TemporalFilter;
		RenderTarget0 = SSSR_FilterTex0;
		RenderTarget1 = SSSR_Moments_HL0;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = GetVariance;
		RenderTarget0 = SSSR_VarianceTex0;
		RenderTarget1 = SSSR_Moments_HL1;
		RenderTarget2 = SSSR_FilterTex1;
	}
	pass{VertexShader = PostProcessVS;PixelShader = Filter1;RenderTarget0 = SSSR_FilterTex4; RenderTarget1 = SSSR_VarianceTex1;}//specified for temporal accumulation history
	pass{VertexShader = PostProcessVS;PixelShader = Filter2;RenderTarget0 = SSSR_FilterTex0; RenderTarget1 = SSSR_VarianceTex0;}
	pass{VertexShader = PostProcessVS;PixelShader = Filter3;RenderTarget0 = SSSR_FilterTex1; RenderTarget1 = SSSR_VarianceTex1;}
	pass{VertexShader = PostProcessVS;PixelShader = Filter4;RenderTarget0 = SSSR_FilterTex0; RenderTarget1 = SSSR_VarianceTex0;}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = Filter5;
		RenderTarget0 = SSSR_FilterTex1;
		RenderTarget1 = SSSR_PNormalTex;
		RenderTarget2 = SSSR_POGColTex;
		RenderTarget3 = SSSR_FilterTex2;
	}
#else //Default denoiser
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = TemporalFilter;
		RenderTarget0 = SSSR_FilterTex0;
		RenderTarget1 = SSSR_HLTex0;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter0;
		RenderTarget0 = SSSR_FilterTex1;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter1;
		RenderTarget0 = SSSR_FilterTex0;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter2;
		RenderTarget0 = SSSR_FilterTex1;
		RenderTarget1 = SSSR_PNormalTex;
		RenderTarget2 = SSSR_POGColTex;
		RenderTarget3 = SSSR_HLTex1;
		RenderTarget4 = SSSR_FilterTex2;
	}
#endif
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = TemporalStabilizer;
		RenderTarget0 = SSSR_FilterTex3;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = Output;
	}
}
