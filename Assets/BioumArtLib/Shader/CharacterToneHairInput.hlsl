#ifndef BIOUM_COMMON_INPUT_INCLUDE
#define BIOUM_COMMON_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"

half4 _BaseMap_ST;
half4 _BaseColor;
half4 _SSSColor;
half4 _RimColor;
half4 _SubSpecColor;

half _NormalScale;
half _Smoothness;
half _Metallic;
half _AOStrength;

half _FresnelStrength;
half _Cutoff;
half _SpecIntensity;

half _SubSpecIntensity;
half _Shift;
half _SubShift;
half _SubSmoothness;

half4 _LightColorControl;
half4 _RimColorFront;
half4 _RimColorBack;
half4 _RimParam;
half _SmoothDiff;

sampler2D _BaseMap;
sampler2D _MAESMap;
sampler2D _NormalMap;

half2 GetBaseUV(half2 uv)
{
    return uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
}

half4 sampleBaseMap(float2 uv, bool needConvert = true)
{
    half4 map = tex2D(_BaseMap, uv);
    map.rgb *= _BaseColor.rgb;

    if(needConvert)
        map.rgb = ColorSpaceConvertInput(map.rgb);

    return map;
}

half4 sampleMAESMap(float2 uv)
{
    half4 map = tex2D(_MAESMap, uv);
    half ao = LerpWhiteTo(map.r, _AOStrength);
    half2 shift = 0;
    shift.x = _Shift;
#if _DOUBLE_SPECULAR
    shift.y = _SubShift;
#endif
    shift *= (map.a - 0.5);
    return half4(shift, 1, ao);
}

half3 sampleNormalMap(float2 uv)
{
    half4 map = tex2D(_NormalMap, uv);
    return UnpackNormalScale56(map, _NormalScale);
}

half GetFresnel()
{
    return _FresnelStrength;
}

half GetCutoff()
{
    return _Cutoff;
}

half3 GetSSSColor()
{
    return ColorSpaceConvertInput(_SSSColor.rgb);
}

half4 GetRimColor()
{
    return _RimColor;  //alpha = power
}

half2 GetSmoothness()
{
    half2 smooth = half2(_Smoothness, 0);
#if _DOUBLE_SPECULAR
    smooth.y = _SubSmoothness;
#endif
    return smooth;
}

half2 GetSpecIntensity()
{
    half2 intensity = 0;
    intensity.x = _SpecIntensity;
#if _DOUBLE_SPECULAR
    intensity.y = _SubSpecIntensity;
#endif
    return intensity;
}

#endif //BIOUM_COMMON_INPUT_INCLUDE