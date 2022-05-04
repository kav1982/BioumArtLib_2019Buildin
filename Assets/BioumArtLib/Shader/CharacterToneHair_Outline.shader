Shader "Hidden/Bioum/Character/ToneHair_Outline"
{
    Properties
    {
        _BaseColor("颜色", Color) = (1,1,1,1)
        _BaseMap ("贴图", 2D) = "grey" {}
        [NoScaleOffset]_MAESMap ("(R)AO (A)偏移", 2D) = "white" {}

        [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" {}
        _NormalScale("法线强度", Range(-2.0, 2.0)) = 1.0

        _Smoothness("光滑度", Range(0.0, 1.0)) = 0.9
        _Metallic("金属度调整", Range(0.0, 1.0)) = 0.0
        _AOStrength("AO强度", Range(0.0, 1.0)) = 0.0
        _FresnelStrength("菲涅尔强度", Range(0.0, 1.0)) = 1.0
        _Cutoff("cutoff", Range(0.0, 1.0)) = 0.5

        [Toggle(_SSS)] _sssToggle ("SSS开关", float) = 0
        _SSSColor ("SSS颜色", Color) = (0.7, 0.07, 0.01, 1)

        [Toggle(_RIM)] _RimToggle ("RIM开关", float) = 0
        [HDR]_RimColorFront ("边缘光亮面颜色", Color) = (1,1,1,1)
        _RimColorBack ("边缘光暗面颜色", Color) = (0.5, 0.5, 0.5,1)
        _RimSmooth ("边缘光硬度", range(0.001, 0.449)) = 0.1
        _RimPower ("边缘光范围", range(1, 10)) = 5
        _RimOffsetX ("边缘光亮部偏移", range(0, 1)) = 0.4
        _RimOffsetY ("边缘光暗部偏移", range(0, 1)) = 0.4
        _RimParam ("边缘光参数", vector) = (0.4, 0.4, 0.1, 5)

        _LightIntensity ("灯光强度", range(0, 4)) = 1
        _LightColorControl ("暗部颜色", color) = (0.5, 0.5, 0.5, 1)
        _SmoothDiff ("明暗交界线硬度", range(0.001, 1)) = 0.5

        [Toggle]_ToneMapping("Tone Mapping", float) = 1.0
        [Toggle(_DOUBLE_SPECULAR)] _DoubleSpecular("Double Specular", float) = 0
        [Toggle(_SWITCH_TANGENT)] _SwitchTangent("switch Tangent", float) = 1

        _SpecIntensity("_Intensity", range(0,1)) = 0.5
        _Shift("_Shift", range(-1,1)) = 0
        _SubSmoothness("_SubSmoothness", range(0,1)) = 0.5
        _SubSpecIntensity("_SubIntensity", range(0,1)) = 0.3
        _SubShift("_SubShift", range(-1,1)) = 0
        _SubSpecColor("高光颜色", Color) = (1,1,1,1)

        _CharacterEnvironmentCube ("cube", Cube) = "grey" {}
        [HDR]_CharacterEnvironmentColor ("环境光", color) = (0.5, 0.5, 0.5, 1)
        _CharacterEnvironmentRotation ("旋转", range(0,360)) = 0
        _CharacterEnvironmentExposure ("曝光", range(0, 8)) = 1
        _CharacterEnvironmentParam ("环境光设置", vector) = (0, 1, 6, 0)

        [PowerSlider(4)]_OutlineScale ("描边粗细", range(0.001, 0.5)) = 0.002
        _OutlineColor("描边颜色", Color) = (0.4,0.4,0.4,1)
        [Toggle] _OutlineToggle ("描边开关", float) = 0

        [HideInInspector] _BlendMode ("_BlendMode", float) = 0
        [HideInInspector] _CullMode ("_CullMode", float) = 0
        [HideInInspector] _Cull ("_Cull", float) = 2
    }
    SubShader
    {
        HLSLINCLUDE
            #include "CharacterToneHairInput.hlsl"
        ENDHLSL
        
        Tags{"RenderType" = "Opaque" "IgnoreProjector" = "True"}
        
        UsePass "Bioum/Character/ToneHair/FORWARDBASE"
        UsePass "Bioum/Character/ToneHair/FORWARDADD"
        UsePass "Bioum/Character/ToneHair/SHADOWCASTER"

        Pass
        {
            Name "OutLine"
            ZWrite On Cull Front

            HLSLPROGRAM
            #pragma target 3.5

            #pragma shader_feature_local _ _ALPHATEST_ON

            #pragma vertex ForwardBaseVert
            #pragma fragment ForwardBaseFrag

            #include "OutlinePass.hlsl"
            ENDHLSL
        }
    }

    CustomEditor "CharacterToneHairGUI"
}
