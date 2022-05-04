
Shader "Unlit/SSQuadShadow"
{
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
    SubShader{
        Tags { "RenderType" = "Opaque" }
        LOD 200

        Pass{
            CGPROGRAM

            #include "UnityCG.cginc"
            #pragma vertex vert_img
            #pragma fragment frag

            sampler2D  _MainTex;
            sampler2D _CameraDepthTexture;
            uniform	sampler2D _TestQTreeTex;
            uniform int _TestQTreeWidth;
            float4 GetWorldPositionFromDepthValue(float2 uv, float linearDepth)
            {
                float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * linearDepth;

                // unity_CameraProjection._m11 = near / t，其中t是视锥体near平面的高度的一半。
                // 投影矩阵的推导见：http://www.songho.ca/opengl/gl_projectionmatrix.html。
                // 这里求的height和width是坐标点所在的视锥体截面（与摄像机方向垂直）的高和宽，并且
                // 假设相机投影区域的宽高比和屏幕一致。
                float height = 2 * camPosZ / unity_CameraProjection._m11;
                float width = _ScreenParams.x / _ScreenParams.y * height;

                float camPosX = width * uv.x - width / 2;
                float camPosY = height * uv.y - height / 2;
                float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);
                return mul(unity_CameraToWorld, camPos);
            }
            int4 getTreeValue(int index) {

                return	tex2D(_TestQTreeTex, half2(index % _TestQTreeWidth, index / _TestQTreeWidth)
                / (half)max(_TestQTreeWidth, 1));
            }
            fixed shadowValue(float3 wpos) 
            {
                int x =  wpos.x * 10 + 0.5;
                int z =  wpos.z * 10 + 0.5;
                int index = 0;
                int size = 1024;
                [unroll(20)]
                while (1) {
                    int4 node = getTreeValue(index);
                    int flag = node.a;
                    
                    if (node.z < 0)return 1-flag ;
                    if (size == 1)return 1;
                    int childIndex = 0;

                    if (x > node.x+size/2)
                    {
                        childIndex++;
                    }
                    if (z > node.y+size/2)
                    {
                        childIndex += 2;
                    }
                    index = node.z + childIndex;
                    size /= 2;
                    
                }

                return 1;
            }
            float4 frag(v2f_img o) : COLOR
            {
                float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, o.uv);
                // 注意：经过投影变换之后的深度和相机空间里的z已经不是线性关系。所以要先将其转换为线性深度。
                // 见：https://developer.nvidia.com/content/depth-precision-visualized
                float linearDepth = Linear01Depth(rawDepth);
                float3 worldpos = GetWorldPositionFromDepthValue(o.uv, linearDepth);
                float atten = 1;
                
                atten =lerp( shadowValue(worldpos + half3(0, 0, 0.2)),1,saturate( worldpos.y*100));
                
                return atten;
                //return float4(worldpos.xyz / 255.0 , 1.0);  // 除以255以便显示颜色，测试用。
            }
            ENDCG
        }
        Pass{
            CGPROGRAM
            
            
            
            

            #include "UnityCG.cginc"
            #pragma vertex vert_img
            #pragma fragment frag
            sampler2D  _MainTex;
            static   float2 poisson[12] = { float2(-0.326212f, -0.40581f),
                float2(-0.840144f, -0.07358f),
                float2(-0.695914f, 0.457137f),
                float2(-0.203345f, 0.620716f),
                float2(0.96234f, -0.194983f),
                float2(0.473434f, -0.480026f),
                float2(0.519456f, 0.767022f),
                float2(0.185461f, -0.893124f),
                float2(0.507431f, 0.064425f),
                float2(0.89642f, 0.412458f),
                float2(-0.32194f, -0.932615f),
            float2(-0.791559f, -0.59771f) };
            
            sampler2D  _TestQTreeMaskTex;
            float4 _TestQTreeMaskTex_TexelSize;
            float4 frag(v2f_img o) : COLOR
            {
                float4 col = tex2D(_MainTex, o.uv);
                float atten = tex2D(_TestQTreeMaskTex, o.uv);
                for (int k = 0; k < 12; k++) {
                    atten += tex2D(_TestQTreeMaskTex, o.uv + poisson[k] * _TestQTreeMaskTex_TexelSize.xy*6);
                }
                return col * (pow( atten/13,3)+0.3)/1.3 ;
            }
            ENDCG
        }
    }
}