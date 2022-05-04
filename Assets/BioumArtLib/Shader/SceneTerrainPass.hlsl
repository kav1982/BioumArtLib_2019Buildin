#ifndef BIOUM_TERRAIN_PASS_INCLUDE
#define BIOUM_TERRAIN_PASS_INCLUDE

#include "../Shader/ShaderLibrary/LightingCommon.hlsl"
#include "../Shader/ShaderLibrary/Fog.hlsl"

struct Attributes
{
    float3 positionOS: POSITION;
    half3 normalOS: NORMAL;
    half4 tangentOS: TANGENT;
    half2 texcoord: TEXCOORD0;
    half2 lightmapUV: TEXCOORD1;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    half4 uv01: TEXCOORD0;
    half4 uv23: TEXCOORD1;
    half2 controlUV: TEXCOORD2;
    DECLARE_GI_DATA(lightmapUV, vertexSH, 3);
    float4 positionWSAndFog: TEXCOORD4;
    
#if _NORMALMAP
    half4 tangentWS: TEXCOORD5;    // xyz: tangent, w: viewDir.x
    half4 bitangentWS: TEXCOORD6;    // xyz: binormal, w: viewDir.y
    half4 normalWS: TEXCOORD7;    // xyz: normal, w: viewDir.z
#else
    half3 normalWS: TEXCOORD5;
    half3 viewDirWS: TEXCOORD6;
#endif
    
#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    float4 shadowCoord : TEXCOORD8;
#endif
};

Varyings TerrainLitVert (Attributes input)
{
    Varyings output = (Varyings)0;

    output.positionWSAndFog.xyz = TransformObjectToWorld(input.positionOS.xyz);
    output.positionCS = TransformWorldToHClip(output.positionWSAndFog.xyz);

#if TERRAIN_2TEX
    output.uv01.xy = input.texcoord * _SplatScale.x;
    output.uv01.zw = input.texcoord * _SplatScale.y;
#elif TERRAIN_3TEX
    output.uv01.xy = input.texcoord * _SplatScale.x;
    output.uv01.zw = input.texcoord * _SplatScale.y;
    output.uv23.xy = input.texcoord * _SplatScale.z;
#elif TERRAIN_4TEX
    output.uv01.xy = input.texcoord * _SplatScale.x;
    output.uv01.zw = input.texcoord * _SplatScale.y;
    output.uv23.xy = input.texcoord * _SplatScale.z;
    output.uv23.zw = input.texcoord * _SplatScale.w;
#endif
    output.controlUV = input.texcoord;

    half3 viewDirWS = _WorldSpaceCameraPos.xyz - output.positionWSAndFog.xyz;
#if _NORMALMAP
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.z);
#else
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.viewDirWS = viewDirWS;
#endif

    OUTPUT_GI_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_GI_SH(output.normalWS.xyz, output.vertexSH);

    output.positionWSAndFog.w = ComputeBuiltInFogFactor(output.positionCS.z);

#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    output.shadowCoord = ComputeShadowCoord(output.positionWSAndFog.xyz, output.positionCS);
#endif
    
    return output;
}

half4 TerrainLitFrag (Varyings input) : SV_TARGET
{
    half4 control = tex2D(_ControlTex, input.controlUV.xy);
    half4 albedo = 0;
#if TERRAIN_2TEX
    half4 splat0 = tex2D(_Splat0, input.uv01.xy);
    half4 splat1 = tex2D(_Splat1, input.uv01.zw);
    albedo += splat0 * control.x * half4(_Color0.rgb, _Smoothness.x);
    albedo += splat1 * control.y * half4(_Color1.rgb, _Smoothness.y);
#elif TERRAIN_3TEX
    half4 splat0 = tex2D(_Splat0, input.uv01.xy);
    half4 splat1 = tex2D(_Splat1, input.uv01.zw);
    half4 splat2 = tex2D(_Splat2, input.uv23.xy);
    albedo += splat0 * control.x * half4(_Color0.rgb, _Smoothness.x);
    albedo += splat1 * control.y * half4(_Color1.rgb, _Smoothness.y);
    albedo += splat2 * control.z * half4(_Color2.rgb, _Smoothness.z);
#elif TERRAIN_4TEX
    half4 splat0 = tex2D(_Splat0, input.uv01.xy);
    half4 splat1 = tex2D(_Splat1, input.uv01.zw);
    half4 splat2 = tex2D(_Splat2, input.uv23.xy);
    half4 splat3 = tex2D(_Splat3, input.uv23.zw);
    albedo += splat0 * control.x * half4(_Color0.rgb, _Smoothness.x);
    albedo += splat1 * control.y * half4(_Color1.rgb, _Smoothness.y);
    albedo += splat2 * control.z * half4(_Color2.rgb, _Smoothness.z);
    albedo += splat3 * control.w * half4(_Color3.rgb, _Smoothness.w);
#endif
    albedo.rgb = ColorSpaceConvertInput(albedo.rgb);

    Surface surface = (Surface)0;
    surface.color.rgb = albedo.rgb;

#if _NORMALMAP
    half3 normalTS = 0;

    #if TERRAIN_2TEX
        normalTS += sampleNormalMap(_NormalMap0, input.uv01.xy, _NormalScale.x) * control.x;
        normalTS += sampleNormalMap(_NormalMap1, input.uv01.zw, _NormalScale.y) * control.y;
    #elif TERRAIN_3TEX
        normalTS += sampleNormalMap(_NormalMap0, input.uv01.xy, _NormalScale.x) * control.x;
        normalTS += sampleNormalMap(_NormalMap1, input.uv01.zw, _NormalScale.y) * control.y;
        normalTS += sampleNormalMap(_NormalMap2, input.uv23.xy, _NormalScale.z) * control.z;
    #elif TERRAIN_4TEX
        normalTS += sampleNormalMap(_NormalMap0, input.uv01.xy, _NormalScale.x) * control.x;
        normalTS += sampleNormalMap(_NormalMap1, input.uv01.zw, _NormalScale.y) * control.y;
        normalTS += sampleNormalMap(_NormalMap2, input.uv23.xy, _NormalScale.z) * control.z;
        normalTS += sampleNormalMap(_NormalMap3, input.uv23.zw, _NormalScale.w) * control.w;
    #endif
    normalTS = SafeNormalize(normalTS);
    half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    half3 normalWS = mul(normalTS, TBN);
    half3 viewDirWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
#else
    half3 normalWS = input.normalWS;
    half3 viewDirWS = input.viewDirWS;
#endif

    surface.normal = SafeNormalize(normalWS);
    surface.viewDirection = SafeNormalize(viewDirWS);
    surface.occlusion = 1;
    surface.position = input.positionWSAndFog.xyz;
    surface.smoothness = albedo.a;


    float4 shadowCoord = 0;
#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    shadowCoord = input.shadowCoord;
#endif 

    GI gi = GET_SIMPLE_GI(input.lightmapUV, input.vertexSH, surface);
#if LIGHTMODEL_LAMBERT
    half3 color = LightingLambert(surface, shadowCoord, gi);
#elif LIGHTMODEL_PBR
    half alpha = 1;
    BRDF brdf = GetSimpleBRDF(surface, alpha);
    half3 color = LightingPBR(brdf, surface, shadowCoord, gi);
#endif

    color = MixBuiltInFog(color, input.positionWSAndFog.w);

    return half4(color, 1);
}


#endif // BIOUM_TERRAIN_PASS_INCLUDE