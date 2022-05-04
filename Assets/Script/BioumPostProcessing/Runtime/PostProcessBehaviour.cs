//using Plugins.Base;
using UnityEngine;
using UnityEngine.Rendering;

namespace BioumPostProcess
{
    [ExecuteAlways, DisallowMultipleComponent, RequireComponent(typeof(Camera))]
    public class PostProcessBehaviour : MonoBehaviour
    {
        public float pixelScale = 1f;   //分辨率缩放比例
        float m_pixelScale;
        Camera m_Camera;
        int m_Width, m_Height;
        int m_RealWidth, m_RealHeight;
        CommandBuffer beforImageEffect;
        CommandBuffer afterOpaque;
        RenderTexture cameraColorTarget;
        RenderTexture cameraDepthTarget;
        Material uberMat, fxaaMat, bloomMat;
        MaterialFactory materialFactory;

        private int depthBit = 24;
        RenderTextureFormat depthTextureFormat = RenderTextureFormat.ARGB32;
        bool useDepthTexture = false;
        public bool UseDepthTexture
        {
            get { return useDepthTexture; }
            set
            {
                if (useDepthTexture != value)
                {
                    useDepthTexture = value;
                    InitCameraColorTarget(useDepthTexture ? 0 : 24);
                    InitCameraDepthTarget();
                }
            }
        }

        public bool UseColorTexture { get; set; }

        public bool UseFXAA { get; set; }

        public bool UseBloom { get; set; }
        Bloom bloom;
        RenderTextureFormat hdrFormat = RenderTextureFormat.ARGB32;
        [HideInInspector]
        public float BloomIntensity = 1, BloomThreshold = 1, BloomDiffusion = 5, BloomSoftKnee = 0.5f;

        public bool UseToneMapping { get; set; }
        public enum ToneMappingMode { ACES, Filmic, }
        [HideInInspector]
        public float FilmSlope = 0.88f, FilmToe = 0.55f, FilmShoulder = 0.26f, FilmBlackClip = 0.0f, FilmWhiteClip = 0.04f;

        [HideInInspector]
        public ToneMappingMode toneMappingMode = ToneMappingMode.ACES;

        ColorGrading colorGrading;
        public bool UseColorGrading { get; set; }

        [HideInInspector]
        public float postExposure = 1;
        [HideInInspector]
        public Texture2D LutTex2D;

        ScreenDistort screenDistort;
        public bool UseScreenDistort { get; set; }

        [HideInInspector]
        public float DistortIntensity = 0.1f, DistortSpeedX = 0, DistortSpeedY = 0.1f, DistortDensity = 1;


        Vignette vignette;
        public bool UseVignette { get; set; }
        [HideInInspector]
        public float VignetteIntensity = 0.1f, VignetteSmoothness = 0.1f, VignetteRoundness = 0.1f;
        [HideInInspector]
        public bool VignetteRounded = true;

        FogOfWar fogOfWar;

        public bool UseFogOfWar { get; set; }
        [HideInInspector]
        public float FogStartHeight = 0f, FogEndHeight = 1f;
        [HideInInspector]
        public Color FogColor = Color.black;
        [HideInInspector]
        public Texture2D FogMaskTex2D;
        [HideInInspector]
        public Texture2D FogDistortTex2D;
        [HideInInspector]
        public Texture2D FogUVTex2D;
        [HideInInspector]
        public int FogBlurNum = 0;

        ScreenBlur screenBlur;
        public bool UseBlur { get; set; }
        [HideInInspector]
        public float BlurSize = 1;
        public int BlurIterations = 1, BlurDownSample = 0;

        public bool UseCapture = false;
        private bool isCaptured = false;
        private RenderTexture captureTexture = null;
        private int captureCount = 0;

        [HideInInspector]
        public PostProcessResources Resource;

