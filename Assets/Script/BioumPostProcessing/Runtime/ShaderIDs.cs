using UnityEngine;

namespace BioumPostProcess
{
    static class ShaderIDs
    {
        internal static readonly int CameraColorBuffer = Shader.PropertyToID("_CameraColorBuffer");
        /// <summary>
        /// _CameraColorTex
        /// </summary>
        internal static readonly int CameraColorTex = Shader.PropertyToID("_CameraColorTex");
        internal static readonly int CameraDepthBuffer = Shader.PropertyToID("_CameraDepthBuffer");
        /// <summary>
        /// _CameraDepthTex
        /// </summary>
        internal static readonly int CameraDepthTex = Shader.PropertyToID("_CameraDepthTex");

        internal static readonly int FXAASourceTex = Shader.PropertyToID("_FXAASourceTex");
        internal static readonly int UseFXAA = Shader.PropertyToID("_UseFXAA");

        internal static readonly int BloomTex = Shader.PropertyToID("_BloomTex");
        internal static readonly int Threshold = Shader.PropertyToID("_Threshold");
        internal static readonly int BloomIntensity = Shader.PropertyToID("_BloomIntensity");
        internal static readonly int PostExposure = Shader.PropertyToID("_PostExposure");
        internal static readonly int SampleScale = Shader.PropertyToID("_SampleScale");

        internal static readonly int Lut2D = Shader.PropertyToID("_Lut2D");
        internal static readonly int Lut2D_Params = Shader.PropertyToID("_Lut2D_Params");

        internal static readonly int DistortParams = Shader.PropertyToID("_DistortParams");
        internal static readonly int DistortTex = Shader.PropertyToID("_DistortTex");

        internal static readonly int vignetteParams = Shader.PropertyToID("_VignetteParams");

        internal static readonly int FogOfWarMaskTex = Shader.PropertyToID("_FOWMaskTex");
        internal static readonly int FogOfWarDistortTex = Shader.PropertyToID("_FOWDistortTex");
        internal static readonly int FogOfWarUVTex = Shader.PropertyToID("_FOWUVTex");
        internal static readonly int FogOfWarColor = Shader.PropertyToID("_FOWColor");
        internal static readonly int FogOfWarParmas = Shader.PropertyToID("_FOWParams");

        internal static readonly int FilmSlope = Shader.PropertyToID("_FilmSlope");
        internal static readonly int FilmToe = Shader.PropertyToID("_FilmToe");
        internal static readonly int FilmShoulder = Shader.PropertyToID("_FilmShoulder");
        internal static readonly int FilmBlackClip = Shader.PropertyToID("_FilmBlackClip");
        internal static readonly int FilmWhiteClip = Shader.PropertyToID("_FilmWhiteClip");


    }
}