Shader "Bioum/Scene/Grass"
{
    Properties
    {
        [MainColor]_BaseColor("颜色", Color) = (1,1,1,1)
        [HDR]_WaveColor("颜色", Color) = (0.8,1,0.3,1)
        _TopColor("颜色", Color) = (0.8,1,0.3,1)
        [MainTexture]_BaseMap ("贴图", 2D) = "grey" {}

        _Cutoff("透贴强度", Range(0.0, 1.0)) = 0.5

        [Toggle(_WIND)] _WindToggle ("风开关", float) = 0
        _WindScale ("缩放", float) = 0.2
        _WindSpeed ("速度", float) = 0.5
        _WindDirection ("风向", range(0,90)) = 40
        _WindIntensity ("强度", range(0, 1)) = 0.2
        _WindParam ("风参数", vector) = (0.2, 0, 0.2, 0.5)

        [HideInInspector] _BlendMode ("_BlendMode", float) = 0
        [HideInInspector] _CullMode ("_CullMode", float) = 0
        [HideInInspector] _Cull ("_Cull", float) = 2
    }
    SubShader
    {
        HLSLINCLUDE
            #include "SceneGrassInput.hlsl"
        ENDHLSL
        
        Tags{"RenderType" = "Opaque" "IgnoreProjector" = "True"}
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
            #pragma multi_compile_instancing
            #pragma skip_variants LIGHTMAP_ON
            #pragma skip_variants VERTEXLIGHT_ON
            #pragma skip_variants LIGHTMAP_SHADOW_MIXING


            #pragma shader_feature_local _ _WIND
            
            #pragma vertex GrassLitVert
            #pragma fragment GrassLitFrag

            #include "SceneGrassPass.hlsl"
            ENDHLSL
        }     
    }

    
    CustomEditor "SceneGrassGUI"
}
