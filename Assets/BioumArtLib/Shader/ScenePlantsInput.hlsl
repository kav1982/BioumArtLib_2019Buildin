#ifndef BIOUM_SIMPLELIT_INPUT_INCLUDE
#define BIOUM_SIMPLELIT_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"
#include "../Shader/ShaderLibrary/Noise.hlsl"


CBUFFER_START(UnityPerMaterial)
half4 _BaseMap_ST;
half4 _BaseColor;
half4 _SSSColor;
half4 _SecondColor;
half4 _EmiColor;

half _NormalWarp;
half _AOStrength;
half _Cutoff;

//bool _NormalMapDXGLSwitch;
half4 _WindParam; //xy:direction z:scale w:speed
half4 _CenterOffset;
half4 _InnerColor;
half _DitherCutoff;
CBUFFER_END

UNITY_DECLARE_TEX2D(_BaseMap);

half4 sampleBaseMap(float2 uv, bool needConvert = true)
{
    half4 map = UNITY_SAMPLE_TEX2D(_BaseMap, uv);

    if(needConvert)
        map.rgb = ColorSpaceConvertInput(map.rgb);

    return map;
}

half4 sampleMAESMap(half2 uv) // meta pass 使用
{
    return half4(0, 1, 0, 0);
}

half4 GetSSSColor()
{
    return ColorSpaceConvertInput(_SSSColor);
}

#endif //BIOUM_COMMON_INPUT_INCLUDE