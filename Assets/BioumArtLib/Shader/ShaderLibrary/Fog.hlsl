#ifndef BIOUM_FOG_INCLUDE
#define BIOUM_FOG_INCLUDE

half4 Bioum_FogColor;
half4 Bioum_FogSunColor;

// x = start distance
// y = distance falloff
// z = start height 
// w = height falloff
half4 Bioum_FogParam;

// x = strength
// y = range
half4 Bioum_FogScatteringParam;


//distance exp fog and height exp fog
//http://www.iquilezles.org/www/articles/fog/fog.htm
half ComputeFogFactor(half3 positionWS, half fogStrength) 
{
    float fogFactor = 0;
#if defined(BIOUM_FOG_SIMPLE) || defined(BIOUM_FOG_HEIGHT)
#ifdef BIOUM_FOG_SIMPLE
    float dis = distance(_WorldSpaceCameraPos.xyz, positionWS);
    float disFogFactor = max(0, 1 - exp(-(dis - Bioum_FogParam.x) * Bioum_FogParam.y));
    fogFactor = disFogFactor;
#endif

#ifdef BIOUM_FOG_HEIGHT
    float heightFogFactor = max(0, 1 - exp((positionWS.y - Bioum_FogParam.z) * Bioum_FogParam.w));
    fogFactor = heightFogFactor;
#endif

#if defined(BIOUM_FOG_SIMPLE) && defined(BIOUM_FOG_HEIGHT)
    fogFactor = lerp(heightFogFactor * disFogFactor, saturate(disFogFactor + heightFogFactor), disFogFactor);
#endif

    fogFactor += fogStrength - 1;
#endif

    return saturate(fogFactor);
}
half3 GetScatteringColor(half3 lightDir, half3 lightColor, half3 viewDirWS)
{
    half sun = max(0, dot(-lightDir, viewDirWS));
    sun = pow(sun, Bioum_FogScatteringParam.y);
    sun *= Bioum_FogScatteringParam.x;
    return lightColor.rgb * sun;
}
half3 MixFogColor(half3 fogColor, half3 color, half fogFactor, half3 viewDirWS)
{
#if defined(BIOUM_FOG_SIMPLE) || defined(BIOUM_FOG_HEIGHT)
#if defined(BIOUM_FOG_SCATTERING)
    half3 lightDir = _DirectionalLightDirections[0].xyz;
    half3 lightColor = _DirectionalLightColors[0].rgb;
    half3 scatteringColor = GetScatteringColor(lightDir, lightColor, viewDirWS);
    fogColor += scatteringColor;
#endif
    return lerp(color, fogColor, fogFactor);
#endif
    return color;
}
half3 MixFogColor(half3 color, half fogFactor, half3 viewDirWS)
{
    return MixFogColor(Bioum_FogColor.rgb, color, fogFactor, viewDirWS);
}



//--------------------------builtin fog--------------------------//
half ComputeBuiltInFogFactor(float z)
{
    float clipZ_01 = UNITY_Z_0_FAR_FROM_CLIPSPACE(z);

    half fogFactor = 0;
#if defined(FOG_LINEAR)
    // factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
    fogFactor = saturate(clipZ_01 * unity_FogParams.z + unity_FogParams.w);
#elif defined(FOG_EXP)
    fogFactor = unity_FogParams.x * clipZ_01;
    fogFactor = saturate(exp2(-fogFactor));
#elif defined(FOG_EXP2)
    fogFactor = unity_FogParams.x * clipZ_01;
    fogFactor = saturate(exp2(-fogFactor * fogFactor));
#endif
    return fogFactor;
}
half3 MixBuiltInFog(half3 fragColor, half3 fogColor, half fogFactor)
{
    half3 color = fragColor;
#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
    color = lerp(fogColor, fragColor, fogFactor);
#endif
    return color;
}
half3 MixBuiltInFog(half3 fragColor, half fogFactor)
{
    half3 fogColor = unity_FogColor.rgb;
#ifdef BIOUM_ADDPASS
    fogColor = 0;
#endif
    return MixBuiltInFog(fragColor, fogColor, fogFactor);
}
//--------------------------builtin fog--------------------------//

//fog end

#endif  //BIOUM_FOG_INCLUDE