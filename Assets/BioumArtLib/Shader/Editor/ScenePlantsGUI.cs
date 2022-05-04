using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class ScenePlantsGUI : ShaderGUI
{
    private static class Styles
    {
        public static string renderingMode = "混合模式";
        public static string cullingMode = "裁剪模式";
        public static readonly string[] blendNames = { "不透明", "透贴", "半透明", "预乘Alpha半透明" };
        public static readonly string[] cullNames = { "正面显示", "双面显示" };
        public static GUIContent baseMapText = new GUIContent("颜色贴图");
    }

    MaterialProperty doubleSideToggle = null;
    MaterialProperty cull = null;
    MaterialProperty baseMap = null;
    MaterialProperty baseColor = null;
    MaterialProperty secondColor = null;
    MaterialProperty normalWarp = null;
    MaterialProperty AOStrength = null;
    MaterialProperty AOCenter = null;
    MaterialProperty AOCenterColor = null;
    MaterialProperty cutoutStrength = null;
    MaterialProperty sssToggle = null;
    MaterialProperty sssColor = null;
    MaterialProperty sssRange = null;
    MaterialProperty windToggle = null;
    MaterialProperty windScale = null;
    MaterialProperty windSpeed = null;
    MaterialProperty windDirection = null;
    MaterialProperty windIntensity = null;
    MaterialProperty windParam = null;
    MaterialProperty ditherCutoff = null;
    MaterialEditor m_MaterialEditor;

    public void FindProperties(MaterialProperty[] props)
    {
        doubleSideToggle = FindProperty("_DoubleSideToggle", props);
        cull = FindProperty("_Cull", props);
        baseMap = FindProperty("_BaseMap", props);
        baseColor = FindProperty("_BaseColor", props);
        secondColor = FindProperty("_SecondColor", props);
        normalWarp = FindProperty("_NormalWarp", props);
        AOStrength = FindProperty("_AOStrength", props);
        AOCenter = FindProperty("_CenterOffset", props);
        AOCenterColor = FindProperty("_InnerColor", props);
        cutoutStrength = FindProperty("_Cutoff", props);
        sssToggle = FindProperty("_sssToggle", props);
        sssColor = FindProperty("_SSSColor", props);
        sssRange = FindProperty("_SSSRange", props);
        windToggle = FindProperty("_WindToggle", props);
        windScale = FindProperty("_WindScale", props);
        windSpeed = FindProperty("_WindSpeed", props);
        windDirection = FindProperty("_WindDirection", props);
        windIntensity = FindProperty("_WindIntensity", props);
        windParam = FindProperty("_WindParam", props);
        ditherCutoff = FindProperty("_DitherCutoff", props);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        material.doubleSidedGI = true;

        FindProperties(props);
        ShaderPropertiesGUI(material);

        //EditorGUILayout.Space();
        //m_MaterialEditor.RenderQueueField();
        //m_MaterialEditor.EnableInstancingField();
        m_MaterialEditor.DoubleSidedGIField();
    }

    const int indent = 1;
    public void ShaderPropertiesGUI(Material material)
    {
        m_MaterialEditor.ShaderProperty(ditherCutoff, "dither");
        m_MaterialEditor.ShaderProperty(cutoutStrength, "透贴强度");
        m_MaterialEditor.ShaderProperty(doubleSideToggle, "双面开关");
        if (doubleSideToggle.floatValue != 0)
            cull.floatValue = (int) CullMode.Off;
        else
            cull.floatValue = (int) CullMode.Back;

        EditorGUILayout.Space(10);
        m_MaterialEditor.TexturePropertySingleLine(Styles.baseMapText, baseMap);
        m_MaterialEditor.TextureScaleOffsetProperty(baseMap);
        m_MaterialEditor.ShaderProperty(normalWarp, "球形法线强度");

        { // for bake
            material.SetTexture("_MainTex", baseMap.textureValue);
            material.SetColor("_Color", baseColor.colorValue);
        }

        m_MaterialEditor.ShaderProperty(AOCenter, "中心坐标");

        m_MaterialEditor.ShaderProperty(AOStrength, "内外渐变范围");
        m_MaterialEditor.ShaderProperty(AOCenterColor, "中心颜色");
        
        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(baseColor, "顶部颜色");
        m_MaterialEditor.ShaderProperty(secondColor, "底部颜色");

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(sssToggle, "SSS");
        if (sssToggle.floatValue != 0)
        {

            m_MaterialEditor.ShaderProperty(sssColor, "SSS颜色", indent);
            m_MaterialEditor.ShaderProperty(sssRange, "SSS范围", indent);
            Color color = sssColor.colorValue;
            color.a = sssRange.floatValue;
            sssColor.colorValue = color;
        }

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(windToggle, "风开关");
        if (windToggle.floatValue != 0)
        {
            m_MaterialEditor.ShaderProperty(windScale, "缩放", indent);
            m_MaterialEditor.ShaderProperty(windSpeed, "速度", indent);
            m_MaterialEditor.ShaderProperty(windDirection, "风向", indent);
            m_MaterialEditor.ShaderProperty(windIntensity, "强度", indent);
            float radian = windDirection.floatValue * Mathf.Deg2Rad;
            float x = Mathf.Cos(radian) * windIntensity.floatValue;
            float y = Mathf.Sin(radian) * windIntensity.floatValue;
            windParam.vectorValue = new Vector4(x, y, windScale.floatValue, windSpeed.floatValue);
        }
    }

}