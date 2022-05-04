using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace BioumPostProcess
{ 
    public class Vignette
    {
         public void Render(bool useVignette, Material uberMat, float intensity, float smoothness, float roundness, bool rounded)
        {
            // x: intensity, y: smoothness, z: roundness, w: rounded
            if (!useVignette || intensity <= 0.01f)
            {
                uberMat.DisableKeyword("VIGNETTE");
                return;
            }

            uberMat.EnableKeyword("VIGNETTE");
            float realRoundness = (1f - roundness) * 6f + roundness;
            uberMat.SetVector(ShaderIDs.vignetteParams, new Vector4(intensity * 3f, smoothness * 5f, roundness, rounded ? 1f : 0f));
        }
    }
}
