using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEngine.Rendering;

namespace BioumPostProcess
{
    public class ScreenBlur
    {
        int blurIterations, blurDownSample;
        float blurSize;
        private Material blurMat;

        private int[] blurShaderIDs;

        public ScreenBlur()
        {
            blurShaderIDs = new int[6];
            for(int i = 0; i < blurShaderIDs.Length; i++)
            {
                blurShaderIDs[i] = Shader.PropertyToID("_ScreenCaptureTex" + i);
            }
        }

        public void UpdateSettings(int blurIterations, int blurDownSample, float blurSize)
        {
            this.blurIterations = blurIterations;
            this.blurDownSample = blurDownSample;
            this.blurSize = blurSize;
        }

        public void Render(MaterialFactory materialFactory, Shader shader, bool useBlur, CommandBuffer cmd,
           RenderTargetIdentifier source, Material uberMat, int sourceWidth, int sourceHeight, RenderTextureFormat rtFormat)
        {
            if (!useBlur)
            {
                return;
            }

            blurMat = materialFactory.Get(shader);

            var lastDown = ShaderIDs.CameraColorTex;
            for (int i = 0; i < blurIterations; i++)
            {
                blurMat.SetFloat("_BlurSize", blurSize);
                int mipDown = blurShaderIDs[i];
                int textureWidth = Math.Max(sourceWidth >> Math.Min(i + 1, blurDownSample), 32);
                int textureHeight = Math.Max(sourceHeight >> Math.Min(i + 1, blurDownSample), 32);
                cmd.GetTemporaryRT(mipDown, textureWidth, textureHeight, 0, FilterMode.Bilinear, rtFormat);
                cmd.BlitColorWithFullScreenTriangle(lastDown, mipDown, blurMat, 0);
                cmd.ReleaseTemporaryRT(lastDown);
                lastDown = mipDown;
            }
            cmd.BlitColorWithFullScreenTriangle(lastDown, BuiltinRenderTextureType.CameraTarget, uberMat, 2);
            cmd.ReleaseTemporaryRT(lastDown);
        }
    }
}
