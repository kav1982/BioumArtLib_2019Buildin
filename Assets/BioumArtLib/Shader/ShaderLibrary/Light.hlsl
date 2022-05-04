#ifndef BIOUM_LIGHT_INCLUDED
#define BIOUM_LIGHT_INCLUDED

#include "AutoLight.cginc"

half4 _LightColor0;

struct Light
{
    half3   direction;
    half3   color;
    half    distanceAttenuation;
    half    shadowAttenuation;
};

half4 ComputeShadowCoord(half3 positionWS, half4 positionCS)
{
    float4 shadowCoord = 0;
    #if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
        #if defined(UNITY_NO_SCREENSPACE_SHADOWS)
            shadowCoord = mul(unity_WorldToShadow[0], unityShadowCoord4(positionWS, 1));
        #else
            shadowCoord = ComputeNonStereoScreenPos(positionCS);
        #endif
    #endif

    return shadowCoord;
}

half MainLightRealtimeShadow(float4 shadowCoord, float3 positionWS, half shadowMask = 1)
{
    half realtimeShadowAttenuation = 1.0f;
    //directional realtime shadow
    #if defined (SHADOWS_SCREEN) && defined(DIRECTIONAL)
        realtimeShadowAttenuation = unitySampleShadow(shadowCoord);
    #endif

    //fade value
    float zDist = dot(_WorldSpaceCameraPos - positionWS, UNITY_MATRIX_V[2].xyz);
    float fadeDist = UnityComputeShadowFadeDistance(positionWS, zDist);
    half  realtimeToBakedShadowFade = UnityComputeShadowFade(fadeDist);

    realtimeShadowAttenuation = UnityMixRealtimeAndBakedShadows(realtimeShadowAttenuation, shadowMask, realtimeToBakedShadowFade);

    return realtimeShadowAttenuation;
}

half3 MainLightDirection()
{
    return _WorldSpaceLightPos0.xyz;
}



half GetAttenuation(half3 positionWS)
{
    half atten = 1;

#if defined(POINT)
    unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(positionWS, 1)).xyz;
    atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
#endif

#if defined(SPOT)
    unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(positionWS, 1));
    atten = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#endif

    return saturate(atten);
}


Light GetLight(float3 positionWS)
{
    Light light;
    light.direction = SafeNormalize(UnityWorldSpaceLightDir(positionWS));
    light.color = _LightColor0.rgb;
    light.shadowAttenuation = 1.0;
    light.distanceAttenuation = GetAttenuation(positionWS);

    light.color = ColorSpaceConvertInput(light.color);

    return light;
}

Light GetLight(float3 positionWS, float4 shadowCoord, half shadowMask = 1)
{
    Light light = GetLight(positionWS);

    light.shadowAttenuation = MainLightRealtimeShadow(shadowCoord, positionWS, shadowMask);

    return light;
}




#endif  //BIOUM_LIGHT_INCLUDED