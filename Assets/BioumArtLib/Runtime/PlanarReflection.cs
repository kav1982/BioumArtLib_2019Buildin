using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
public class PlanarReflection : MonoBehaviour
{
    public bool isReflection = true;

    [SerializeField, Range(1, 300)]
    float cullDistacneLargeModel = 150;

    [Range(0, 0.5f)]
    public float reflectionDistort = 0.1f;

    [SerializeField]
    float[] cullDistance = new float[32];

    [Range(-2, 2)]
    public float clipPlaneOffset = 0;
    public LayerMask reflectLayers = 0;

    private Dictionary<Camera, Camera> m_ReflectionCameras = new Dictionary<Camera, Camera>(); // Camera -> Camera table
    private RenderTexture m_ReflectionTexture;
    private int m_OldReflectionTextureSize;
    private static bool s_InsideWater;

    public enum Axis { x, y, z, x2, y2, z2 }
    public Axis normalDirection = Axis.y;
    Vector3 GetNormalDirection(Axis axis)
    {
        Vector3 dir = transform.up;
        switch (axis)
        {
            case Axis.x:
                dir = transform.right;
                break;
            case Axis.y:
                dir = transform.up;
                break;
            case Axis.z:
                dir = transform.forward;
                break;
            case Axis.x2:
                dir = -transform.right;
                break;
            case Axis.y2:
                dir = -transform.up;
                break;
            case Axis.z2:
                dir = -transform.forward;
                break;
        }
        return dir;
    }

    public enum TextureSize
    {
        small = 128,
        middle = 256,
        large = 512,
        veryLarge = 1024,
    }
    public TextureSize textureSize = TextureSize.large;

    Material waterMat;
    private void OnEnable()
    {
        gameObject.layer = 4; // Water
        waterMat = GetComponent<Renderer>().sharedMaterial;
    }

    // This is called when it's known that the object will be rendered by some
    // camera. We render reflections / refractions and do other updates here.
    // Because the script executes in edit mode, reflections for the scene view
    // camera will just work!
    public void OnWillRenderObject()
    {
        if (!waterMat)
        {
            return;
        }

        Camera cam = Camera.current;
        if (!cam)
        {
            return;
        }

        if (s_InsideWater)
        {
            return;
        }
        s_InsideWater = true;

        Camera reflectionCamera;
        CreateWaterObjects(cam, out reflectionCamera, (int) textureSize);

        // find out the reflection plane: position and normal in world space
        Vector3 pos = transform.position;
        Vector3 normal = GetNormalDirection(normalDirection);

        UpdateCameraModes(cam, reflectionCamera);

        if (isReflection == false)
        {
            waterMat.DisableKeyword("_REFLECTION_TEXTURE");
            if (m_ReflectionTexture)
            {
                DestroyImmediate(m_ReflectionTexture);
                m_ReflectionTexture = null;
            }
            foreach (var kvp in m_ReflectionCameras)
            {
                DestroyImmediate((kvp.Value).gameObject);
            }
            m_ReflectionCameras.Clear();
        }
        else
        {
            // Reflect camera around reflection plane
            float d = -Vector3.Dot(normal, pos); // - clipPlaneOffset;
            Vector4 reflectionPlane = new Vector4(normal.x, normal.y, normal.z, d);

            Matrix4x4 reflection = Matrix4x4.zero;
            CalculateReflectionMatrix(ref reflection, reflectionPlane);
            Vector3 oldpos = cam.transform.position;
            Vector3 newpos = reflection.MultiplyPoint(oldpos);
            reflectionCamera.worldToCameraMatrix = cam.worldToCameraMatrix * reflection;

            // Setup oblique projection matrix so that near plane is our reflection
            // plane. This way we clip everything below/above it for free.
            Vector4 clipPlane = CameraSpacePlane(reflectionCamera, pos, normal, 1.0f);
            reflectionCamera.projectionMatrix = cam.CalculateObliqueMatrix(clipPlane);

            reflectionCamera.cullingMask = ~(1 << 4) & reflectLayers.value; // never render water layer
            reflectionCamera.targetTexture = m_ReflectionTexture;
            bool oldCulling = GL.invertCulling;
            GL.invertCulling = !oldCulling;
            reflectionCamera.transform.position = newpos;
            Vector3 euler = cam.transform.eulerAngles;
            reflectionCamera.transform.eulerAngles = new Vector3(-euler.x, euler.y, euler.z);
            reflectionCamera.Render();
            reflectionCamera.transform.position = oldpos;
            GL.invertCulling = oldCulling;
            waterMat.SetTexture("_ReflectionTex", m_ReflectionTexture);
            waterMat.SetFloat("_RealtimeReflectionDistort", reflectionDistort);
            waterMat.EnableKeyword("_REFLECTION_TEXTURE");
        }

        s_InsideWater = false;
    }

