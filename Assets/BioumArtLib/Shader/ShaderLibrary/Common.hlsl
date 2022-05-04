#ifndef BIOUM_COMMON_INCLUDE
#define BIOUM_COMMON_INCLUDE

#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"

#define UNITY_MATRIX_M      unity_ObjectToWorld
#define UNITY_MATRIX_I_M    unity_WorldToObject
#define UNITY_MATRIX_V      unity_MatrixV
#define UNITY_MATRIX_VP     unity_MatrixVP
#define UNITY_MATRIX_P      glstate_matrix_projection

#define HALF_EPS 4.8828125e-4    // 2^-11, machine epsilon: 1 + EPS = 1 (half of the ULP for 1.0f)
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define HALF_MAX 65504.0


#define Square(x) (x)*(x)
#define PositivePow(base, power) pow(abs(base), power)

half positiveSin(half x)
{
    x = fmod(x, UNITY_TWO_PI);
    return sin(x) * 0.5 + 0.5;
}

half Pow4(half x)
{
    return (x * x) * (x * x);
}

half SRGBToLinear(half c)
{
    return c * c;
}
half3 SRGBToLinear(half3 c)
{
    return c * c;
}
half4 SRGBToLinear(half4 c)
{
    return half4(SRGBToLinear(c.rgb), c.a);
}

half LinearToSRGB(half c)
{
    return sqrt(c);
}
half3 LinearToSRGB(half3 c)
{
    return sqrt(c);
}
half4 LinearToSRGB(half4 c)
{
    return half4(LinearToSRGB(c.rgb), c.a);
}

half3 ColorSpaceConvertInput(half3 color)
{
#ifdef UNITY_COLORSPACE_GAMMA
    color = SRGBToLinear(color);
#endif
    return color;
}
half4 ColorSpaceConvertInput(half4 color)
{
#ifdef UNITY_COLORSPACE_GAMMA
    color = SRGBToLinear(color);
#endif
    return color;
}
half3 ColorSpaceConvertOutput(half3 color)
{
#ifdef UNITY_COLORSPACE_GAMMA
    color = LinearToSRGB(color);
#endif
    return color;
}
half4 ColorSpaceConvertOutput(half4 color)
{
#ifdef UNITY_COLORSPACE_GAMMA
    color = LinearToSRGB(color);
#endif
    return color;
}


float DistanceSquared(float3 pA, float3 pB) 
{
    return dot(pA - pB, pA - pB);
}

half LerpWhiteTo(half b, half t)
{
    half oneMinusT = 1.0 - t;
    return oneMinusT + b * t;
}
half3 LerpWhiteTo(half3 b, half t)
{
    half oneMinusT = 1.0 - t;
    return half3(oneMinusT, oneMinusT, oneMinusT) + b * t;
}


half2x2 GetRotationMatrix(half rotation) // rotation为弧度单位
{
    half sinResult, cosResult;
    sincos(rotation, sinResult, cosResult);
    half2x2 rotMatrix = half2x2(cosResult, -sinResult, sinResult, cosResult);
    return rotMatrix;
}


// Normalize that account for vectors with zero length
half3 SafeNormalize(half3 inVec)
{
    half dp3 = max(HALF_MIN, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}

half3 BioumShadeSH9 (half3 normalWS)
{
    half4 n = half4(normalWS, 1);
    // Linear + constant polynomial terms
    half3 res = SHEvalLinearL0L1 (n);
    // Quadratic polynomials
    res += SHEvalLinearL2 (n);

// #if defined(UNITY_COLORSPACE_GAMMA)
//     res = LinearToSRGB(res);
// #endif

    return max(HALF_MIN, res);
}


inline half3 BioumDecodeHDR (half4 data, half4 decodeInstructions)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    half alpha = decodeInstructions.w * (data.a - 1.0) + 1.0;

    // If Linear mode is not supported we can skip exponent part
    #if defined(UNITY_COLORSPACE_GAMMA)
        return (decodeInstructions.x * alpha) * data.rgb;
    #else
    #   if defined(UNITY_USE_NATIVE_HDR)
            return decodeInstructions.x * data.rgb; // Multiplier for future HDRI relative to absolute conversion.
    #   else
            return (decodeInstructions.x * pow(alpha, decodeInstructions.y)) * data.rgb;
    #   endif
    #endif
}


// ------------------------------------Packing---------------------------------------//
// Unpack from normal map
half3 UnpackNormalRGB(half4 packedNormal, half scale = 1.0)
{
    half3 normal;
    normal.xyz = packedNormal.rgb * 2.0 - 1.0;
    normal.xy *= scale;
    return normal;
}

half3 UnpackNormalAG(half4 packedNormal, half scale = 1.0)
{
    half3 normal;
    normal.xy = packedNormal.ag * 2.0 - 1.0;
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));

    // must scale after reconstruction of normal.z which also
    // mirrors UnpackNormalRGB(). This does imply normal is not returned
    // as a unit length vector but doesn't need it since it will get normalized after TBN transformation.
    // If we ever need to blend contributions with built-in shaders for URP
    // then we should consider using UnpackDerivativeNormalAG() instead like
    // HDRP does since derivatives do not use renormalization and unlike tangent space
    // normals allow you to blend, accumulate and scale contributions correctly.
    normal.xy *= scale;
    return normal;
}

// Unpack normal as DXT5nm (1, y, 0, x) or BC5 (x, y, 0, 1)
half3 UnpackNormalmapRGorAG(half4 packedNormal, half scale = 1.0)
{
    // Convert to (?, y, 0, x)
    packedNormal.a *= packedNormal.r;
    return UnpackNormalAG(packedNormal, scale);
}

