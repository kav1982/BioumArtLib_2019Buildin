#ifndef BIOUM_SCENE_WATER_PASS_INCLUDE
#define BIOUM_SCENE_WATER_PASS_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"
#include "../Shader/ShaderLibrary/LightingCommon.hlsl"
#include "../Shader/ShaderLibrary/Fog.hlsl"

sampler2D _NormalTex; 
sampler2D _ReflectionTex; 
CBUFFER_START(UnityPerMaterial)
half4 _WaveSpeed;
float4 _NormalTex_ST;
half _NormalScale, _EnvNormalScale;
half _SoftEdgeRange, _WaterColorRange;
half4 _WaterColorNear, _WaterColorFar;
half _Transparent;
half _FresnelPower;
half _Smoothness;

half _ThresholdSpeed;
half _ThresholdDensity;
half _MaxThreshold;
half _ThresholdFalloff;
half _FoamDensity;
half _FoamSpeed;
half _FoamEdgeRange;
half4 _FoamColor;
half _RealtimeReflectionDistort;
CBUFFER_END

struct Attributes
{
    float3 positionOS: POSITION;
    float2 texcoord: TEXCOORD0;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
    half4 color : COLOR;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float4 uv: TEXCOORD0;
    half4 positionWSAndFog: TEXCOORD1;
    half4 tangentWS: TEXCOORD2;
    half4 bitangentWS: TEXCOORD3;
    half4 normalWS: TEXCOORD4;
    half4 positionNDC: TEXCOORD5;
    half4 vColor : COLOR; 
};

Varyings WaterLitVert(Attributes input)
{
    Varyings output = (Varyings)0;

    VertexPositionInputs vertexPositions = GetVertexPositionInputs(input.positionOS);
    output.positionCS = vertexPositions.positionCS;
    output.positionWSAndFog.xyz = vertexPositions.positionWS;
    output.positionNDC = vertexPositions.positionNDC;
    output.positionNDC.z = -vertexPositions.positionVS.z;
    
    float4 uv = output.positionWSAndFog.xzxz * _NormalTex_ST.xyxy * float4(1,1,1.3,1.28);
    output.uv = uv + frac(_Time.x * _WaveSpeed); 

    half3 viewDirWS = _WorldSpaceCameraPos.xyz - vertexPositions.positionWS;
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.z);

#if !_ENABLE_DEPTH_TEXTURE
    half2 range = rcp(half2(_WaterColorRange, _SoftEdgeRange) * 0.1);
    range = smoothstep(0, 1, range * input.color.r);
    output.vColor = lerp(_WaterColorNear, _WaterColorFar, range.x);
    output.vColor.a = range.y;
#endif

    output.positionWSAndFog.w = ComputeBuiltInFogFactor(output.positionCS.z);

    return output;
}

half near(half delta, half value, half target)
{
    return (delta - min(delta, abs(value - target))) / delta;
}
half bin(half value)
{
    return log(1 + value * 1000.0);
}
half nearBin(half delta, half value, half target)
{
    return bin(near(delta, value, target));
}


half4 WaterLitFrag(Varyings input): SV_TARGET
{    
    half4 bump0 = tex2D(_NormalTex, input.uv.xy);
    half4 bump1 = tex2D(_NormalTex, input.uv.zw);

    //base color and alpha
    half3 color = 1; half alpha = 1; half edge = 1;
    half3 positionSS = input.positionNDC.xyz / input.positionNDC.w;

#if _ENABLE_DEPTH_TEXTURE
    half3 far = rcp(half3(_SoftEdgeRange, _WaterColorRange, _FoamEdgeRange));
    
    float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, positionSS.xy).r;
    half sceneZ = LinearEyeDepth(depth, _ZBufferParams);
    half thisZ = input.positionNDC.z;// LinearEyeDepth(positionNDC.z, _ZBufferParams);
    edge = sceneZ - thisZ;
    half3 fade = saturate (far * edge);
    edge = fade.z; //use for foam

    color = lerp(_WaterColorNear.rgb, _WaterColorFar.rgb, fade.y);
    alpha = fade.x;
#else
    color = input.vColor.rgb;
    edge = alpha = input.vColor.a;
#endif
    alpha *= _Transparent;
    half foamEdge = edge;//saturate(lerp(0, _FoamEdgeRange, edge));


    bump0.xyz = UnpackNormalScale(bump0, _NormalScale);
    bump1.xyz = UnpackNormalScale(bump1, _NormalScale);
    half3 normalTS = SafeNormalize(bump0.xyz + bump1.xyz);
    
    half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    half3 normalWS = SafeNormalize(mul(normalTS, TBN));
    half3 viewDirWS = SafeNormalize(half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w));

    Surface surface = (Surface)0;
    surface.color = half4(color, 1);
    surface.normal = normalWS;
    surface.viewDirection = viewDirWS;
    surface.metallic = 0;
    surface.occlusion = 1;
    surface.smoothness = _Smoothness;
    surface.position = input.positionWSAndFog.xyz;
    surface.fresnelStrength = 1;
    surface.specularTint = 1;

    //lighting
    Light light = GetLight(surface.position);
    BRDF brdf = GetBRDF(surface, alpha);
    half3 specColor = SpecularStrength(surface, brdf, light) * light.color * light.shadowAttenuation;
    
#if _REFLECTION_TEXTURE
    half2 reflectionUV = positionSS.xy;
    reflectionUV.xy += surface.normal.xz * _RealtimeReflectionDistort;
    half3 envReflection = tex2D(_ReflectionTex, reflectionUV);
#else
    half3 envNormal = lerp(input.normalWS.xyz, normalWS, _EnvNormalScale);
    surface.normal = envNormal;
    half3 envReflection = SampleEnvironment (surface, brdf);
#endif

    half fresnel = 1 - max(0, dot(surface.normal, surface.viewDirection));
    fresnel = PositivePow(fresnel, _FresnelPower);
    envReflection *= fresnel;

    //wave
#if _WAVE
    half threshold = positiveSin((surface.position.x + _Time.y * _ThresholdSpeed) * _ThresholdDensity);
    threshold *= _MaxThreshold * (_ThresholdFalloff - edge);
    half wave = positiveSin(edge * _FoamDensity - _Time.y * _FoamSpeed);
    wave = saturate(nearBin(threshold, wave, 1) + nearBin(threshold, edge, 0));
    half3 waveColor = wave * foamEdge * _FoamColor.rgb;
#endif

    //final color
    color += envReflection;
    color += specColor * foamEdge;   
    color *= alpha;

#if _WAVE
    color += waveColor;
#endif

    color = MixBuiltInFog(color, input.positionWSAndFog.w);
    color = max(0.001, color);
    
    return half4(color, alpha);
}

#endif // BIOUM_SCENE_WATER_PASS_INCLUDE