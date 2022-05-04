#ifndef BIOUM_LIGHTING_COMMON_INCLUDED
#define BIOUM_LIGHTING_COMMON_INCLUDED

//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "LightingBase.hlsl"



half3 Lambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return NdotL * lightColor;
}
half3 HalfLambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = dot(normal, lightDir) * 0.5 + 0.5;
    return NdotL * lightColor;
}

half3 IncomingLight(Surface surface, Light light)
{
    half3 shadow = light.shadowAttenuation * light.distanceAttenuation;
    half3 color = Lambert(light.color, light.direction, surface.normal);
    return color * shadow;
}


half3 DirectBRDF(Surface surface, BRDF brdf, Light light)
{
    half3 specular = brdf.diffuse;

#if _SPECULAR_ON
    specular += SpecularStrength(surface, brdf, light) * brdf.specular;
#endif

    half3 radiance = IncomingLight(surface, light);

    return specular * radiance;
}



// final lighting

half3 LightingPBR(BRDF brdf, Surface surface, float4 shadowCoord, GI gi)
{
    half3 color = 0;
#ifndef BIOUM_ADDPASS
    color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    color *= surface.occlusion; 
#endif

    Light light = GetLight(surface.position, shadowCoord, gi.shadowMask);
    color += DirectBRDF(surface, brdf, light);

#if _SIMPLE_SSS
    color += SimpleSSS(surface, light.direction, surface.SSSColor.a);
#endif

    return color;
}

half3 LightingLambert(Surface surface, float4 shadowCoord, GI gi)
{
    half3 color = 0;
#ifndef BIOUM_ADDPASS
    color = surface.color.rgb * gi.diffuse;
    color *= surface.occlusion; 
#endif

    Light light = GetLight(surface.position, shadowCoord, gi.shadowMask);

    color += IncomingLight(surface, light) * surface.color.rgb;

#if _SIMPLE_SSS
    color += SimpleSSS(surface, light.direction, surface.SSSColor.a);
#endif

    return color;
}


#endif  //BIOUM_LIGHTING_COMMON_INCLUDED