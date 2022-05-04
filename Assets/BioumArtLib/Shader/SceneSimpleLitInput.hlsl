#ifndef BIOUM_SIMPLELIT_INPUT_INCLUDE
#define BIOUM_SIMPLELIT_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"
#include "../Shader/ShaderLibrary/Noise.hlsl"


CBUFFER_START(UnityPerMaterial)
half4 _BaseMap_ST;
half4 _BaseColor;
half4 _SSSColor;
half4 _EmiColor;
half4 _RimColor;

half _NormalScale;
half _AOStrength;
half _Transparent;
half _Cutoff;
half _DitherCutoff;

half4 _WindParam; //xy:direction z:scale w:speed
CBUFFER_END

UNITY_DECLARE_TEX2D(_BaseMap); 
UNITY_DECLARE_TEX2D(_NormalMap);
UNITY_DECLARE_TEX2D(_MAESMap);

half4 sampleBaseMap(float2 uv, bool needConvert = true)
{
    half4 map = UNITY_SAMPLE_TEX2D(_BaseMap, uv);
    map.rgb *= _BaseColor.rgb;

    if(needConvert)
        map.rgb = ColorSpaceConvertInput(map.rgb);

    return map;
}

half4 sampleMAESMap(float2 uv)
{
    half4 map = 1;
#if _MAESMAP
    map = UNITY_SAMPLE_TEX2D(_MAESMap, uv);
    map.a = LerpWhiteTo(map.a, _AOStrength);
#endif

    return map;
}

half3 sampleNormalMap(float2 uv)
{
    half4 map = UNITY_SAMPLE_TEX2D(_NormalMap, uv);
    return UnpackNormalScale(map, _NormalScale);
}

half GetCutoff()
{
    return _Cutoff;
}

half4 GetSSSColor()
{
    return ColorSpaceConvertInput(_SSSColor);
}

half4 GetRimColor()
{
    return _RimColor;  //alpha = power
}

half GetAlpha()
{
    return _Transparent;
}

#endif //BIOUM_COMMON_INPUT_INCLUDE