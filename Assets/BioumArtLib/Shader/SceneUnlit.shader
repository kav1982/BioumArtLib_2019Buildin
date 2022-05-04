Shader "Bioum/Scene/Unlit"
{
    Properties
    {
        [MainColor][HDR]_BaseColor("颜色", Color) = (1,1,1,1)
        [MainTexture]_BaseMap ("贴图", 2D) = "white" {}
        _Cutoff ("透贴强度", range(0,1)) = 0.35
        _DitherCutoff ("Dither", range(0,1)) = 0.5
        _Transparent ("透明度", range(0,1)) = 1

        [Toggle(_WIND)] _WindToggle ("风开关", float) = 0
        _WindScale ("缩放", float) = 0.2
        _WindSpeed ("速度", float) = 0.5
        _WindDirection ("风向", range(0,90)) = 40
        _WindIntensity ("强度", range(0, 1)) = 0.2
        _WindParam ("风参数", vector) = (0.2, 0, 0.2, 0.5)

        [HideInInspector] _BlendMode ("_BlendMode", float) = 0
        [HideInInspector] _CullMode ("_CullMode", float) = 0
        [HideInInspector] _SrcBlend ("_SrcBlend", float) = 1
        [HideInInspector] _DstBlend ("_DstBlend", float) = 0
        [HideInInspector] _ZWrite ("_ZWrite", float) = 1
        [HideInInspector][Toggle] _TransparentZWrite ("_TransparentZWrite", float) = 0
        [HideInInspector] _Cull ("_Cull", float) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        HLSLINCLUDE
            #include "SceneUnlitInput.hlsl"
        ENDHLSL

        Pass
        {
            Name "ForwardBase"
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite] Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma multi_compile_fog
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
            #pragma multi_compile_local _ _DITHER_FADE
            #pragma shader_feature_local _ _WIND
            
            #pragma vertex UnlitVert
            #pragma fragment UnlitFrag

            #include "SceneUnlitPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On ZTest LEqual
            Cull Off ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            //#pragma multi_compile_instancing

            #pragma shader_feature_local _ _ALPHATEST_ON
            #pragma multi_compile_local _ _DITHER_FADE
            #pragma shader_feature_local _ _WIND
            #pragma vertex ShadowCasterVert
            #pragma fragment ShadowCasterFrag

            #include "ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
    CustomEditor "SceneUnlitGUI"
}
