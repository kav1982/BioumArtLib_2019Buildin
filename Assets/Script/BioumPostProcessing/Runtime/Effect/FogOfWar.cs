using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEngine.Rendering;

namespace BioumPostProcess
{ 
    public class FogOfWar
    {
        Color fogColor;
        Vector4 fogParam = new Vector4();
        Material blurMat;

        public void UpdateSettings(float fogStartHeight, float fogEndHeight, int fogBlurNum, Color fogColor)
        {
            this.fogColor = fogColor;
            fogParam.x = fogStartHeight;
            fogParam.y = fogEndHeight;
            fogParam.z = fogBlurNum;
        }

        public void Render(MaterialFactory materialFactory, Shader shader, bool useFogOfWar, CommandBuffer cmd,
            Material uberMat, RenderTextureFormat rtFormat, Texture2D fogMaskTex2D, Texture2D fogDistortTex2D, Texture2D fogUVTex2D)
        {
            if (!useFogOfWar)
            {
                uberMat.DisableKeyword("FOGOFWAR");
                return;
            }
            uberMat.EnableKeyword("FOGOFWAR");
            uberMat.SetTexture(ShaderIDs.FogOfWarDistortTex, fogDistortTex2D);
            uberMat.SetTexture(ShaderIDs.FogOfWarUVTex, fogUVTex2D);
            uberMat.SetColor(ShaderIDs.FogOfWarColor, fogColor);
            uberMat.SetVector(ShaderIDs.FogOfWarParmas, fogParam);

            blurMat = materialFactory.Get(shader);

            if (fogMaskTex2D)
            {
                int textureWidth = fogMaskTex2D.width;
                int textureHeight = fogMaskTex2D.height;
                if(fogParam.z > 0)
                {
                    RenderTexture rt = RenderTexture.GetTemporary(textureWidth, textureHeight, 0);
                    Graphics.Blit(fogMaskTex2D, rt, blurMat);
                    for (int i = 0; i < fogParam.z; i++)
                    {
                        textureWidth = Math.Min(textureWidth << 1, 512);
                        textureHeight = Math.Min(textureHeight << 1, 512);
                        RenderTexture rt2 = RenderTexture.GetTemporary(textureWidth, textureHeight, 0);
                        Graphics.Blit(rt, rt2, blurMat);
                        RenderTexture.ReleaseTemporary(rt);
                        rt = rt2;
                    }
                    uberMat.SetTexture(ShaderIDs.FogOfWarMaskTex, rt);
                    RenderTexture.ReleaseTemporary(rt);
                }
                else
                {
                    uberMat.SetTexture(ShaderIDs.FogOfWarMaskTex, fogMaskTex2D);
                }
            }
        }
    }
}
