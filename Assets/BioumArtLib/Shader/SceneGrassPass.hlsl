#ifndef BIOUM_SCENE_GRASS_PASS_INCLUDE
#define BIOUM_SCENE_GRASS_PASS_INCLUDE

#include "../Shader/ShaderLibrary/LightingCommon.hlsl"
#include "../Shader/ShaderLibrary/fog.hlsl"

struct Attributes
{
    float3 positionOS: POSITION;
    half3 normalOS: NORMAL;
    half2 texcoord: TEXCOORD0;
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    half4 uv: TEXCOORD0;
    half4 vertexSHAndFog : TEXCOORD1;
    float3 positionWS: TEXCOORD2;
        
#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    float4 shadowCoord : TEXCOORD3;
#endif

    half4 waveColor : TEXCOORD4;
    half3 tintColor : TEXCOORD5;
    half3 normalWS : TEXCOORD6;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings GrassLitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    output.normalWS = TransformObjectToWorldNormal(half3(0, 1, 0));
    half3 sh = SampleSH(output.normalWS);
    output.vertexSHAndFog.xyz = sh;

    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
#if _WIND
    float2 direction = _WindParam.xy;
    float scale = _WindParam.z;
    float speed = _WindParam.w;
    half2 waveColor = 0;
    float2 wave = PlantsAnimationNoise(output.positionWS, direction, scale, speed, waveColor);
    output.positionWS.xz += wave * input.color.r;
    waveColor.xy = saturate(waveColor.xy);
    output.waveColor.rgb = waveColor.x * waveColor.y * _WaveColor.rgb;
    output.waveColor.a = input.color.r;
#endif

    output.tintColor = lerp(_BaseColor.rgb, _TopColor.rgb, input.color.r);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.uv.xy = input.texcoord;
    
    output.vertexSHAndFog.w = ComputeBuiltInFogFactor(output.positionCS.z);

#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    output.shadowCoord = ComputeShadowCoord(output.positionWS, output.positionCS);
#endif
    
    return output;
}

half4 GrassLitFrag(Varyings input): SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    half4 tex = sampleBaseMap(input.uv.xy);
#if _ALPHATEST_ON
    clip(tex.a - _Cutoff);
#endif
    
    float4 shadowCoord = 0;
#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    shadowCoord = input.shadowCoord;
#endif 
    
    half3 color = input.tintColor * input.vertexSHAndFog.xyz;
    
    Light light = GetLight(input.positionWS, shadowCoord);
    half shadow = light.shadowAttenuation * light.distanceAttenuation;

    color += input.waveColor.rgb * Square(input.waveColor.a) * max(0.2, shadow);
    color += HalfLambert(light.color, light.direction, input.normalWS) * input.tintColor * shadow;

    color = MixBuiltInFog(color, input.vertexSHAndFog.w);
    
    half alpha = tex.a;
    return half4(color, alpha);
}


#endif // BIOUM_SCENE_GRASS_PASS_INCLUDE