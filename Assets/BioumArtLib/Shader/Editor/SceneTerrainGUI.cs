using UnityEditor;
using UnityEngine;

public class SceneTerrainGUI : ShaderGUI
{
    public enum TextureCount
    {
        two,
        three,
        four,
    }
    public enum LightingModel
    {
        Lambert,
        PBR,
    }

    private static class Styles
    {
        public static string textureCount = "贴图数量";
        public static string lightingModel = "光照模式";
        public static readonly string[] textureCountNames = { "两张", "三张", "四张", };
        public static readonly string[] lightingModelNames = { "简单", "PBR", };
        public static GUIContent splatMapText = new GUIContent("颜色贴图");
        public static GUIContent normalMapText = new GUIContent("法线贴图");
        public static GUIContent controlMapText = new GUIContent("混合贴图");
    }

    MaterialProperty textureCountProp = null;
    MaterialProperty lightingModelProp = null;
    MaterialProperty controlMap = null;
    MaterialProperty splatMap0 = null;
    MaterialProperty splatMap1 = null;
    MaterialProperty splatMap2 = null;
    MaterialProperty splatMap3 = null;
    MaterialProperty splatScale0 = null;
    MaterialProperty splatScale1 = null;
    MaterialProperty splatScale2 = null;
    MaterialProperty splatScale3 = null;
    MaterialProperty splatScale = null;
    MaterialProperty color0 = null;
    MaterialProperty color1 = null;
    MaterialProperty color2 = null;
    MaterialProperty color3 = null;
    MaterialProperty normalMapToggle = null;
    MaterialProperty normalMap0 = null;
    MaterialProperty normalMap1 = null;
    MaterialProperty normalMap2 = null;
    MaterialProperty normalMap3 = null;
    MaterialProperty normalScale0 = null;
    MaterialProperty normalScale1 = null;
    MaterialProperty normalScale2 = null;
    MaterialProperty normalScale3 = null;
    MaterialProperty normalScale = null;
    MaterialProperty smoothness0 = null;
    MaterialProperty smoothness1 = null;
    MaterialProperty smoothness2 = null;
    MaterialProperty smoothness3 = null;
    MaterialProperty smoothness = null;

    MaterialEditor m_MaterialEditor;

    public void FindProperties(MaterialProperty[] props)
    {
        textureCountProp = FindProperty("_TexCount", props);
        lightingModelProp = FindProperty("_LightingModel", props);
        controlMap = FindProperty("_ControlTex", props);
        splatMap0 = FindProperty("_Splat0", props);
        splatMap1 = FindProperty("_Splat1", props);
        splatMap2 = FindProperty("_Splat2", props);
        splatMap3 = FindProperty("_Splat3", props);
        splatScale0 = FindProperty("_SplatScale0", props);
        splatScale1 = FindProperty("_SplatScale1", props);
        splatScale2 = FindProperty("_SplatScale2", props);
        splatScale3 = FindProperty("_SplatScale3", props);
        splatScale = FindProperty("_SplatScale", props);
        color0 = FindProperty("_Color0", props);
        color1 = FindProperty("_Color1", props);
        color2 = FindProperty("_Color2", props);
        color3 = FindProperty("_Color3", props);

        normalMapToggle = FindProperty("_NormalMapToggle", props);
        normalMap0 = FindProperty("_NormalMap0", props);
        normalMap1 = FindProperty("_NormalMap1", props);
        normalMap2 = FindProperty("_NormalMap2", props);
        normalMap3 = FindProperty("_NormalMap3", props);
        normalScale0 = FindProperty("_NormalScale0", props);
        normalScale1 = FindProperty("_NormalScale1", props);
        normalScale2 = FindProperty("_NormalScale2", props);
        normalScale3 = FindProperty("_NormalScale3", props);
        normalScale = FindProperty("_NormalScale", props);

        smoothness0 = FindProperty("_Smoothness0", props);
        smoothness1 = FindProperty("_Smoothness1", props);
        smoothness2 = FindProperty("_Smoothness2", props);
        smoothness3 = FindProperty("_Smoothness3", props);
        smoothness = FindProperty("_Smoothness", props);
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
        //m_MaterialEditor.EnableInstancingField();
        //m_MaterialEditor.DoubleSidedGIField();
    }

    void RenderMode(Material material)
    {
        SetupMaterialWithTextureCount(material, (TextureCount) (textureCountProp.floatValue - 2.0f));
        SetupMaterialWithLightingModel(material, (LightingModel) lightingModelProp.floatValue);
    }

    public void SetupMaterialWithTextureCount(Material material, TextureCount textureCount)
    {
        switch (textureCount)
        {
            case TextureCount.two:
                material.SetKeyword("TERRAIN_2TEX", true);
                material.SetKeyword("TERRAIN_3TEX", false);
                material.SetKeyword("TERRAIN_4TEX", false);
                break;
            case TextureCount.three:
                material.SetKeyword("TERRAIN_2TEX", false);
                material.SetKeyword("TERRAIN_3TEX", true);
                material.SetKeyword("TERRAIN_4TEX", false);
                break;
            case TextureCount.four:
                material.SetKeyword("TERRAIN_2TEX", false);
                material.SetKeyword("TERRAIN_3TEX", false);
                material.SetKeyword("TERRAIN_4TEX", true);
                break;
        }
    }