    // Cleanup all the objects we possibly have created
    void OnDisable()
    {
        waterMat.DisableKeyword("_REFLECTION_TEXTURE");
        if (m_ReflectionTexture)
        {
            DestroyImmediate(m_ReflectionTexture);
            m_ReflectionTexture = null;
        }
        foreach (var kvp in m_ReflectionCameras)
        {
            DestroyImmediate((kvp.Value).gameObject);
        }
        m_ReflectionCameras.Clear();
    }

    void UpdateCameraModes(Camera src, Camera dest)
    {
        if (dest == null)
        {
            return;
        }
        // set water camera to clear the same way as current camera
        dest.clearFlags = src.clearFlags;
        dest.backgroundColor = src.backgroundColor;
        dest.nearClipPlane = 1f;
        dest.orthographic = src.orthographic;
        dest.fieldOfView = src.fieldOfView;
        dest.aspect = src.aspect;
        dest.orthographicSize = src.orthographicSize;
        dest.depthTextureMode = DepthTextureMode.None;

        UpdateCullDistance(dest);

        //if (src.clearFlags == CameraClearFlags.Skybox)
        //{
        //    Skybox sky = src.GetComponent<Skybox>();
        //    Skybox mysky = dest.GetComponent<Skybox>();
        //    if (!sky || !sky.material)
        //    {
        //        mysky.enabled = false;
        //    }
        //    else
        //    {
        //        mysky.enabled = true;
        //        mysky.material = sky.material;
        //    }
        //}
        // update other values to match current camera.
        // even if we are supplying custom camera&projection matrices,
        // some of values are used elsewhere (e.g. skybox uses far plane)
    }

    void UpdateCullDistance(Camera cam)
    {
        for (int i = 0; i < 32; i++)
        {
            cullDistance[i] = cullDistacneLargeModel;
        }

        cam.layerCullSpherical = true;
        cam.layerCullDistances = cullDistance;
    }

    // On-demand create any objects we need for water
    void CreateWaterObjects(Camera currentCamera, out Camera reflectionCamera, int texSize)
    {
        reflectionCamera = null;

        if (isReflection)
        {
            // Reflection render texture
            if (!m_ReflectionTexture || m_OldReflectionTextureSize != texSize)
            {
                if (m_ReflectionTexture)
                {
                    DestroyImmediate(m_ReflectionTexture);
                }
                m_ReflectionTexture = new RenderTexture(texSize, texSize, 16);
                m_ReflectionTexture.name = "__WaterReflection" + GetInstanceID();
                m_ReflectionTexture.isPowerOfTwo = true;
                m_ReflectionTexture.hideFlags = HideFlags.DontSave;
                m_OldReflectionTextureSize = texSize;
            }

            // Camera for reflection
            m_ReflectionCameras.TryGetValue(currentCamera, out reflectionCamera);
            if (!reflectionCamera) // catch both not-in-dictionary and in-dictionary-but-deleted-GO
            {
                GameObject go = new GameObject("Water Refl Camera id" + GetInstanceID() + " for " + currentCamera.GetInstanceID(), typeof(Camera), typeof(Skybox));
                reflectionCamera = go.GetComponent<Camera>();
                reflectionCamera.enabled = false;
                reflectionCamera.transform.position = transform.position;
                reflectionCamera.transform.rotation = transform.rotation;
                reflectionCamera.depthTextureMode = DepthTextureMode.None;
                //reflectionCamera.gameObject.AddComponent<FlareLayer>();
                go.hideFlags = HideFlags.HideAndDontSave;
                m_ReflectionCameras[currentCamera] = reflectionCamera;
            }
        }
    }

