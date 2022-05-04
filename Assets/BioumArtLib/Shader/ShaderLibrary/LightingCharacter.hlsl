#ifndef BIOUM_LIGHTING_CHARACTER_INCLUDE
#define BIOUM_LIGHTING_CHARACTER_INCLUDE

#include "LightingBase.hlsl"

struct CharacterToneParam
{
    half3 lightColorBack;
    half lightIntensity;
    half smoothDiff;

    half3 rimColorFront;
    half3 rimColorBack;
    half2 rimOffset;
    half rimPower;
    half rimSmooth;
};

struct HairParam
{
    half2 shift;
    half2 smoothness;
    half2 specIntensity;
    half3 tangent;
    half3 specColor;
};



half3 IncomingLightTone(CharacterToneParam toneParam, Surface surface, Light light)
{
    half3 atten = light.shadowAttenuation * light.distanceAttenuation;
    half3 color = light.color;
    half3 NdotL = 0;

#if _SSS
    NdotL = SGDiffuseLighting(surface.normal, light.direction, surface.SSSColor);
#else
    NdotL = dot(surface.normal, light.direction);
#endif

    half3 smoothNdotL = smoothstep(0, toneParam.smoothDiff, NdotL);
    atten *= smoothNdotL;

#ifndef UNITY_COLORSPACE_GAMMA
    toneParam.lightColorBack = LinearToSRGB(toneParam.lightColorBack);
#endif

#ifdef BIOUM_ADDPASS
    return color * atten * toneParam.lightIntensity;
#else
    return lerp((toneParam.lightColorBack * 2 - 1) * color, color, atten) * toneParam.lightIntensity;
#endif
}

half3 DirectBRDFTone(CharacterToneParam toneParam, Surface surface, BRDF brdf, Light light)
{
    half3 specular = brdf.diffuse;

#if _SPECULAR_ON
    specular += SpecularStrength(surface, brdf, light) * brdf.specular;
    //specular = min(10.0f,specular);
#endif

    half3 radiance = IncomingLightTone(toneParam, surface, light);

    return max(0, specular * radiance);
}


half3 ToneRim(CharacterToneParam toneParam, half3 fragColor, half3 normalVS, half4 viewDirVS, half occlusion) // viewDirVS.w : lightDirVS.x
{
    half2 offset = half2(-viewDirVS.w, viewDirVS.w) * toneParam.rimOffset;
    half3 frontView = viewDirVS.xyz + half3(offset.x, 0, 0);
    half3 backView = viewDirVS.xyz + half3(offset.y, 0, 0);
    half NdotFV = max(0, dot(normalVS, frontView));
    half NdotBV = max(0, dot(normalVS, backView));

    half NdotU = saturate(normalVS.y * 0.7 + 0.3);  // normalVS.y = dot(normalVS, (0, 1, 0))
    half2 rim = PositivePow(1 - half2(NdotFV, NdotBV), toneParam.rimPower);
    rim = smoothstep(0.5 - toneParam.rimSmooth, 0.5 + toneParam.rimSmooth, rim);
    rim *= half2(NdotU, 1 - NdotU) * occlusion;

    half3 rimFColor = rim.x * toneParam.rimColorFront.rgb;
    fragColor += rimFColor;

    fragColor = lerp(fragColor, fragColor * toneParam.rimColorBack, rim.y);

    return fragColor;
}



//hair
half3 ShiftT(half3 tangent, half3 normal, half shift)
{
	return tangent + normal * shift;
}
half KajiyaKaySpec(half3 tangent, half3 viewDirWS, half3 lightDirWS, half smoothness)
{
	half3 halfDir = normalize(lightDirWS + viewDirWS);
	half tdoth = dot(tangent, halfDir);
	half sinTH = sqrt(max(0, 1 - tdoth * tdoth));
	half dirAtten = smoothstep(-1, 0, tdoth);

	half roughness = Pow4(1 - smoothness);
	half power = rcp(max(0.001, roughness));
    half intensity = smoothness * smoothness;

	return dirAtten * PositivePow(sinTH, power) * intensity;
}
half3 DirectHairSpecularTone(CharacterToneParam toneParam, Light light, half3 diffuse, Surface surface, HairParam hairParam)
{
    half3 lambert = IncomingLightTone(toneParam, surface, light);
    half3 shiftTangent0 = ShiftT(hairParam.tangent, surface.normal, hairParam.shift.x);
    half3 spec0 = KajiyaKaySpec(shiftTangent0, surface.viewDirection, light.direction, hairParam.smoothness.x) * hairParam.specIntensity.x;
    half3 spec1 = 0;
#if _DOUBLE_SPECULAR
    half3 shiftTangent1 = ShiftT(hairParam.tangent, surface.normal, hairParam.shift.y);
    spec1 = KajiyaKaySpec(shiftTangent1, surface.viewDirection, light.direction, hairParam.smoothness.y) * hairParam.specIntensity.y;
    spec1 *= hairParam.specColor;
#endif

    half3 specColor = lerp(1, surface.color.rgb, surface.metallic);
    specColor *= spec0 + spec1;
    return lambert * (diffuse + specColor);
}
//hair


// final lighting




/// tone lighting
half3 LightingCharacterTone(CharacterToneParam toneParam, BRDF brdf, Surface surface, float4 shadowCoord, GI gi)
{
    half3 color = 0;
#ifndef BIOUM_ADDPASS
    color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    color *= surface.occlusion; 
#endif

    Light light = GetLight(surface.position, shadowCoord);
    color += DirectBRDFTone(toneParam, surface, brdf, light);
    color = max(0.001, color);

    color = ColorSpaceConvertOutput(color);

    return color;
}
half3 LightingCharacterHairTone(CharacterToneParam toneParam, BRDF brdf, Surface surface, GI gi, float4 shadowCoord, HairParam hairParam)
{
    half3 color = 0;
#ifndef BIOUM_ADDPASS
    gi.specular = lerp(gi.specular * 0.1, gi.specular, surface.metallic);
    color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    color *= surface.occlusion;
#endif

    Light light = GetLight(surface.position, shadowCoord);
    color += DirectHairSpecularTone(toneParam, light, brdf.diffuse, surface, hairParam);
    color = max(0.001, color);

    color = ColorSpaceConvertOutput(color);
    
    return color;
}




#endif //BIOUM_LIGHTING_CHARACTER_INCLUDE