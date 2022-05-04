#ifndef BIOUM_OUTLINE_PASS_INCLUDE
#define BIOUM_OUTLINE_PASS_INCLUDE


//-----------------------------------ForwardBase---------------------------//
struct BaseAttributes
{
    float3 positionOS: POSITION;
    half3 normalOS: NORMAL;
    half2 texcoord: TEXCOORD0;
};

struct BaseVaryings
{
    float4 positionCS: SV_POSITION;
    half4 uv: TEXCOORD0;
};

half _OutlineScale;
half4 _OutlineColor;

BaseVaryings ForwardBaseVert(BaseAttributes input)
{
    BaseVaryings output = (BaseVaryings)0;
    
    input.positionOS += input.normalOS * _OutlineScale;
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(positionWS);
    
    output.uv.xy = GetBaseUV(input.texcoord);
    
    return output;
}

half4 ForwardBaseFrag(BaseVaryings input): SV_TARGET
{
    half4 color = sampleBaseMap(input.uv.xy, false);

#if _ALPHATEST_ON
    clip(color.a - _Cutoff);
#endif

    color.rgb *= _OutlineColor.rgb;
    //color.a *= _Transparent;

    return half4(color);
}
//-----------------------------------ForwardBase---------------------------//

#endif // BIOUM_OUTLINE_PASS_INCLUDE