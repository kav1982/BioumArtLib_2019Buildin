#ifndef BIOUM_SURFACE_UNCLUDE
#define BIOUM_SURFACE_UNCLUDE

struct Surface
{
    half4 color;
    half3 specular;
    half3 viewDirection;
    half3 position;
    half  metallic;
    half  smoothness;
    half3 normal;
    half  occlusion;
    half fresnelStrength;
    half specularTint;
    half4 SSSColor;
};

#endif