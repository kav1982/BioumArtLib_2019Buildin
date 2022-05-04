#ifndef BIOUM_CHARACTER_TONE_PASS_INCLUDE
#define BIOUM_CHARACTER_TONE_PASS_INCLUDE

#include "../Shader/ShaderLibrary/LightingCharacter.hlsl"
#include "../Shader/ShaderLibrary/fog.hlsl"

//-----------------------------------ForwardBase---------------------------//
struct BaseAttributes
{
    float3 positionOS: POSITION;
    half3 normalOS: NORMAL;
    half4 tangentOS: TANGENT;
    half2 texcoord: TEXCOORD0;
};

struct BaseVaryings
{
    float4 positionCS: SV_POSITION;
    half4 uv: TEXCOORD0;
    half3 vertexSH : TEXCOORD1;
    float4 positionWSAndFog: TEXCOORD2;
    
#ifdef _NORMALMAP
    half4 tangentWS: TEXCOORD4;    // xyz: tangent, w: viewDir.x
    half4 bitangentWS: TEXCOORD5;    // xyz: binormal, w: viewDir.y
    half4 normalWS: TEXCOORD3;    // xyz: normal, w: viewDir.z
#else
    half3 normalWS: TEXCOORD3;
    half3 viewDirWS: TEXCOORD4;
#endif

#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    float4 shadowCoord : TEXCOORD6;
#endif

#if _RIM
    half3 normalVS : TEXCOORD7;
    half4 viewDirVS : TEXCOORD8;
#endif

};

BaseVaryings ForwardBaseVert(BaseAttributes input)
{
    BaseVaryings output = (BaseVaryings)0;
    
    half3 positionWS = TransformObjectToWorld(input.positionOS);
    output.positionWSAndFog.xyz = positionWS;
    output.positionCS = TransformWorldToHClip(positionWS);
    
    half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos.xyz - positionWS);
#if _NORMALMAP
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.z);
#else
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.viewDirWS = viewDirWS;
#endif
    
    output.uv.xy = GetBaseUV(input.texcoord);
    
    OUTPUT_GI_SH(output.normalWS.xyz, output.vertexSH);
    
    output.positionWSAndFog.w = ComputeBuiltInFogFactor(output.positionCS.z);

#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    output.shadowCoord = ComputeShadowCoord(output.positionWSAndFog.xyz, output.positionCS);
#endif

#if _RIM
    half3 lightDirVS = TransformWorldToViewDir(MainLightDirection(), false);
    output.viewDirVS.xyz = TransformWorldToViewDir(viewDirWS, false);
    output.viewDirVS.w = lightDirVS.x;
    output.normalVS = TransformWorldToViewDir(output.normalWS.xyz, false);
#endif
    
    return output;
}

half4 ForwardBaseFrag(BaseVaryings input): SV_TARGET
{
    Surface surface = (Surface)0;
    surface.color = sampleBaseMap(input.uv.xy);
#if _ALPHATEST_ON
    clip(surface.color.a - _Cutoff);
#endif
    
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
    surface.SSSColor.rgb = GetSSSColor();


    float4 shadowCoord = 0;
#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    shadowCoord = input.shadowCoord;
#endif  


    half alpha = GetTransparent() * surface.color.a;
    BRDF brdf = GetBRDF(surface, alpha);
    GI gi = GET_GI(0, input.vertexSH, surface, brdf);

    CharacterToneParam toneParam;
    toneParam.lightColorBack = lerp(_LightColorControl.rgb, _SkinBackColor.rgb, maes.b);
    toneParam.lightIntensity = _LightColorControl.a;
    toneParam.smoothDiff = _SmoothDiff;
    toneParam.rimColorFront = _RimColorFront.rgb;
    toneParam.rimColorBack = _RimColorBack.rgb;
    toneParam.rimOffset = _RimParam.xy;
    toneParam.rimSmooth = _RimParam.z;
    toneParam.rimPower = _RimParam.w;

    
    half3 color = LightingCharacterTone(toneParam, brdf, surface, shadowCoord, gi);

#if _RIM
    color = ToneRim(toneParam, color, input.normalVS, input.viewDirVS, surface.occlusion);
#endif

    color = MixBuiltInFog(color, input.positionWSAndFog.w);

    return half4(color, alpha);
}
//-----------------------------------ForwardBase---------------------------//


