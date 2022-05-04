using BioumPostProcess;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
namespace BioumPostProcess
{
    [DisallowMultipleComponent, ExecuteAlways]
    public class PostProcessController : MonoBehaviour
    {
        public static PostProcessController global { get; set; }

        #region post config
        /// <summary>
        /// FXAA抗锯齿
        /// </summary>
        public bool useFXAA = false;

        /// <summary>
        /// bloom
        /// </summary>
        public bool useBloom = false;
        [SerializeField, Range(0, 30)]
        public float bloomIntensity = 1;
        [SerializeField, Range(1, 8)]
        public float bloomDiffusion = 5;
        [SerializeField, Range(0, 4)]
        public float bloomThreshold = 1;
        [SerializeField, Range(0, 1)]
        public float bloomSoftKnee = 0.6f;

        /// <summary>
        /// 色彩调整
        /// </summary>
        public bool useColorGrading = false;
        [SerializeField, Min(0.0f)]
        public float postExposure = 1;
        [SerializeField]
        Texture2D LutTex2D = null;

        /// <summary>
        /// 色调映射
        /// </summary>
        public bool useToneMapping = false;
        [SerializeField]
        PostProcessBehaviour.ToneMappingMode toneMappingMode = PostProcessBehaviour.ToneMappingMode.ACES;
        [SerializeField, Range(0, 1)]
        public float FilmSlope = 0.88f;
        [SerializeField, Range(0, 1)]
        public float FilmToe = 0.55f;
        [SerializeField, Range(0, 1)]
        public float FilmShoulder = 0.26f;
        [SerializeField, Range(0, 1)]
        public float FilmBlackClip = 0.0f;
        [SerializeField, Range(0, 1)]
        public float FilmWhiteClip = 0.04f;
        /// <summary>
        /// 用于海底或火焰场景的屏幕扭曲
        /// </summary>
        public bool useScreenDistort = false;
        [SerializeField, Range(0, 1)]
        public float distortIntensity = 0.1f;
        [SerializeField, Range(0, 1)]
        public float distortSpeedX = 0.0f;
        [SerializeField, Range(0, 1)]
        public float distortSpeedY = 0.1f;
        [SerializeField, Min(0)]
        public float distortDensity = 1f;

        public bool useVignette = false;
        [SerializeField, Range(0, 1)]
        public float vignetteIntensity = 0f;
        [SerializeField, Range(0, 1)]
        public float vignetteSmoothness = 0.2f;
        [SerializeField, Range(0, 1)]
        public float vignetteRoundness = 1f;
        public bool vignetteRounded = false;

        public bool useFogOfWar = false;
        [SerializeField]
        public float fogStartHeight = 0f;
        [SerializeField]
        public float fogEndHeight = 1f;
        [SerializeField]
        public Color fogColor = Color.black;
        [SerializeField, Range(0,3)]
        public int fogBlurNum = 2;
        [SerializeField]
        Texture2D fogDistortTex = null;
        [SerializeField]
        Texture2D fogUVTex = null;
        public Texture2D fogMaskTex = null;

        public bool useBlur = false;
        [SerializeField, Range(0, 9)]
        public float blurSize = 0.01f;
        [SerializeField, Range(0, 5)]
        public int blurIterations = 3;
        [SerializeField, Range(0, 9)]
        public int blurDownSample = 3;


        public bool useCapture = false;
        /// <summary>
        /// 抓取深度缓冲, 用于其他需要深度图的shader. 
        /// 取代默认管线的深度图, 消耗很低.
        /// </summary>
        public bool useDepthTexture = false;
        /// <summary>
        /// 抓取颜色缓冲, 取代GrabPass, 用于折射, 屏幕扭曲等特效. 
        /// 比GrabPass消耗低
        /// </summary>
        public bool useColorTexture = false;
        #endregion

        Camera mainCamera;
        public Camera MainCamera
        {
            get { return mainCamera; }
            set
            {
                if (value != mainCamera)
                {
                    mainCamera = value;
                    CameraChanged(mainCamera);
                }
            }
        }

        PostProcessBehaviour behaviour;
        //[SerializeField]
        public PostProcessResources resource;

        bool supportDepthFormat = false;

        private void OnEnable()
        {
#if UNITY_EDITOR
            resource = FindResource();
#endif
            supportDepthFormat = true;
            //supportDepthFormat = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R16);

            Camera camera = GetComponent<Camera>();
            if(camera == null)
            {
                camera = Camera.main;
            }
            if(camera != null)
            {
                MainCamera = camera;
            }
            if(mainCamera)
            {
                CameraChanged(mainCamera);
            }
        }

