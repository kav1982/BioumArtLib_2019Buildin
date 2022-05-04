Shader "Bioum/Scene/Plants"
{
    Properties
    {
        [MainColor]_BaseColor("颜色", Color) = (1,1,1,1)
        _SecondColor("下方颜色", Color) = (0.5,0.5,0.5,1)
        [MainTexture]_BaseMap ("贴图", 2D) = "grey" {}

        _Cutoff("透贴强度", Range(0.0, 1.0)) = 0.5
		_DitherCutoff ("Dither", range(0,1)) = 0.5

        [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" {}
        _NormalScale("法线强度", Range(-2.0, 2.0)) = 1.0
        _NormalWarp("球形法线强度", Range(0, 1)) = 0
        [Toggle] _NormalMapDXGLSwitch ("OpenGL/DX Switch", float) = 0

        _AOStrength("AO范围", float) = 5
        _CenterOffset("AO中心偏移", vector) = (0,0,0,0)
        _InnerColor("内部颜色", Color) = (0.03, 0.25, 0.11, 1)

        [Toggle(_SIMPLE_SSS)] _sssToggle ("SSS开关", float) = 0
        _SSSColor ("SSS颜色", Color) = (0.72, 0.82, 0.21, 1)
        _SSSRange ("SSS范围", range(0, 5)) = 0.5

        [Toggle(_WIND)] _WindToggle ("风开关", float) = 0
        _WindScale ("缩放", float) = 0.2
        _WindSpeed ("速度", float) = 0.5
        _WindDirection ("风向", range(0,90)) = 40
        _WindIntensity ("强度", range(0, 1)) = 0.2
        _WindParam ("风参数", vector) = (0.2, 0, 0.2, 0.5)

        [HideInInspector] _Cull ("_Cull", float) = 2
        [HideInInspector][Toggle] _DoubleSideToggle ("双面开关", float) = 0
        [HideInInspector] _Color("Color", Color) = (1,1,1,1)
        [HideInInspector] _MainTex ("Main Tex", 2D) = "white" {}

		_DitherCutoff ("dither", range(0, 1)) = 0.5
    }
    SubShader
    {
        HLSLINCLUDE
            #include "ScenePlantsInput.hlsl"
        ENDHLSL
        
        LOD 300
        Tags{"RenderType" = "TransparentCutout" "IgnoreProjector" = "True" "Queue"="AlphaTest"}
        Pass
        {
            Name "ForwardBase"
            Tags{"LightMode"="ForwardBase"}
            Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            //#pragma multi_compile_instancing
            #pragma skip_variants LIGHTMAP_ON
            #pragma skip_variants VERTEXLIGHT_ON
            #pragma skip_variants LIGHTMAP_SHADOW_MIXING

            #pragma shader_feature_local _ _WIND
            #pragma shader_feature_local _ _SIMPLE_SSS

            #pragma multi_compile_local _ _DITHER_FADE

            #define _ALPHATEST_ON 1
            
            #pragma vertex PlantsVert
            #pragma fragment PlantsFrag

            #include "ScenePlantsPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On ZTest LEqual
            Cull[_Cull] ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            //#pragma multi_compile_instancing

            #pragma shader_feature_local _ _WIND
			#pragma multi_compile_local _ _DITHER_FADE

            #define _ALPHATEST_ON 1

            #pragma vertex ShadowCasterVert
            #pragma fragment ShadowCasterFrag

            #include "ShadowCasterPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #include "CommonMetaPass.hlsl"
            ENDHLSL
        }
    }

    
    CustomEditor "ScenePlantsGUI"
}