    // Given position/normal of the plane, calculates plane in camera space.
    Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign)
    {
        Vector3 offsetPos = pos + normal * clipPlaneOffset;
        Matrix4x4 m = cam.worldToCameraMatrix;
        Vector3 cpos = m.MultiplyPoint(offsetPos);
        Vector3 cnormal = m.MultiplyVector(normal).normalized * sideSign;
        return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
    }

    // Calculates reflection matrix around the given plane
    static void CalculateReflectionMatrix(ref Matrix4x4 reflectionMat, Vector4 plane)
    {
        reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
        reflectionMat.m01 = (-2F * plane[0] * plane[1]);
        reflectionMat.m02 = (-2F * plane[0] * plane[2]);
        reflectionMat.m03 = (-2F * plane[3] * plane[0]);

        reflectionMat.m10 = (-2F * plane[1] * plane[0]);
        reflectionMat.m11 = (1F - 2F * plane[1] * plane[1]);
        reflectionMat.m12 = (-2F * plane[1] * plane[2]);
        reflectionMat.m13 = (-2F * plane[3] * plane[1]);

        reflectionMat.m20 = (-2F * plane[2] * plane[0]);
        reflectionMat.m21 = (-2F * plane[2] * plane[1]);
        reflectionMat.m22 = (1F - 2F * plane[2] * plane[2]);
        reflectionMat.m23 = (-2F * plane[3] * plane[2]);

        reflectionMat.m30 = 0F;
        reflectionMat.m31 = 0F;
        reflectionMat.m32 = 0F;
        reflectionMat.m33 = 1F;
    }

#if UNITY_EDITOR
    #region 编辑器面板
    [CustomEditor(typeof(PlanarReflection))]
    public class WaterReflectionEditor : Editor
    {
        static class Styles
        {
            public static GUIContent enableReflection = new GUIContent("使用实时反射");
            public static GUIContent clipPlaneOffset = new GUIContent("水面裁剪偏移");

            public static GUIContent reflectLayers = new GUIContent("反射层");
            public static GUIContent cullDistacneLargeModel = new GUIContent("反射范围");

            public static GUIContent reflectionDistort = new GUIContent("实时反射扭曲强度");

            public static string[] axisNames = { "X", "Y", "Z", "-X", "-Y", "-Z", };
            public static string[] texSizeNames = { "128", "256", "512", "1024", };
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            EditorGUILayout.Space();
            EditorGUILayout.PropertyField(serializedObject.FindProperty("isReflection"), Styles.enableReflection);

            EditorGUILayout.Space();
            EditorGUILayout.PropertyField(serializedObject.FindProperty("reflectLayers"), Styles.reflectLayers);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("cullDistacneLargeModel"), Styles.cullDistacneLargeModel);

            EditorGUILayout.Space();
            EditorGUILayout.PropertyField(serializedObject.FindProperty("reflectionDistort"), Styles.reflectionDistort);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("clipPlaneOffset"), Styles.clipPlaneOffset);

            SerializedProperty texSize = serializedObject.FindProperty("textureSize");
            texSize.enumValueIndex = EditorGUILayout.Popup("反射贴图大小", texSize.enumValueIndex, Styles.texSizeNames);
            SerializedProperty normalDir = serializedObject.FindProperty("normalDirection");
            normalDir.enumValueIndex = EditorGUILayout.Popup("水面方向", normalDir.enumValueIndex, Styles.axisNames);

            serializedObject.ApplyModifiedProperties();
        }

    }
    #endregion
#endif
}