    public void SetupMaterialWithLightingModel(Material material, LightingModel lightingModel)
    {
        switch (lightingModel)
        {
            case LightingModel.Lambert:
                material.SetKeyword("LIGHTMODEL_LAMBERT", true);
                material.SetKeyword("LIGHTMODEL_PBR", false);
                break;
            case LightingModel.PBR:
                material.SetKeyword("LIGHTMODEL_LAMBERT", false);
                material.SetKeyword("LIGHTMODEL_PBR", true);
                break;
        }
    }

    Vector4 splatScaleVector = Vector4.one;
    Vector4 smoothnessVector = Vector4.one;
    Vector4 normalScaleVector = Vector4.one;
    public void ShaderPropertiesGUI(Material material)
    {
        TextureCountPopup();
        LightingModelPopup();

        EditorGUILayout.Space(10);
        m_MaterialEditor.TexturePropertySingleLine(Styles.splatMapText, splatMap0, color0);
        m_MaterialEditor.ShaderProperty(splatScale0, "贴图缩放");
        m_MaterialEditor.TexturePropertySingleLine(Styles.splatMapText, splatMap1, color1);
        m_MaterialEditor.ShaderProperty(splatScale1, "贴图缩放");
        if (textureCountProp.floatValue > 2)
        {
            m_MaterialEditor.TexturePropertySingleLine(Styles.splatMapText, splatMap2, color2);
            m_MaterialEditor.ShaderProperty(splatScale2, "贴图缩放");
        }
        if (textureCountProp.floatValue > 3)
        {
            m_MaterialEditor.TexturePropertySingleLine(Styles.splatMapText, splatMap3, color3);
            m_MaterialEditor.ShaderProperty(splatScale3, "贴图缩放");
        }

        splatScaleVector.x = splatScale0.floatValue;
        splatScaleVector.y = splatScale1.floatValue;
        splatScaleVector.z = splatScale2.floatValue;
        splatScaleVector.w = splatScale3.floatValue;
        splatScale.vectorValue = splatScaleVector;

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(normalMapToggle, "使用法线贴图");
        if (normalMapToggle.floatValue != 0)
        {
            m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, normalMap0, normalScale0);
            m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, normalMap1, normalScale1);
            if (textureCountProp.floatValue > 2)
                m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, normalMap2, normalScale2);
            if (textureCountProp.floatValue > 3)
                m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, normalMap3, normalScale3);

            normalScaleVector.x = normalScale0.floatValue;
            normalScaleVector.y = normalScale1.floatValue;
            normalScaleVector.z = normalScale2.floatValue;
            normalScaleVector.w = normalScale3.floatValue;
            normalScale.vectorValue = normalScaleVector;
        }

        EditorGUILayout.Space(10);
        if ((LightingModel) lightingModelProp.floatValue == LightingModel.PBR)
        {
            EditorGUILayout.LabelField("光滑度保存在颜色贴图A通道");
            m_MaterialEditor.ShaderProperty(smoothness0, "光滑度1");
            m_MaterialEditor.ShaderProperty(smoothness1, "光滑度2");
            if (textureCountProp.floatValue > 2)
                m_MaterialEditor.ShaderProperty(smoothness2, "光滑度3");
            if (textureCountProp.floatValue > 3)
                m_MaterialEditor.ShaderProperty(smoothness3, "光滑度4");

            smoothnessVector.x = smoothness0.floatValue;
            smoothnessVector.y = smoothness1.floatValue;
            smoothnessVector.z = smoothness2.floatValue;
            smoothnessVector.w = smoothness3.floatValue;
            smoothness.vectorValue = smoothnessVector;
        }

        EditorGUILayout.Space(10);
        m_MaterialEditor.TexturePropertySingleLine(Styles.controlMapText, controlMap);
    }

    void TextureCountPopup()
    {
        EditorGUI.showMixedValue = textureCountProp.hasMixedValue;
        var count = (TextureCount) (textureCountProp.floatValue - 2.0f);

        EditorGUI.BeginChangeCheck();
        count = (TextureCount) EditorGUILayout.Popup(Styles.textureCount, (int) count, Styles.textureCountNames);

        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Texture Count Mode");
            textureCountProp.floatValue = (float) count + 2;
        }

        EditorGUI.showMixedValue = false;
    }

    void LightingModelPopup()
    {
        EditorGUI.showMixedValue = lightingModelProp.hasMixedValue;
        var mode = (LightingModel) lightingModelProp.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (LightingModel) EditorGUILayout.Popup(Styles.lightingModel, (int) mode, Styles.lightingModelNames);

        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("LightingModel Mode");
            lightingModelProp.floatValue = (float) mode;
        }

        EditorGUI.showMixedValue = false;
    }

}