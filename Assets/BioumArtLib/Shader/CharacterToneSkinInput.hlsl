#ifndef BIOUM_CHARACTER_TONE_SKIN_INPUT_INCLUDE
#define BIOUM_CHARACTER_TONE_SKIN_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"

half4 _BaseMap_ST;
half4 _BaseColor;
half4 _SSSColor;
half4 _EmiColor;
half4 _RimColor;

half4 _SmoothAndCurve;

half _NormalScale;
half _AOStrength;
half _SmoothDiff;

half4 _LightColorControl;
half4 _RimColorFront;
half4 _RimColorBack;
half4 _RimParam;

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

    map.r = lerp(_SmoothAndCurve.z, _SmoothAndCurve.w, map.r);
    map.g = LerpWhiteTo(map.g, _AOStrength);
    map.a = lerp(_SmoothAndCurve.x, _SmoothAndCurve.y, map.a);

    return map;
}

half3 sampleNormalMap(float2 uv)
{
    half4 map = tex2D(_NormalMap, uv);
    return UnpackNormalScale56(map, _NormalScale);
}

half3 GetSSSColor()
{
    return ColorSpaceConvertInput(_SSSColor.rgb);
}

half4 GetRimColor()
{
    return _RimColor;  //alpha = power
}


#endif //BIOUM_CHARACTER_TONE_SKIN_INPUT_INCLUDE