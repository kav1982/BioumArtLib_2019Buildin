#ifndef BIOUM_GI_INCLUDE
#define BIOUM_GI_INCLUDE

#ifdef LIGHTMAP_ON
#define DECLARE_GI_DATA(lmName, shName, index) float2 lmName : TEXCOORD##index
#define OUTPUT_GI_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
#define OUTPUT_GI_SH(normalWS, OUT)
#else
#define DECLARE_GI_DATA(lmName, shName, index) half3 shName : TEXCOORD##index
#define OUTPUT_GI_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
#define OUTPUT_GI_SH(normalWS, OUT) OUT.xyz = SampleSH(normalWS)
#endif

#ifndef UNITY_SPECCUBE_LOD_STEPS
#define UNITY_SPECCUBE_LOD_STEPS (6)
#endif

#if _CHARACTER_IN_UI
UNITY_DECLARE_TEXCUBE(_CharacterEnvironmentCube);
half4 _CharacterEnvironmentCube_HDR;
half4 _CharacterEnvironmentColor; // a : cube mipmap count
half4 _CharacterEnvironmentParam; // X:旋转 Y:曝光 Z:mipmap数量
#endif

half PerceptualRoughnessToMipmapLevel(half perceptualRoughness, uint mipMapCount)
{
    perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);

    return perceptualRoughness * mipMapCount;
}
half PerceptualRoughnessToMipmapLevel(half perceptualRoughness)
{
    return PerceptualRoughnessToMipmapLevel(perceptualRoughness, UNITY_SPECCUBE_LOD_STEPS);
}


half GetMipmapLevel(half perceptualRoughness)
{
    return perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;
}

half3 SampleEnvironment (Surface surfaceWS, BRDF brdf) 
{
    half3 color = 0;
#ifndef BIOUM_ADDPASS

    half3 uvw = reflect(-surfaceWS.viewDirection, surfaceWS.normal);

    #if _CHARACTER_IN_UI
        half2x2 rotMatrix = GetRotationMatrix(_CharacterEnvironmentParam.x);
        uvw.xz = mul(uvw.xz, rotMatrix);
        
        half lod = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness, (uint)_CharacterEnvironmentParam.z);
        half4 environment = UNITY_SAMPLE_TEXCUBE_LOD(_CharacterEnvironmentCube, uvw, lod);
        color = DecodeHDR(environment, _CharacterEnvironmentCube_HDR) * _CharacterEnvironmentParam.y;
    #else
        half lod = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness);
        half4 environment = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, uvw, lod);
        color = BioumDecodeHDR(environment, unity_SpecCube0_HDR);
    #endif

#endif

    return min(10.0f,color);
}

half3 SampleLightmap(half2 lightmapUV)
{
    half3 bakedColor = 0;
#ifndef BIOUM_ADDPASS
    #if defined(LIGHTMAP_ON)
        half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapUV);
        bakedColor = DecodeLightmap(bakedColorTex);
    #endif
#endif
    return bakedColor;
}
half3 SH9 (half4 normal) // 返回线性空间sh
{
    // Linear + constant polynomial terms
    half3 res = SHEvalLinearL0L1 (normal);
    // Quadratic polynomials
    res += SHEvalLinearL2 (normal);
    return res;
}
half3 SampleSH(half3 normalWS)
{
    half3 sh = 0;
#ifndef BIOUM_ADDPASS
    #if _CHARACTER_IN_UI
        sh = _CharacterEnvironmentColor.rgb;
    #else
        #if !defined(LIGHTMAP_ON)
            sh = SH9(half4(normalWS, 1));
        #endif
    #endif
#endif
    return sh;
}

half4 SampleShadowMask(half2 lightMapUV)
{
    half4 shadows = 1;
#if SHADOWS_SHADOWMASK
    shadows = UNITY_SAMPLE_TEX2D(unity_ShadowMask, lightMapUV);
#endif
    return shadows;
}



struct GI 
{
    half3 diffuse;
    half3 specular;
    half4 shadowMask;
};

GI GetSimpleGI (half2 lightMapUV, half3 vertexSH, Surface surfaceWS) 
{
    GI gi = (GI)0;
#ifndef BIOUM_ADDPASS
    
    gi.diffuse = SampleLightmap(lightMapUV) + vertexSH;
    gi.specular = unity_IndirectSpecColor.rgb;
#if _CHARACTER_IN_UI
    gi.specular = _CharacterEnvironmentColor.rgb;  
#endif
    gi.shadowMask = SampleShadowMask(lightMapUV);

    gi.diffuse = ColorSpaceConvertInput(gi.diffuse);

#endif

    return gi;
}
GI GetGI (half2 lightMapUV, half3 vertexSH, Surface surfaceWS, BRDF brdf) 
{
    GI gi = GetSimpleGI(lightMapUV, vertexSH, surfaceWS);

#if _ENVIRONMENT_REFLECTION_ON && !defined(BIOUM_ADDPASS)
    gi.specular = SampleEnvironment(surfaceWS, brdf);
    gi.specular = ColorSpaceConvertInput(gi.specular);
#endif

    return gi;
}


#ifdef LIGHTMAP_ON
#define GET_GI(lmName, shName, surface, brdfName) GetGI(lmName, 0, surface, brdfName)
#define GET_SIMPLE_GI(lmName, shName, surface) GetSimpleGI(lmName, 0, surface)
#else
#define GET_GI(lmName, shName, surface, brdfName) GetGI(0, shName, surface, brdfName)
#define GET_SIMPLE_GI(lmName, shName, surface) GetSimpleGI(0, shName, surface)
#endif


#endif