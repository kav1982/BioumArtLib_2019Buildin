Shader "Hidden/BioumPost/Uber"
{
    HLSLINCLUDE
    
    //#pragma multi_compile __ BLOOM
    #pragma multi_compile __ COLOR_GRADING_LDR_2D
    #pragma multi_compile __ SCREEN_DISTORT
    #pragma multi_compile __ ACES_TONEMAPPING FIlMIC_TONEMAPPING //NEUTRAL_TONEMAPPING 
	#pragma multi_compile __ VIGNETTE
    #pragma multi_compile __ FOGOFWAR
    
    #include "ShaderLibrary/StdLib.hlsl"
    #include "ShaderLibrary/Colors.hlsl"
    #include "ShaderLibrary/Sampling.hlsl"
	#include "ShaderLibrary/FilmicTonemapper.hlsl"
    
    TEXTURE2D_SAMPLER2D(_CameraColorTex, sampler_CameraColorTex);
    TEXTURE2D_SAMPLER2D(_CameraDepthTex, sampler_CameraDepthTex);
    bool _UseFXAA;
    half _PostExposure;
	half4 _MainColor;
    
    
    
    #if COLOR_GRADING_LDR_2D
        TEXTURE2D_SAMPLER2D(_Lut2D, sampler_Lut2D);
        half4 _Lut2D_Params;
    #endif
    
    #if SCREEN_DISTORT
        TEXTURE2D_SAMPLER2D(_DistortTex, sampler_DistortTex);
        half4 _DistortParams;
    #endif

	#if VIGNETTE
		// Vignette
		half4 _VignetteParams; // x: intensity, y: smoothness, z: roundness, w: rounded
	#endif

    #if FOGOFWAR
        TEXTURE2D_SAMPLER2D(_FOWDistortTex, sampler_FOWDistortTex);
        TEXTURE2D_SAMPLER2D(_FOWUVTex, sampler_FOWUVTex);
        TEXTURE2D_SAMPLER2D(_FOWMaskTex, sampler_FOWMaskTex);
        half4 _FOWMaskTex_TexelSize;
        half3 _FOWColor;
        half4 _FOWMaskParams; // x: start pos x, y: start pos y, z: fog width, w: fog height
        half4 _FOWParams;   //x: start height y: end height z : blur sample count
		half2 _DistortUVAni;
    #endif
    
    half4 FragUber(VaryingsDefault i): SV_Target
    {
        half2 uv = i.texcoord;
        
        #if SCREEN_DISTORT
            half2 distortUV = frac((uv - _Time.y * _DistortParams.xy) * _DistortParams.w);
            half distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, distortUV).x;
            distortTex -= 0.5;
            
            uv += distortTex * _DistortParams.z;
        #endif
        
        half4 color = SAMPLE_TEXTURE2D(_CameraColorTex, sampler_CameraColorTex, uv);
        #if UNITY_COLORSPACE_GAMMA
            color = SRGBToLinear(color);
        #endif

        color *= _PostExposure;
        
        

		#if VIGNETTE
			half2 d = abs(uv - 0.5.xx) * _VignetteParams.x;
			d.x *= lerp(1.0, _ScreenParams.x / _ScreenParams.y, _VignetteParams.w);
			d = pow(saturate(d), _VignetteParams.z); // Roundness
			half vfactor = pow(saturate(1.0 - dot(d, d)), _VignetteParams.y);
			color.rgb *= lerp((0.0).xxx, (1.0).xxx, vfactor);
			color.a = lerp(1.0, color.a, vfactor);
		#endif

        #if FOGOFWAR
			//float Eyedepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTex, sampler_CameraDepthTex, uv));		
			float Eyedepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTex, sampler_CameraDepthTex, uv));
			half4 fogWorldPos = GetWorldPosFromEyeDepth(uv, Eyedepth);			
            half2 uvFOW = half2((fogWorldPos.x-_FOWMaskParams.x) / _FOWMaskParams.z, (fogWorldPos.z-_FOWMaskParams.y) / _FOWMaskParams.w);									
			half2 uvDistortFOW = uvFOW - half2(_Time.x, _Time.x) * 3;
            half4 fogMask = SAMPLE_TEXTURE2D(_FOWMaskTex, sampler_FOWMaskTex, uvFOW ).r;			
			half mask = smoothstep(0, 0.5, fogMask);
			//half fogMaskout = smoothstep(0, 1, fogMask);
			
			//扭曲
            half2 disp = SAMPLE_TEXTURE2D(_FOWDistortTex, sampler_FOWDistortTex, uvFOW).xy;
            disp = (disp * 2 - 1) * 0.4;

            float heightNoise = disp * 0.01;
            float heightFactor = (fogWorldPos.y - _FOWParams.x - heightNoise) / (_FOWParams.y - _FOWParams.x);
            heightFactor = saturate(heightFactor);

			//偏移+扭曲
			half3 fowUVColor = SAMPLE_TEXTURE2D(_FOWUVTex, sampler_FOWUVTex, uvFOW * 6 + uvDistortFOW + disp);
			//fowUVColor = lerp(fowUVColor + 1, fowUVColor - 1, fogMask);
			fowUVColor = lerp(fowUVColor, 0, mask);
			//fowUVColor *= fowUVColor;

			//分层迷雾+云
			half3 fogcolor = lerp(_FOWColor, color.rgb, lerp(heightFactor, 1, fogMask));
			half3 cloudcolor = fowUVColor * half3(0.2,0.4,0.8);
			color.rgb = lerp(fogcolor, cloudcolor, fowUVColor);
			//color.rgb = fogcolor;	
        #endif
        
        #if ACES_TONEMAPPING
            color.rgb = unity_to_ACES(color.rgb);
            color.rgb = AcesTonemap(color.rgb);
        //#elif NEUTRAL_TONEMAPPING
        //    color.rgb = NeutralTonemap(color.rgb);
		#elif FIlMIC_TONEMAPPING			
			color.rgb = FilmicTonemap(color.rgb);			
        #endif
        
        #if UNITY_COLORSPACE_GAMMA
            color = LinearToSRGB(color);
        #endif
        
        #if COLOR_GRADING_LDR_2D
            color = saturate(color);
            color.rgb = ApplyLut2D(TEXTURE2D_PARAM(_Lut2D, sampler_Lut2D), color.rgb, _Lut2D_Params);
        #endif
        
        UNITY_BRANCH
        if (_UseFXAA)
        {
            // Put saturated luma in alpha for FXAA - higher quality than "green as luma" and
            // necessary as RGB values will potentially still be HDR for the FXAA pass
            color.a = Luminance(saturate(color));
        }
        
        return color;
    }

    half4 FragUberCapture(VaryingsDefault i): SV_Target
    {
        half2 uv = i.texcoord;
        half4 color = half4(0,0,0,0);
        color = SAMPLE_TEXTURE2D(_CameraColorTex, sampler_CameraColorTex, uv);
        return color;
    }
    ENDHLSL
    
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex VertUVTransform
            #pragma fragment FragUber
            ENDHLSL
            
        }
        
        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex VertDefault
            #pragma fragment FragUber
            ENDHLSL
        }

        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex VertUVTransform
            #pragma fragment FragUberCapture
            ENDHLSL
        }
    }
}
