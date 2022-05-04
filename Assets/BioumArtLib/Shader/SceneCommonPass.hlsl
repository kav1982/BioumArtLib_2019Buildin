#ifndef BIOUM_SCENE_COMMON_PASS_INCLUDE
#define BIOUM_SCENE_COMMON_PASS_INCLUDE

#include "../Shader/ShaderLibrary/LightingCommon.hlsl"
#include "../Shader/ShaderLibrary/fog.hlsl"

struct Attributes
{
    float3 positionOS: POSITION;
    half3 normalOS: NORMAL;
    half4 tangentOS: TANGENT;
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
    
#if _NORMALMAP
    half4 tangentWS: TEXCOORD4;    // xyz: tangent, w: viewDir.x
    half4 bitangentWS: TEXCOORD5;    // xyz: binormal, w: viewDir.y
    half4 normalWS: TEXCOORD3;    // xyz: normal, w: viewDir.z
#else
    half3 normalWS: TEXCOORD3;
    half3 viewDirWS: TEXCOORD4;
#endif
    
    half4 VertexLightAndFog: TEXCOORD6; // w: fogFactor, xyz: vertex light

#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    float4 shadowCoord : TEXCOORD7;
#endif
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings CommonLitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    output.positionWSAndFog.xyz = TransformObjectToWorld(input.positionOS.xyz);
#if _WIND
    float2 direction = _WindParam.xy;
    float scale = _WindParam.z;
    float speed = _WindParam.w;
    float2 wave = PlantsAnimationNoise(output.positionWSAndFog.xyz, direction, scale, speed);
    output.positionWSAndFog.xyz.xz += wave * input.color.r;
#endif
    output.positionCS = TransformWorldToHClip(output.positionWSAndFog.xyz);
    
    half3 viewDirWS = _WorldSpaceCameraPos - output.positionWSAndFog.xyz;
#if _NORMALMAP
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.z);
#else
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.viewDirWS = viewDirWS;
#endif
    
    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
    
    OUTPUT_GI_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_GI_SH(output.normalWS.xyz, output.vertexSH);
    
    output.positionWSAndFog.w = ComputeBuiltInFogFactor(output.positionCS.z);

#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    output.shadowCoord = ComputeShadowCoord(output.positionWSAndFog.xyz, output.positionCS);
#endif
    
    return output;
}

half4 CommonLitFrag(Varyings input): SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    Surface surface = (Surface)0;
    surface.color = sampleBaseMap(input.uv.xy);
	
	AlphaTestAndFade(input.positionCS.xy, surface.color.a, _Cutoff, _DitherCutoff);
    
#if _NORMALMAP
    half3 normalTS = sampleNormalMap(input.uv.xy);
    half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    half3 normalWS = mul(normalTS, TBN);
    half3 viewDirWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
#else
    half3 normalWS = input.normalWS;
    half3 viewDirWS = input.viewDirWS;
#endif
    surface.normal = SafeNormalize(normalWS);
    surface.viewDirection = SafeNormalize(viewDirWS);
    
    half4 maes = sampleMAESMap(input.uv.xy);
    surface.metallic = maes.r;
    surface.occlusion = maes.g;
    surface.smoothness = maes.a;
    surface.specularTint = _SpecularTint;
    surface.position = input.positionWSAndFog.xyz;
    surface.fresnelStrength = GetFresnel();
    surface.SSSColor = GetSSSColor();

    float4 shadowCoord = 0;
#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    shadowCoord = input.shadowCoord;
#endif 
    
    half alpha = GetAlpha() * surface.color.a;
    BRDF brdf = GetBRDF(surface, alpha);
    GI gi = GET_GI(input.lightmapUV, input.vertexSH, surface, brdf);
    
    half3 color = LightingPBR(brdf, surface, shadowCoord, gi);
    color += maes.b * _EmiColor.rgb;

    color = MixBuiltInFog(color, input.positionWSAndFog.w);

            
    return half4(color, alpha);
}


#endif // BIOUM_SCENE_COMMON_PASS