//-----------------------------------ForwardAdd----------------------------//
// struct AddAttributes
// {
//     half3 positionOS: POSITION;
//     half3 normalOS: NORMAL;
//     half4 tangentOS: TANGENT;
//     half2 texcoord: TEXCOORD0;
//     half2 lightmapUV: TEXCOORD1;
//     UNITY_VERTEX_INPUT_INSTANCE_ID
// };

// struct AddVaryings
// {
//     half4 positionCS: SV_POSITION;
//     half4 uv: TEXCOORD0;
//     half3 vertexSH : TEXCOORD1;
//     half4 positionWSAndFog: TEXCOORD2;
// #ifdef _NORMALMAP
//     half4 tangentWS: TEXCOORD4;    // xyz: tangent, w: viewDir.x
//     half4 bitangentWS: TEXCOORD5;    // xyz: binormal, w: viewDir.y
//     half4 normalWS: TEXCOORD3;    // xyz: normal, w: viewDir.z
// #else
//     half3 normalWS: TEXCOORD3;
//     half3 viewDirWS: TEXCOORD4;
// #endif
//     UNITY_VERTEX_INPUT_INSTANCE_ID
// };

// AddVaryings ForwardAddVert(AddAttributes input)
// {
//     AddVaryings output = (AddVaryings)0;
//     UNITY_SETUP_INSTANCE_ID(input);
//     UNITY_TRANSFER_INSTANCE_ID(input, output);
    
//     half3 positionWS = TransformObjectToWorld(input.positionOS);
//     output.positionWSAndFog.xyz = positionWS;
//     output.positionCS = TransformWorldToHClip(positionWS);
    
//     half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos - positionWS);
// #if _NORMALMAP
//     VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
//     output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
//     output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
//     output.normalWS = half4(normalInput.normalWS, viewDirWS.z);
// #else
//     output.normalWS = TransformObjectToWorldNormal(input.normalOS);
//     output.viewDirWS = viewDirWS;
// #endif
    
//     output.uv.xy = GetBaseUV(input.texcoord);
//     output.vertexSH = SampleSH(output.normalWS.xyz);
    
//     output.positionWSAndFog.w = ComputeBuiltInFogFactor(output.positionCS.z);
    
//     return output;
// }

// half4 ForwardAddFrag(AddVaryings input): SV_TARGET
// {
//     UNITY_SETUP_INSTANCE_ID(input);
//     ClipLOD(input.positionCS.xy, unity_LODFade.x);
    
//     Surface surface = (Surface)0;
//     surface.color = sampleBaseMap(input.uv.xy);
// #if _ALPHATEST_ON
//     half cutout = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
//     clip(surface.color.a - cutout);
// #endif
    
// #if _NORMALMAP
//     half3 normalTS = sampleBumpMap(input.uv.xy);
//     half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
//     half3 normalWS = mul(normalTS, TBN);
//     half3 viewDirWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
// #else
//     half3 normalWS = input.normalWS;
//     half3 viewDirWS = input.viewDirWS;
// #endif
//     surface.normal = SafeNormalize(normalWS);
//     surface.viewDirection = viewDirWS;
    
//     half4 maes = sampleMAESMap(input.uv.xy);
//     surface.metallic = maes.r;
//     surface.occlusion = maes.g;
//     surface.smoothness = maes.a;
    
//     surface.position = input.positionWSAndFog.xyz;
//     surface.fresnelStrength = GetFresnel();
    
//     BRDF brdf = GetBRDF(surface);
//     half3 color = LightingCharacterCommonAdd(brdf, surface);

//     color = MixBuiltInFog(color, half3(0,0,0), input.positionWSAndFog.w);
    
//     return half4(color, surface.color.a);
// }
//-----------------------------------ForwardAdd----------------------------//

#endif // BIOUM_CHARACTER_TONE_PASS_INCLUDE