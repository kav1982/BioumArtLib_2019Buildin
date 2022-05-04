#ifndef BIOUM_GRASS_INPUT_INCLUDE
#define BIOUM_GRASS_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"
#include "../Shader/ShaderLibrary/Noise.hlsl"


CBUFFER_START(UnityPerMaterial)
half4 _BaseMap_ST;
half4 _BaseColor;
half4 _TopColor;
half4 _WaveColor;
half _Cutoff;
half _DitherCutoff;
half4 _WindParam; //xy:direction z:scale w:speed
CBUFFER_END

UNITY_DECLARE_TEX2D(_BaseMap);

half4 sampleBaseMap(float2 uv, bool needConvert = true)
{
    half4 map = UNITY_SAMPLE_TEX2D(_BaseMap, uv);

    return map;
}

half GetCutoff()
{
    return _Cutoff;
}

#endif //BIOUM_GRASS_INPUT_INCLUDE