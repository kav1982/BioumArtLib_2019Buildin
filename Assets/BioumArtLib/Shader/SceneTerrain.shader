Shader "Bioum/Scene/Terrain"
{
	Properties
	{
		_Color0 ("颜色", Color) = (1,1,1,1)
		_Color1 ("颜色", Color) = (1,1,1,1)
		_Color2 ("颜色", Color) = (1,1,1,1)
		_Color3 ("颜色", Color) = (1,1,1,1)

		_Splat0 ("贴图1", 2D) = "white" {}
		_Splat1 ("贴图2", 2D) = "white" {}
		_Splat2 ("贴图3", 2D) = "white" {}
		_Splat3 ("贴图4", 2D) = "white" {}
        _SplatScale0 ("scale0", float) = 5
        _SplatScale1 ("scale1", float) = 5
        _SplatScale2 ("scale2", float) = 5
        _SplatScale3 ("scale3", float) = 5
        _SplatScale ("scale", vector) = (5,5,5,5)

        [Toggle(_NORMALMAP)] _NormalMapToggle("", float) = 0
		_NormalMap0 ("法线贴图", 2D) = "bump" {}
		_NormalMap1 ("法线贴图", 2D) = "bump" {}
		_NormalMap2 ("法线贴图", 2D) = "bump" {}
		_NormalMap3 ("法线贴图", 2D) = "bump" {}
		_NormalScale0 ("法线强度", range(-4, 4)) = 1
		_NormalScale1 ("法线强度", range(-4, 4)) = 1
		_NormalScale2 ("法线强度", range(-4, 4)) = 1
		_NormalScale3 ("法线强度", range(-4, 4)) = 1
		_NormalScale ("法线强度", vector) = (1,1,1,1)

		_Smoothness0 ("smoothness", range(0, 1)) = 0.5
		_Smoothness1 ("smoothness", range(0, 1)) = 0.5
		_Smoothness2 ("smoothness", range(0, 1)) = 0.5
		_Smoothness3 ("smoothness", range(0, 1)) = 0.5
		_Smoothness ("smoothness", vector) = (0.5, 0.5, 0.5, 0.5)

		_ControlTex ("控制贴图", 2D) = "white" {}

		[HideInInspector] _TexCount ("__TexCount", float) = 2.0
		[HideInInspector] _LightingModel ("__LightingModel", float) = 0.0
	}
	SubShader
	{
        HLSLINCLUDE
            #include "SceneTerrainInput.hlsl"
        ENDHLSL

		Tags{ "RenderType"="Opaque" "Queue"="AlphaTest+50"}
		Pass 
		{
			Name "ForwardBase"
			Tags{"LightMode"="ForwardBase"}

			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

			#pragma multi_compile_fog
            #pragma multi_compile_fwdbase

			#pragma shader_feature_local TERRAIN_2TEX TERRAIN_3TEX TERRAIN_4TEX
			#pragma shader_feature_local LIGHTMODEL_LAMBERT LIGHTMODEL_PBR
			#pragma shader_feature_local _ _NORMALMAP

			#define _SPECULAR_ON 1
            #define _ENVIRONMENT_REFLECTION_ON 0

            #pragma vertex TerrainLitVert
            #pragma fragment TerrainLitFrag

            #include "SceneTerrainPass.hlsl"
			ENDHLSL
		}

        Pass 
		{
			Name "ForwardAdd"
			Tags{"LightMode"="ForwardAdd"}
            Blend One One ZWrite Off

			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

			#pragma multi_compile_fog
            #pragma multi_compile_fwdadd

			#pragma shader_feature_local TERRAIN_2TEX TERRAIN_3TEX TERRAIN_4TEX
			#pragma shader_feature_local LIGHTMODEL_LAMBERT LIGHTMODEL_PBR
			#pragma shader_feature_local _ _NORMALMAP

			#define _SPECULAR_ON 1
            #define _ENVIRONMENT_REFLECTION_ON 0
			#define BIOUM_ADDPASS

            #pragma vertex TerrainLitVert
            #pragma fragment TerrainLitFrag

            #include "SceneTerrainPass.hlsl"
			ENDHLSL
		}

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On ZTest LEqual
            Cull Back ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma vertex ShadowCasterVert
            #pragma fragment ShadowCasterFrag

            #include "ShadowCasterPass.hlsl"
            ENDHLSL
        }
	}
	CustomEditor "SceneTerrainGUI"
}
