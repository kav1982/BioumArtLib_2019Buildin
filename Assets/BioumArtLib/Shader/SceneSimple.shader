Shader "Custom/SceneSample"
{
	Properties{
		_Diffuse("Diffuse Color",Color) = (1,0,1,1)
		_Specular("Specular Color",Color) = (1,0,1,1)
		_Gloss("Gloss",Range(8,200)) = 10
	}
	SubShader{
		Pass{
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#include "Lighting.cginc"
			#pragma vertex vert
			#pragma fragment frag
			fixed4 _Diffuse;
			half _Gloss;
			fixed4 _Specular;
 
	//application to vertex
		struct a2v
		{
			float4 vertex:POSITION;
			float3 normal:NORMAL;
		};
		struct v2f
		{
			float4 position:sv_position;
			fixed3 worldNormalDir : Color0;
		};
			
		v2f vert(a2v v)
		{
			v2f f;
			f.position = UnityObjectToClipPos(v.vertex);
			f.worldNormalDir = mul(v.normal, (float3x3)unity_WorldToObject);
			return f;
		}
		fixed4 frag(v2f f) : SV_Target
		{
			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
			fixed3 normalDir = normalize(f.worldNormalDir);
			fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
			fixed3 diffuse = _LightColor0.rgb * (dot(lightDir, normalDir)*0.5+0.5) * _Diffuse.rgb;
			fixed3 reflectDir = normalize(reflect(-lightDir,normalDir));//计算反射光
			fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(f.worldNormalDir, unity_WorldToObject).xyz);//视角方向
			fixed3 specular = _Specular.rgb * pow(max(0,dot(viewDir, reflectDir)),_Gloss);//Blinn光照公式
			fixed3 tempColor = diffuse + ambient + specular;//漫反射+环境光+高光反射
			return fixed4(tempColor,1);
		}
			ENDCG
	}
}
	Fallback "Diffuse"
}
