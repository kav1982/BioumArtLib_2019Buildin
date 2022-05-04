#ifndef BIOUM_CHARACTER_TONE_HAIR_PASS_INCLUDE
#define BIOUM_CHARACTER_TONE_HAIR_PASS_INCLUDE

#include "../Shader/ShaderLibrary/LightingCharacter.hlsl"
#include "../Shader/ShaderLibrary/fog.hlsl"

struct Attributes
{
    float4 positionOS: POSITION;
    half3 normalOS: NORMAL;
    half4 tangentOS: TANGENT;
    half2 texcoord: TEXCOORD0;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    half4 uv: TEXCOORD0;
    half3 vertexSH : TEXCOORD1;
    float4 positionWSAndFog: TEXCOORD2;
    
    half4 tangentWS: TEXCOORD4;    // xyz: tangent, w: viewDir.x
    half4 bitangentWS: TEXCOORD5;    // xyz: binormal, w: viewDir.y
    half4 normalWS: TEXCOORD3;    // xyz: normal, w: viewDir.z

#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    float4 shadowCoord : TEXCOORD6;
#endif

#if _RIM
    half3 normalVS : TEXCOORD7;
    half4 viewDirVS : TEXCOORD8;
#endif
};

Varyings ForwardBaseVert(Attributes input)
{
    Varyings output = (Varyings)0;
    
    output.positionWSAndFog.xyz = TransformObjectToWorld(input.positionOS.xyz);
    output.positionCS = TransformWorldToHClip(output.positionWSAndFog.xyz);
    
    half3 viewDirWS = normalize(_WorldSpaceCameraPos - output.positionWSAndFog.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.z);
    
    output.uv.xy = input.texcoord;
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

half4 ForwardBaseFrag(Varyings input): SV_TARGET
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
#else
    half3 normalWS = input.normalWS.xyz;
#endif

    half3 viewDirWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
    half3 tangentWS = input.tangentWS.xyz;
#if _SWITCH_TANGENT
    tangentWS = input.bitangentWS.xyz;
#endif
    tangentWS = SafeNormalize(tangentWS);

    surface.normal = SafeNormalize(normalWS);
    surface.viewDirection = SafeNormalize(viewDirWS);
    
    half4 maes = sampleMAESMap(input.uv.xy);
    surface.metallic = _Metallic;
    surface.occlusion = maes.a;
    surface.smoothness = _Smoothness;
    surface.specularTint = 1;
    surface.position = input.positionWSAndFog.xyz;
    surface.fresnelStrength = GetFresnel();
    surface.SSSColor.rgb = GetSSSColor();

    float4 shadowCoord = 0;
#if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
    shadowCoord = input.shadowCoord;
#endif  
    
    half alpha = surface.color.a;
    BRDF brdf = GetBRDF(surface, alpha);
    GI gi = GET_GI(0, input.vertexSH, surface, brdf);

    CharacterToneParam toneParam;
    toneParam.lightColorBack = _LightColorControl.rgb;
    toneParam.lightIntensity = _LightColorControl.a;
    toneParam.smoothDiff = _SmoothDiff;
    toneParam.rimColorFront = _RimColorFront.rgb;
    toneParam.rimColorBack = _RimColorBack.rgb;
    toneParam.rimOffset = _RimParam.xy;
    toneParam.rimSmooth = _RimParam.z;
    toneParam.rimPower = _RimParam.w;

    HairParam hairParam;
    hairParam.shift = maes.xy;
    hairParam.specIntensity = GetSpecIntensity();
    hairParam.smoothness = GetSmoothness();
    hairParam.tangent = tangentWS;
    hairParam.specColor = _SubSpecColor.rgb;
    
    half3 color = LightingCharacterHairTone(toneParam, brdf, surface, gi, shadowCoord, hairParam);
#if _RIM
    color = ToneRim(toneParam, color, input.normalVS, input.viewDirVS, surface.occlusion);
#endif

    color = MixBuiltInFog(color, input.positionWSAndFog.w);
    
    return half4(color, alpha);
}


#endif // BIOUM_CHARACTER_TONE_PASS_INCLUDE