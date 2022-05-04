#ifndef BIOUM_SCENE_UNLIT_PASS_INCLUDE
#define BIOUM_SCENE_UNLIT_PASS_INCLUDE

#include "../Shader/ShaderLibrary/fog.hlsl"

struct Attributes
{
    half4 positionOS: POSITION;
    half2 texcoord: TEXCOORD0;
    half3 normalOS: NORMAL;
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    half4 positionCS: SV_POSITION;
    half4 uv: TEXCOORD0;
    half4 vertexSHAndFog : TEXCOORD1;   

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings UnlitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
#if _WIND
    float2 direction = _WindParam.xy;
    float scale = _WindParam.z;
    float speed = _WindParam.w;
    float2 wave = PlantsAnimationNoise(positionWS, direction, scale, speed);
    positionWS.xz += wave * input.color.r;
#endif
    output.positionCS = TransformWorldToHClip(positionWS);
    
    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
        
    return output;
}

half4 UnlitFrag(Varyings input): SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    half4 albedo = sampleBaseMap(input.uv.xy);
	
		half texAlpha = 1, dither = 1;
#if _ALPHATEST_ON
	texAlpha = albedo.a;
	texAlpha += -_Cutoff;
#endif
#if _DITHER_FADE
	dither = GetDither(input.positionCS.xy);
	dither += -_DitherCutoff;
#endif
#if _ALPHATEST_ON || _DITHER_FADE
	clip(min(dither, texAlpha));
#endif

    half3 color = albedo.rgb;
    half alpha = GetAlpha() * albedo.a;
#if _ALPHAPREMULTIPLY_ON
    color *= alpha;
#endif

    color = MixBuiltInFog(color, input.vertexSHAndFog.w);
    
    return half4(color, alpha);
}


#endif // BIOUM_SCENE_COMMON_PASS