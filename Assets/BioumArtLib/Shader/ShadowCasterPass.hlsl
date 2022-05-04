#ifndef BIOUM_SHADOW_CASTER_PASS_INCLUDED
#define BIOUM_SHADOW_CASTER_PASS_INCLUDED

#include "../Shader/ShaderLibrary/Common.hlsl"

#if _ALPHATEST_ON
#define SHOULD_SAMPLE_TEXTURE 1
#endif

struct Attributes
{
    half3 positionOS   : POSITION;
    half3 normalOS     : NORMAL;
    half2 texcoord     : TEXCOORD0;
    half4 color     : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    half4 positionCS   : SV_POSITION;
#ifdef SHOULD_SAMPLE_TEXTURE
    float2 uv     : TEXCOORD0;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

half4 BioumClipSpaceShadowCasterPos(half3 positionOS, half3 normalOS, half4 vColor)
{
    half3 positionWS = TransformObjectToWorld(positionOS);
#if _WIND
    float2 direction = _WindParam.xy;
    float scale = _WindParam.z;
    float speed = _WindParam.w;
    float2 wave = PlantsAnimationNoise(positionWS, direction, scale, speed);
    positionWS.xz += wave * vColor.r;
#endif

    if (unity_LightShadowBias.z != 0.0)
    {
        half3 normalWS = TransformObjectToWorldNormal(normalOS);
        half3 lightPosWS = normalize(UnityWorldSpaceLightDir(positionWS.xyz));

        // apply normal offset bias (inset position along the normal)
        // bias needs to be scaled by sine between normal and light direction
        // (http://the-witness.net/news/2013/09/shadow-mapping-summary-part-1/)
        //
        // unity_LightShadowBias.z contains user-specified normal offset amount
        // scaled by world space texel size.

        half shadowCos = dot(normalWS, lightPosWS);
        half shadowSine = sqrt(1 - shadowCos * shadowCos);
        half normalBias = unity_LightShadowBias.z * shadowSine;

        positionWS -= normalWS * normalBias;
    }

    return TransformWorldToHClip(positionWS);
}

Varyings ShadowCasterVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    half4 positionCS = BioumClipSpaceShadowCasterPos(input.positionOS, input.normalOS, input.color);
    output.positionCS = UnityApplyLinearShadowBias(positionCS);

#ifdef SHOULD_SAMPLE_TEXTURE
    output.uv = input.texcoord * _BaseMap_ST.xy + _BaseMap_ST.zw;
#endif
    
    return output;
}

half4 ShadowCasterFrag(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    DitherLOD(unity_LODFade.x, input.positionCS.xy);

	half alpha = 1;
#ifdef SHOULD_SAMPLE_TEXTURE
    alpha = sampleBaseMap(input.uv, false).a;
#endif

// #if _ALPHATEST_ON && !_DITHER_CLIP              // 常规cutout
//     clip(alpha - _Cutoff);
// #elif _DITHER_CLIP && !_DITHER_TRANSPARENT      // cutout并且开启dither
//     float dither = GetDither(input.positionCS.xy);
//     DitherClip(alpha, dither, _Cutoff, _DitherCutoff);
// #elif _DITHER_CLIP && _DITHER_TRANSPARENT       // 半透并且开启dither
//     alpha *= _Transparent;
//     float dither = GetDither(input.positionCS.xy);
//     clip(alpha - dither);
// #endif

	half texAlpha = 1, dither = 1;
#if _ALPHATEST_ON
	texAlpha = alpha;
	texAlpha += -_Cutoff;
#endif
#if _DITHER_FADE
	dither = GetDither(input.positionCS.xy);
	dither += -_DitherCutoff;
#endif
#if _ALPHATEST_ON || _DITHER_FADE
	clip(min(dither, texAlpha));
#endif

    return 0;
}

#endif
