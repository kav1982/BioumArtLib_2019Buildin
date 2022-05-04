Shader "Hidden/Bioum/ScreenBlur" {
    HLSLINCLUDE

        #include "ShaderLibrary/StdLib.hlsl"
        #include "ShaderLibrary/Colors.hlsl"
        #include "ShaderLibrary/Sampling.hlsl"

        TEXTURE2D_SAMPLER2D(_CameraColorTex, sampler_CameraColorTex);

        float4 _CameraColorTex_TexelSize;

        static const half GaussianBlurKernel3x3[9] = 
        {
            0.077847, 0.123317, 0.077847, 
            0.123317,   0.195346,   0.123317, 
            0.077847,   0.123317,   0.077847,
        };
        static const half2 GaussianBlurTexelOffsets3x3[9] =
        {
            half2(-1,1), half2(0, 1), half2(1,1),
            half2(-1,0), half2(0, 0), half2(1,0),
            half2(-1,-1), half2(0, -1), half2(1,-1),
        };
        half _BlurSize;

        half4 FragBlur(VaryingsDefault i) : SV_Target
        {
            half4 color = half4(0,0,0,0);
            for (int j = 0; j < 9; j++)
            {
                color += SAMPLE_TEXTURE2D(_CameraColorTex, sampler_CameraColorTex, i.texcoord + GaussianBlurTexelOffsets3x3[j] * _CameraColorTex_TexelSize.xy * _BlurSize) * GaussianBlurKernel3x3[j];
            }
            return color;
        }

    ENDHLSL
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDefault
                #pragma fragment FragBlur

            ENDHLSL
        }
    }
}