        private void OnEnable()
        {
            if (materialFactory == null)
                materialFactory = new MaterialFactory();

            if (bloom == null)
                bloom = new Bloom();

            if (colorGrading == null)
                colorGrading = new ColorGrading();

            if (screenDistort == null)
                screenDistort = new ScreenDistort();

            if (vignette == null)
                vignette = new Vignette();

            if (fogOfWar == null)
                fogOfWar = new FogOfWar();

            if (screenBlur == null)
                screenBlur = new ScreenBlur();

            Init();
        }

        private void OnDisable()
        {
            CleanUp();
        }

        private void LateUpdate()
        {
           
        }

        private void OnPreCull()
        {
            if (m_Width != m_Camera.pixelWidth || m_Height != m_Camera.pixelHeight || m_pixelScale != pixelScale)
            {
                SetResolution();
                InitCameraColorTarget(useDepthTexture ? 0 : 24);
                InitCameraDepthTarget();
            }
            RuntimeUtilities.UpdateMat(Resource.copyColor, Resource.copyDepth);
        }

        private void OnPreRender()
        {
            if (UseCapture)
            {
                if (isCaptured)
                {
                    afterOpaque.Clear();
                    beforImageEffect.Clear();
                    beforImageEffect.BlitColorWithFullScreenTriangle(captureTexture, BuiltinRenderTextureType.CameraTarget, uberMat, 2);
                    return;
                }
            }
            else
            {
                if(captureTexture != null)
                {
                    RenderTexture.ReleaseTemporary(captureTexture);
                    captureTexture = null;
                }
                isCaptured = false;
                captureCount = 0;
            }
            SetRenderTarget();
            BuildCommandBuffer();
        }

        
        private void OnPostRender()
        {
            if(UseCapture && !isCaptured)
            {
                if (captureTexture == null && captureCount > 2)
                {
                    captureTexture = RenderTexture.GetTemporary(m_RealWidth, m_RealHeight, 24, RenderTextureFormat.ARGB32);
                    Graphics.Blit(Shader.GetGlobalTexture(ShaderIDs.CameraColorTex), captureTexture);
                    isCaptured = true;
                }
            }
            m_Camera.targetTexture = null;
        }

