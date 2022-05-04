﻿using UnityEditor;
using UnityEngine;

public class SceneGrassGUI : ShaderGUI
{
    public enum BlendMode
    {
        Opaque,
        Cutout,
    }
    public enum CullMode
    {
        Back,
        Double,
    }

    private static class Styles
    {
        public static string renderingMode = "混合模式";
        public static string cullingMode = "裁剪模式";
        public static readonly string[] blendNames = { "不透明", "透贴", };
        public static readonly string[] cullNames = { "正面显示", "双面显示" };
        public static GUIContent baseMapText = new GUIContent("颜色贴图");
        public static GUIContent normalMapText = new GUIContent("法线贴图");
        public static GUIContent maseMapText = new GUIContent("自发光(R) AO(A)");
    }

    MaterialProperty blendMode = null;
    MaterialProperty cullMode = null;

    MaterialProperty baseMap = null;
    MaterialProperty baseColor = null;
    MaterialProperty topColor = null;
    MaterialProperty waveColor = null;
    MaterialProperty cutoutStrength = null;
    MaterialProperty windToggle = null;
    MaterialProperty windScale = null;
    MaterialProperty windSpeed = null;
    MaterialProperty windDirection = null;
    MaterialProperty windIntensity = null;
    MaterialProperty windParam = null;
    MaterialEditor m_MaterialEditor;

    public void FindProperties(MaterialProperty[] props)
    {
        blendMode = FindProperty("_BlendMode", props);
        cullMode = FindProperty("_CullMode", props);
        baseMap = FindProperty("_BaseMap", props);
        baseColor = FindProperty("_BaseColor", props);
        topColor = FindProperty("_TopColor", props);
        waveColor = FindProperty("_WaveColor", props);
        cutoutStrength = FindProperty("_Cutoff", props);
        windToggle = FindProperty("_WindToggle", props);
        windScale = FindProperty("_WindScale", props);
        windSpeed = FindProperty("_WindSpeed", props);
        windDirection = FindProperty("_WindDirection", props);
        windIntensity = FindProperty("_WindIntensity", props);
        windParam = FindProperty("_WindParam", props);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        material.doubleSidedGI = true;

        FindProperties(props);
        RenderMode(material);
        ShaderPropertiesGUI(material);

        //EditorGUILayout.Space();
        //m_MaterialEditor.RenderQueueField();
        m_MaterialEditor.EnableInstancingField();
        //m_MaterialEditor.DoubleSidedGIField();
    }

    void RenderMode(Material material)
    {
        SetupMaterialWithBlendMode(material, (BlendMode) blendMode.floatValue);
        SetupMaterialWithCullMode(material, (CullMode) cullMode.floatValue);
    }

    public void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        switch (blendMode)
        {
            case BlendMode.Opaque:
                material.SetOverrideTag("RenderType", "Opaque");
                material.SetKeyword("_ALPHATEST_ON", false);
                material.SetInt("_ZWrite", 1);
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Geometry + 10;
                break;
            case BlendMode.Cutout:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetKeyword("_ALPHATEST_ON", true);
                material.SetInt("_ZWrite", 1);
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.AlphaTest + 10;
                break;
        }
    }

    public void SetupMaterialWithCullMode(Material material, CullMode cullMode)
    {
        switch (cullMode)
        {
            case CullMode.Back:
                material.SetInt("_Cull", (int) UnityEngine.Rendering.CullMode.Back);
                break;
            case CullMode.Double:
                material.SetInt("_Cull", (int) UnityEngine.Rendering.CullMode.Off);
                break;
        }
    }

    const int indent = 1;
    public void ShaderPropertiesGUI(Material material)
    {

        BlendModePopup();
        if ((BlendMode) blendMode.floatValue == BlendMode.Cutout)
        {
            m_MaterialEditor.ShaderProperty(cutoutStrength, "透贴强度", indent);
        }

        CullModePopup();

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(baseColor, "底部颜色");
        m_MaterialEditor.ShaderProperty(topColor, "顶部颜色");
        m_MaterialEditor.ShaderProperty(waveColor, "波浪颜色(需要开启风)");
        m_MaterialEditor.TexturePropertySingleLine(Styles.baseMapText, baseMap);

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

    void BlendModePopup()
    {
        EditorGUI.showMixedValue = blendMode.hasMixedValue;
        var mode = (BlendMode) blendMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (BlendMode) EditorGUILayout.Popup(Styles.renderingMode, (int) mode, Styles.blendNames);

        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
            blendMode.floatValue = (float) mode;
        }

        EditorGUI.showMixedValue = false;
    }

    void CullModePopup()
    {
        EditorGUI.showMixedValue = cullMode.hasMixedValue;
        var mode = (CullMode) cullMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (CullMode) EditorGUILayout.Popup(Styles.cullingMode, (int) mode, Styles.cullNames);

        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Culling Mode");
            cullMode.floatValue = (float) mode;
        }

        EditorGUI.showMixedValue = false;
    }

}