half3 UnpackNormalScale(half4 packedNormal, half bumpScale)
{
#if defined(UNITY_NO_DXT5nm)
    return UnpackNormalRGB(packedNormal, bumpScale);
#else
    return UnpackNormalmapRGorAG(packedNormal, bumpScale);
#endif
}

half3 UnpackNormalScale56(half4 packednormal, half bumpScale)  // unity 5.6
{
    #if defined(UNITY_NO_DXT5nm)
        return packednormal.xyz * 2 - 1;
    #else
        half3 normal;
        normal.xy = (packednormal.wy * 2 - 1);
        normal.xy *= bumpScale;
        normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
        return normal;
    #endif
}
// ------------------------------------Packing---------------------------------------//

// --------------------------------SpaceTransform---------------------------------------//
float3 TransformObjectToWorld(float3 positionOS)
{
    return mul(UNITY_MATRIX_M, float4(positionOS, 1.0)).xyz;
}
float3 TransformWorldToView(float3 positionWS)
{
    return mul(UNITY_MATRIX_V, float4(positionWS, 1.0)).xyz;
}
// Tranforms position from world space to homogenous space
float4 TransformWorldToHClip(float3 positionWS)
{
    return mul(UNITY_MATRIX_VP, float4(positionWS, 1.0));
}
half3 TransformObjectToWorldDir(half3 positionOS, bool doNormalize = true)
{
    half3 dirWS = mul((half3x3)UNITY_MATRIX_M, positionOS);
    if (doNormalize)
        return normalize(dirWS);

    return dirWS;
}
// Transforms normal from object to world space
half3 TransformObjectToWorldNormal(half3 normalOS, bool doNormalize = true)
{
#ifdef UNITY_ASSUME_UNIFORM_SCALING
    return TransformObjectToWorldDir(normalOS, doNormalize);
#else
    // Normal need to be multiply by inverse transpose
    half3 normalWS = mul(normalOS, (half3x3)UNITY_MATRIX_I_M);
    if (doNormalize)
        return SafeNormalize(normalWS);
    
    return normalWS;
#endif
}
// Tranforms vector from world space to view space
half3 TransformWorldToViewDir(half3 dirWS, bool doNormalize = true)
{
    half3 dirVS = mul((half3x3)UNITY_MATRIX_V, dirWS).xyz;
    if (doNormalize)
        return normalize(dirVS);

    return dirVS; 
}
// --------------------------------SpaceTransform---------------------------------------//

struct VertexNormalInputs
{
    half3 tangentWS;
    half3 bitangentWS;
    half3 normalWS;
};

half GetOddNegativeScale()
{
    return unity_WorldTransformParams.w;
}

VertexNormalInputs GetVertexNormalInputs(half3 normalOS, half4 tangentOS)
{
    VertexNormalInputs tbn;

    // mikkts space compliant. only normalize when extracting normal at frag.
    half sign = tangentOS.w * GetOddNegativeScale();
    tbn.normalWS = TransformObjectToWorldNormal(normalOS);
    tbn.tangentWS = TransformObjectToWorldDir(tangentOS.xyz);
    tbn.bitangentWS = cross(tbn.normalWS, tbn.tangentWS) * sign;
    return tbn;
}



struct VertexPositionInputs
{
    float3 positionWS; // World space position
    float3 positionVS; // View space position
    float4 positionCS; // Homogeneous clip space position
    float4 positionNDC;// Homogeneous normalized device coordinates
};
VertexPositionInputs GetVertexPositionInputs(float3 positionOS)
{
    VertexPositionInputs input;
    input.positionWS = TransformObjectToWorld(positionOS);
    input.positionVS = TransformWorldToView(input.positionWS);
    input.positionCS = TransformWorldToHClip(input.positionWS);

    float4 ndc = input.positionCS * 0.5f;
    input.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    input.positionNDC.zw = input.positionCS.zw;

    return input;
}




//From  Next Generation Post Processing in Call of Duty: Advanced Warfare [Jimenez 2014]
// http://advances.realtimerendering.com/s2014/index.html
float InterleavedGradientNoise(float2 pixCoord, int frameCount)
{
    const float3 magic = float3(0.06711056f, 0.00583715f, 52.9829189f);
    float2 frameMagicScale = float2(2.083f, 4.867f);
    pixCoord += frameCount * frameMagicScale;
    return frac(magic.z * frac(dot(pixCoord, magic.xy)));
}

float GetDither(float2 positionCS)
{
    return InterleavedGradientNoise(positionCS, 0);
}

void DitherLOD (float fade, float dither) 
{
	#if defined(LOD_FADE_CROSSFADE)
		clip(fade + (fade < 0.0 ? dither : -dither));
	#endif
}

void DitherLOD (float fade, float2 positionCS) 
{
	#if defined(LOD_FADE_CROSSFADE)
        float dither = InterleavedGradientNoise(positionCS, 0);
		clip(fade + (fade < 0.0 ? dither : -dither));
	#endif
}

void DitherClip(half alpha, half dither, half cutoff, half ditherCutoff)
{
    clip((alpha - cutoff) - (dither * ditherCutoff));
}

void AlphaTestAndFade(float2 positionCS, half alpha, half cutoff, half ditherCutoff)
{
	half texAlpha = 1, dither = 1;
#if _ALPHATEST_ON
	texAlpha = alpha;
	texAlpha += -cutoff;
#endif
#if _DITHER_FADE
	dither = GetDither(positionCS);
	dither += -ditherCutoff;
#endif
#if _ALPHATEST_ON || _DITHER_FADE
	clip(min(dither, texAlpha));
#endif
}

#endif