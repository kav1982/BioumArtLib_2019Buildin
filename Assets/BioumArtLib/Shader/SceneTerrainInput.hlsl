#ifndef BIOUM_TERRAIN_INPUT_INCLUDE
#define BIOUM_TERRAIN_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"

half4 _Color0, _Color1, _Color2, _Color3;
sampler2D _Splat0, _Splat1, _Splat2, _Splat3;
half4 _SplatScale;
sampler2D _ControlTex;

#if _NORMALMAP
sampler2D _NormalMap0, _NormalMap1, _NormalMap2, _NormalMap3;
half4 _NormalScale;
#endif

half4 _Smoothness;

half3 sampleNormalMap(sampler2D tex, half2 uv, half scale)
{
    half4 map = tex2D(tex, uv);
    return UnpackNormalScale(map, scale);
}

#endif //BIOUM_TERRAIN_INPUT_INCLUDE