        void Init()
        {
            m_Camera = GetComponent<Camera>();
            m_Camera.allowMSAA = false; //会和后处理冲突
            SetResolution();

            if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf))
            {
                hdrFormat = RenderTextureFormat.ARGBHalf;
            }
            else if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGB2101010))
            {
                hdrFormat = RenderTextureFormat.ARGB2101010;
            }


            if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RHalf))
            {
                depthTextureFormat = RenderTextureFormat.RHalf;
                depthBit = 0;
            }
            else if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RFloat))
            {
                depthTextureFormat = RenderTextureFormat.RFloat;
                depthBit = 0;
            }
            else if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf))
            {
                depthTextureFormat = RenderTextureFormat.ARGBHalf;
                depthBit = 24;
            }
            //BaseLogger.Info("PostProcess DepthTextureFormat:{0}", depthTextureFormat);

            InitCameraColorTarget(24);
            InitCameraDepthTarget();

            beforImageEffect = new CommandBuffer() { name = "PostProcess Before ImageEffect" };
            m_Camera.AddCommandBuffer(CameraEvent.BeforeImageEffects, beforImageEffect);

            afterOpaque = new CommandBuffer() { name = "PostProcess After Opaque" };
            m_Camera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, afterOpaque);

            RuntimeUtilities.InitializeStatic();
        }

        void SetResolution()
        {
            m_Width = m_Camera.pixelWidth;
            m_Height = m_Camera.pixelHeight;
            m_pixelScale = pixelScale;
            m_RealWidth = Mathf.FloorToInt(m_Width * m_pixelScale);
            m_RealHeight = Mathf.FloorToInt(m_Height * m_pixelScale);
            //将最大分辨率设置为1080P
            if (m_RealHeight > 1080)
            {
                m_RealHeight = 1080;
                m_RealWidth = 1080 * m_Width / m_Height;
            }
            if(m_RealWidth > 1920)
            {
                m_RealWidth = 1920;
                m_RealHeight = 1920 * m_Height / m_Width;
            }
        }

        void SetRenderTarget()
        {
            if (useDepthTexture)
            {
                m_Camera.SetTargetBuffers(cameraColorTarget.colorBuffer, cameraDepthTarget.depthBuffer);
            }
            else
            {
                m_Camera.SetTargetBuffers(cameraColorTarget.colorBuffer, cameraColorTarget.depthBuffer);
            }
        }
        void InitCameraColorTarget(int depthBit)
        {
            RuntimeUtilities.Destroy(cameraColorTarget);

            cameraColorTarget = new RenderTexture(m_RealWidth, m_RealHeight, depthBit, hdrFormat)
            {
                name = "Post Process Camera Color Target",
                filterMode = FilterMode.Bilinear,
            };
            cameraColorTarget.Create();
        }
        void InitCameraDepthTarget()
        {
            RuntimeUtilities.Destroy(cameraDepthTarget);

            if (!useDepthTexture)
            {
                return;
            }

            cameraDepthTarget = new RenderTexture(m_RealWidth, m_RealHeight, 24, RenderTextureFormat.Depth)
            {
                name = "Post Process Camera Depth Target",
                filterMode = FilterMode.Point,
            };
            cameraDepthTarget.Create();
        }

        void CleanUp()
        {
            if (beforImageEffect != null)
                m_Camera.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, beforImageEffect);
            if (afterOpaque != null)
                m_Camera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, afterOpaque);

            RuntimeUtilities.Destroy(cameraColorTarget);
            RuntimeUtilities.Destroy(cameraDepthTarget);

            RuntimeUtilities.Destroy(RuntimeUtilities.copyColorMat);
            RuntimeUtilities.Destroy(RuntimeUtilities.copyDepthMat);
            if(materialFactory != null)
            {
                materialFactory.CleanUp();
            }
            if (captureTexture != null)
            {
                RenderTexture.ReleaseTemporary(captureTexture);
                captureTexture = null;
            }
            isCaptured = false;
            captureCount = 0;
        }

        //后处理CommandBuffer
        void BuildCommandBuffer()
        {
            afterOpaque.Clear();
            //抓取深度图
            if (useDepthTexture)
            {
                afterOpaque.BeginSample("Copy Depth");
                afterOpaque.GetTemporaryRT(ShaderIDs.CameraDepthTex, m_RealWidth, m_RealHeight, depthBit, FilterMode.Point, depthTextureFormat);

                afterOpaque.CopyDepthTexture(cameraDepthTarget.depthBuffer, ShaderIDs.CameraDepthTex, RuntimeUtilities.copyDepthMat);
                afterOpaque.SetGlobalTexture(ShaderIDs.CameraDepthTex, ShaderIDs.CameraDepthTex);

                afterOpaque.ReleaseTemporaryRT(ShaderIDs.CameraDepthTex);
                afterOpaque.EndSample("Copy Depth");
            }
            //抓取颜色图
            if (UseColorTexture)
            {
                afterOpaque.BeginSample("Copy Color");
                afterOpaque.GetTemporaryRT(ShaderIDs.CameraColorTex, m_RealWidth, m_RealHeight, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

                afterOpaque.CopyColorTexture(cameraColorTarget.colorBuffer, ShaderIDs.CameraColorTex, RuntimeUtilities.copyColorMat);
                afterOpaque.SetGlobalTexture(ShaderIDs.CameraColorTex, ShaderIDs.CameraColorTex);

                afterOpaque.ReleaseTemporaryRT(ShaderIDs.CameraColorTex);
                afterOpaque.EndSample("Copy Color");
            }

            afterOpaque.BeginSample("bloom");
            uberMat = materialFactory.Get(Resource.uber);
            bloom.UpdateSettings(BloomIntensity, BloomThreshold, BloomDiffusion, BloomSoftKnee);
            bloom.Render(materialFactory, Resource.bloom, UseBloom, afterOpaque, cameraColorTarget, uberMat, m_RealWidth, m_RealHeight, hdrFormat);
            afterOpaque.EndSample("bloom");


            //后处理
            beforImageEffect.Clear();
            //uberMat = materialFactory.Get(Resource.uber);
            //bloom.UpdateSettings(BloomIntensity, BloomThreshold, BloomDiffusion, BloomSoftKnee);
            //bloom.Render(materialFactory, Resource.bloom, UseBloom, beforImageEffect, cameraColorTarget, uberMat, m_RealWidth, m_RealHeight, hdrFormat);
            colorGrading.Render(UseColorGrading, uberMat, LutTex2D, postExposure);
            screenDistort.Render(UseScreenDistort, uberMat, DistortIntensity, DistortSpeedX, DistortSpeedY, DistortDensity, Resource.distortTex);
            vignette.Render(UseVignette, uberMat, VignetteIntensity, VignetteSmoothness, VignetteRoundness, VignetteRounded);
            fogOfWar.UpdateSettings(FogStartHeight, FogEndHeight, FogBlurNum, FogColor);
            fogOfWar.Render(materialFactory, Resource.fogBlur, UseFogOfWar, beforImageEffect, uberMat, hdrFormat, FogMaskTex2D, FogDistortTex2D, FogUVTex2D);
            screenBlur.UpdateSettings(BlurIterations, BlurDownSample, BlurSize);

            //混合后处理结果
            beforImageEffect.BeginSample("Uber");
            if (UseToneMapping)
            {
                if (toneMappingMode == ToneMappingMode.ACES)
                {
                    uberMat.EnableKeyword("ACES_TONEMAPPING");
                    uberMat.DisableKeyword("FIlMIC_TONEMAPPING");
                }
                else
                {
                    uberMat.EnableKeyword("FIlMIC_TONEMAPPING");
                    uberMat.DisableKeyword("ACES_TONEMAPPING");
                    uberMat.SetFloat(ShaderIDs.FilmSlope, FilmSlope);
                    uberMat.SetFloat(ShaderIDs.FilmToe, FilmToe);
                    uberMat.SetFloat(ShaderIDs.FilmShoulder, FilmShoulder);
                    uberMat.SetFloat(ShaderIDs.FilmBlackClip, FilmBlackClip);
                    uberMat.SetFloat(ShaderIDs.FilmWhiteClip, FilmWhiteClip);
                }
            }
            else
            {
                uberMat.DisableKeyword("ACES_TONEMAPPING");
                uberMat.DisableKeyword("FIlMIC_TONEMAPPING");
            }

            //抗锯齿
            if (UseFXAA)
            {
                uberMat.SetFloat(ShaderIDs.UseFXAA, 1);
                fxaaMat = materialFactory.Get(Resource.fxaa);
                beforImageEffect.GetTemporaryRT(ShaderIDs.FXAASourceTex, m_RealWidth, m_RealHeight, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                beforImageEffect.BlitColorWithFullScreenTriangle(cameraColorTarget, ShaderIDs.FXAASourceTex, uberMat, 1);
                beforImageEffect.EndSample("Uber");

                beforImageEffect.BeginSample("FXAA");
                beforImageEffect.BlitColorWithFullScreenTriangle(ShaderIDs.FXAASourceTex, BuiltinRenderTextureType.CameraTarget, fxaaMat, 0);
                beforImageEffect.ReleaseTemporaryRT(ShaderIDs.FXAASourceTex);
                beforImageEffect.EndSample("FXAA");
            }
            else
            {
                uberMat.SetFloat(ShaderIDs.UseFXAA, 0);
                beforImageEffect.BlitColorWithFullScreenTriangle(cameraColorTarget, BuiltinRenderTextureType.CameraTarget, uberMat, 0);
                beforImageEffect.EndSample("Uber");
            }

            screenBlur.Render(materialFactory, Resource.screenBlur, UseBlur, beforImageEffect, cameraColorTarget, uberMat, m_RealWidth, m_RealHeight, hdrFormat);
            captureCount++;
        }
    }
}