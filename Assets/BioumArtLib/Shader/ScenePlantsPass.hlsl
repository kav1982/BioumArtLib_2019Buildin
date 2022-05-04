#ifndef BIOUM_SCENE_PLANTS_PASS_INCLUDE
#define BIOUM_SCENE_PLANTS_PASS_INCLUDE

#include "../Shader/ShaderLibrary/LightingCommon.hlsl"
#include "../Shader/ShaderLibrary/Fog.hlsl"

struct Attributes
{
    float3 positionOS: POSITION;
    half3 normalOS: NORMAL;
    half2 texcoord: TEXCOORD0;
    half2 lightmapUV: TEXCOORD1;
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    half4 uv: TEXCOORD0;
    DECLARE_GI_DATA(lightmapUV, vertexSH, 1);
    float4 positionWSAndFog: TEXCOORD2;
    
    half3 normalWS: TEXCOORD3;
    half3 viewDirWS: TEXCOORD4;

#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    float4 shadowCoord : TEXCOORD5;
#endif

    half4 tintColor : TEXCOORD6;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings PlantsVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    half dist = distance(_CenterOffset.xyz, input.positionOS.xyz);
    half radialAO = saturate(dist / _AOStrength);
    radialAO = Pow4(radialAO);

    output.tintColor.rgb = lerp(_InnerColor.rgb, _BaseColor, radialAO);
    output.tintColor.a = radialAO;

    output.positionWSAndFog.xyz = TransformObjectToWorld(input.positionOS.xyz);
#if _WIND
    float2 direction = _WindParam.xy;
    float scale = _WindParam.z;
    float speed = _WindParam.w;
    float2 wave = PlantsAnimationNoise(output.positionWSAndFog.xyz, direction, scale, speed);
    output.positionWSAndFog.xyz.xz += wave * input.color.r * radialAO;
#endif
    output.positionCS = TransformWorldToHClip(output.positionWSAndFog.xyz);
    
    half3 normalOS = lerp(input.normalOS, normalize(input.positionOS.xyz - _CenterOffset.xyz), _NormalWarp);
    output.normalWS = TransformObjectToWorldNormal(normalOS);
    output.viewDirWS = normalize(_WorldSpaceCameraPos.xyz - output.positionWSAndFog.xyz);

    half NdotU = output.normalWS.y * 0.5 + 0.5;
    output.tintColor.rgb = lerp(_SecondColor.rgb, output.tintColor, NdotU);

    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
    
    OUTPUT_GI_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_GI_SH(output.normalWS.xyz, output.vertexSH);
#ifndef LIGHTMAP_ON
    output.vertexSH = lerp(_InnerColor.rgb, output.vertexSH, radialAO);
#endif
    
    output.positionWSAndFog.w = ComputeBuiltInFogFactor(output.positionCS.z);

#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    output.shadowCoord = ComputeShadowCoord(output.positionWSAndFog.xyz, output.positionCS);
#endif

    return output;
}

half4 PlantsFrag(Varyings input): SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    Surface surface = (Surface)0;
    surface.color = sampleBaseMap(input.uv.xy);
    surface.color.rgb *= input.tintColor.rgb;

	half texAlpha = 1, dither = 1;
#if _ALPHATEST_ON
	texAlpha = surface.color.a;
	texAlpha += -_Cutoff;
#endif
#if _DITHER_FADE
	dither = GetDither(input.positionCS.xy);
	dither += -_DitherCutoff;
#endif
#if _ALPHATEST_ON || _DITHER_FADE
	clip(min(dither, texAlpha));
#endif

    surface.normal = normalize(input.normalWS);
    surface.viewDirection = input.viewDirWS;
    surface.occlusion = 1;
    surface.position = input.positionWSAndFog.xyz;
    surface.SSSColor = _SSSColor * input.tintColor.a;

    float4 shadowCoord = 0;
#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    shadowCoord = input.shadowCoord;
#endif
    
    GI gi = GET_SIMPLE_GI(input.lightmapUV, input.vertexSH, surface);
    
    half3 color = LightingLambert(surface, shadowCoord, gi);

    color = MixBuiltInFog(color, input.positionWSAndFog.w);
    
    return half4(color, surface.color.a);
}


#endif // BIOUM_SCENE_PLANTS_PASS_INCLUDE