        void OnDestroy()
        {
            CleanUp();
        }

        private void LateUpdate()
        {
            if (!resource)
            {
                return;
            }
            if (!behaviour)
            {
                return;
            }

            if (useDepthTexture && supportDepthFormat)
                Shader.EnableKeyword("CAMERA_DEPTH_TEXTURE");
            else
                Shader.DisableKeyword("CAMERA_DEPTH_TEXTURE");

            if (Check())
            {
                mainCamera.allowHDR = false;
                behaviour.enabled = true;

                behaviour.UseDepthTexture = useDepthTexture && supportDepthFormat;
                behaviour.UseColorTexture = useColorTexture;

                behaviour.UseFXAA = useFXAA;

                behaviour.UseBloom = useBloom;
                behaviour.BloomIntensity = bloomIntensity;
                behaviour.BloomDiffusion = bloomDiffusion;
                behaviour.BloomThreshold = bloomThreshold;
                behaviour.BloomSoftKnee = bloomSoftKnee;

                behaviour.UseColorGrading = useColorGrading;
                behaviour.postExposure = postExposure;
                behaviour.LutTex2D = LutTex2D;

                behaviour.UseToneMapping = useToneMapping;
                behaviour.toneMappingMode = toneMappingMode;
                behaviour.FilmSlope = FilmSlope;
                behaviour.FilmToe = FilmToe;
                behaviour.FilmShoulder = FilmShoulder;
                behaviour.FilmBlackClip = FilmBlackClip;
                behaviour.FilmWhiteClip = FilmWhiteClip;


                behaviour.UseScreenDistort = useScreenDistort;
                behaviour.DistortIntensity = distortIntensity;
                behaviour.DistortSpeedX = distortSpeedX;
                behaviour.DistortSpeedY = distortSpeedY;
                behaviour.DistortDensity = distortDensity;

                behaviour.UseVignette = useVignette;
                behaviour.VignetteIntensity = vignetteIntensity;
                behaviour.VignetteSmoothness = vignetteSmoothness;
                behaviour.VignetteRoundness = vignetteRoundness;
                behaviour.VignetteRounded = vignetteRounded;

                behaviour.UseFogOfWar = useFogOfWar;
                behaviour.FogColor = fogColor;
                behaviour.FogStartHeight = fogStartHeight;
                behaviour.FogEndHeight = fogEndHeight;
                behaviour.FogDistortTex2D = fogDistortTex;
                behaviour.FogMaskTex2D = fogMaskTex;
                behaviour.FogUVTex2D = fogUVTex;
                behaviour.FogBlurNum = fogBlurNum;

                behaviour.UseBlur = useBlur;
                behaviour.BlurDownSample = blurDownSample;
                behaviour.BlurSize = blurSize;
                behaviour.BlurIterations = blurIterations;



                behaviour.UseCapture = useCapture;
            }
            else
            {
                mainCamera.allowHDR = true;
                CleanUp();
            }
        }

#if UNITY_EDITOR
        PostProcessResources FindResource()
        {
            PostProcessResources resource;
            //string[] guid = AssetDatabase.FindAssets("PostProcessResource");
            //string path = AssetDatabase.GUIDToAssetPath(guid[0]);

            string path = "Assets/Resources/Data/PostProcess/PostProcessResource.asset";

            resource = AssetDatabase.LoadAssetAtPath<PostProcessResources>(path);
            if (!resource)
            {
                throw new System.Exception("找不到后处理资源引用文件");
            }

            return resource;
        }
#endif

        void CameraChanged(Camera camera)
        {
            if(camera != null)
            {
                behaviour = camera.GetComponent<PostProcessBehaviour>() ?? camera.gameObject.AddComponent<PostProcessBehaviour>();
                behaviour.Resource = resource;
            }
        }

        bool Check()
        {
            bool needPost = false;

            needPost |= useBloom;
            needPost |= useColorGrading;
            needPost |= useScreenDistort;
            needPost |= useToneMapping;
            needPost |= useDepthTexture;
            needPost |= useColorTexture;
            needPost |= useFXAA;
            needPost |= useVignette;
            needPost |= useFogOfWar;

            needPost &= mainCamera != null;

            return needPost;
        }

        void CleanUp()
        {
            if (behaviour)
            {
                behaviour.enabled = false;
            }
        }
    }
}