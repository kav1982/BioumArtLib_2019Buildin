using UnityEditor;
using UnityEngine;

public class CharacterToneGUI : ShaderGUI
{
    public enum BlendMode
    {
        Opaque,
        Cutout,
        Transparent,
        PreMultiply,
    }
    public enum CullMode
    {
        Back,
        Front,
        Double,
    }

    private static class Styles
    {
        public static string blendMode = "混合模式";
        public static string cullingMode = "裁剪模式";
        public static readonly string[] blendNames = { "不透明", "透贴", "半透明", "预乘Alpha半透明" };
        public static readonly string[] cullNames = { "正面显示", "背面显示", "双面显示" };
        public static GUIContent baseMapText = new GUIContent("颜色贴图");
        public static GUIContent normalMapText = new GUIContent("法线贴图");
        public static GUIContent maesMapText = new GUIContent("金属(R) AO(G) 皮肤Mask(B) 光滑(A)");
        public static GUIContent smoothnessRemapText = new GUIContent("光滑度重映射");
        public static GUIContent environmentMapText = new GUIContent("环境反射球");
    }

    MaterialProperty blendMode = null;
    MaterialProperty cullMode = null;

    MaterialProperty baseMap = null;
    MaterialProperty baseColor = null;
    MaterialProperty normalMap = null;
    MaterialProperty normalScale = null;
    MaterialProperty maesMap = null;
    MaterialProperty emissiveColor = null;
    MaterialProperty smoothnessMin = null;
    MaterialProperty smoothnessMax = null;
    MaterialProperty metallic = null;
    MaterialProperty fresnelStrength = null;
    MaterialProperty specularTint = null;
    MaterialProperty AOStrength = null;
    MaterialProperty transparent = null;
    MaterialProperty transparentZWrite = null;
    MaterialProperty cutoutStrength = null;
    MaterialProperty sssToggle = null;
    MaterialProperty sssColor = null;

    MaterialProperty rimToggle = null;
    MaterialProperty rimColorFront = null;
    MaterialProperty rimColorBack = null;
    MaterialProperty rimPower = null;
    MaterialProperty rimOffsetX = null;
    MaterialProperty rimOffsetY = null;
    MaterialProperty rimSmooth = null;
    MaterialProperty rimParam = null;

    MaterialProperty smoothDiff = null;
    MaterialProperty lightColorControl = null;
    MaterialProperty skinBackColor = null;
    MaterialProperty lightIntensity = null;

    MaterialProperty outlineScale = null;
    MaterialProperty outlineColor = null;
    MaterialProperty outlineToggle = null;

    MaterialProperty environmentMap = null;
    MaterialProperty environmentColor = null;
    MaterialProperty environmentParam = null;
    MaterialProperty environmentExposure = null;
    MaterialProperty environmentRotation = null;


    MaterialEditor m_MaterialEditor;
    
    // public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    // {
    //     Material material = materialEditor.target as Material;
    //     FindProperties(props);
    //     m_MaterialEditor = materialEditor;
    //     
    //     //EditorGUI.BeginChangeCheck();
    //     RenderMode(material);
    //     ShaderPropertiesGUI(material);
    //     
    // }

    public void FindProperties(MaterialProperty[] props)
    {
        blendMode = FindProperty("_BlendMode", props);
        cullMode = FindProperty("_CullMode", props);
        baseMap = FindProperty("_BaseMap", props);
        baseColor = FindProperty("_BaseColor", props);
        normalMap = FindProperty("_NormalMap", props);
        normalScale = FindProperty("_NormalScale", props);
        maesMap = FindProperty("_MAESMap", props);
        emissiveColor = FindProperty("_EmiColor", props);
        smoothnessMin = FindProperty("_SmoothnessMin", props);
        smoothnessMax = FindProperty("_SmoothnessMax", props);
        metallic = FindProperty("_Metallic", props);
        fresnelStrength = FindProperty("_FresnelStrength", props);
        specularTint = FindProperty("_SpecularTint", props);
        AOStrength = FindProperty("_AOStrength", props);
        transparent = FindProperty("_Transparent", props);
        transparentZWrite = FindProperty("_TransparentZWrite", props);
        cutoutStrength = FindProperty("_Cutoff", props);
        sssToggle = FindProperty("_sssToggle", props);
        sssColor = FindProperty("_SSSColor", props);

        rimToggle = FindProperty("_RimToggle", props);
        rimColorFront = FindProperty("_RimColorFront", props);
        rimColorBack = FindProperty("_RimColorBack", props);
        rimOffsetX = FindProperty("_RimOffsetX", props);
        rimOffsetY = FindProperty("_RimOffsetY", props);
        rimSmooth = FindProperty("_RimSmooth", props);
        rimPower = FindProperty("_RimPower", props);
        rimParam = FindProperty("_RimParam", props);

        lightIntensity = FindProperty("_LightIntensity", props);
        lightColorControl = FindProperty("_LightColorControl", props);
        skinBackColor = FindProperty("_SkinBackColor", props);
        smoothDiff = FindProperty("_SmoothDiff", props);

        outlineScale = FindProperty("_OutlineScale", props);
        outlineColor = FindProperty("_OutlineColor", props);
        outlineToggle = FindProperty("_OutlineToggle", props);

        environmentMap = FindProperty("_CharacterEnvironmentCube", props);
        environmentColor = FindProperty("_CharacterEnvironmentColor", props);
        environmentRotation = FindProperty("_CharacterEnvironmentRotation", props);
        environmentExposure = FindProperty("_CharacterEnvironmentExposure", props);
        environmentParam = FindProperty("_CharacterEnvironmentParam", props);
    }
    
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;
    
        material.doubleSidedGI = true;
    
        FindProperties(props);
        //RenderMode(material);
        ShaderPropertiesGUI(material);
        RenderMode(material);
        
    }

    void RenderMode(Material material)
    {
        SetupMaterialWithBlendMode(material, (BlendMode)blendMode.floatValue);
        SetupMaterialWithCullMode(material, (CullMode)cullMode.floatValue);
    }

    public void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        switch (blendMode)
        {
            case BlendMode.Opaque:
                material.SetOverrideTag("RenderType", "Opaque");
                material.SetKeyword("_ALPHATEST_ON", false);
                material.SetKeyword("_ALPHAPREMULTIPLY_ON", false);
                material.SetInt("_ZWrite", 1);
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.GeometryLast;
                break;
            case BlendMode.Cutout:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetKeyword("_ALPHATEST_ON", true);
                material.SetKeyword("_ALPHAPREMULTIPLY_ON", false);
                material.SetInt("_ZWrite", 1);
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                break;
            case BlendMode.Transparent:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetKeyword("_ALPHATEST_ON", false);
                material.SetKeyword("_ALPHAPREMULTIPLY_ON", false);
                material.SetInt("_ZWrite", (int)transparentZWrite.floatValue);
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.PreMultiply:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetKeyword("_ALPHATEST_ON", false);
                material.SetKeyword("_ALPHAPREMULTIPLY_ON", true);
                material.SetInt("_ZWrite", (int)transparentZWrite.floatValue);
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                break;
        }
    }

    public void SetupMaterialWithCullMode(Material material, CullMode cullMode)
    {
        switch (cullMode)
        {
            case CullMode.Back:
                material.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Back);
                break;
            case CullMode.Front:
                material.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Front);
                break;
            case CullMode.Double:
                material.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Off);
                break;
        }
    }
    
    
    public void ShaderPropertiesGUI(Material material)
    {
        EditorGUI.BeginChangeCheck();
        SceneShaderGUI(material);
        
        
        EditorGUILayout.Space();
        m_MaterialEditor.RenderQueueField();
        m_MaterialEditor.EnableInstancingField();
        m_MaterialEditor.DoubleSidedGIField();
    }
    
    
    const int indent = 1;
    void SceneShaderGUI(Material material)
    {

         BlendModePopup();
        
         Color mainColor = Color.white;
        
         if ((BlendMode)blendMode.floatValue == BlendMode.Cutout)
         {
             m_MaterialEditor.ShaderProperty(cutoutStrength, "透贴强度", indent);
         }
         else if ((BlendMode)blendMode.floatValue == BlendMode.Transparent || (BlendMode)blendMode.floatValue == BlendMode.PreMultiply)
         {
             m_MaterialEditor.ShaderProperty(transparent, "透明度", indent);
             m_MaterialEditor.ShaderProperty(transparentZWrite, "Z写入", indent);
             mainColor = baseColor.colorValue;
             mainColor.a = transparent.floatValue;
         }

        CullModePopup();
        
        EditorGUILayout.Space();
        m_MaterialEditor.TexturePropertySingleLine(Styles.baseMapText, baseMap, baseColor);
        m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, normalMap, normalScale);
        m_MaterialEditor.TexturePropertySingleLine(Styles.maesMapText, maesMap);

        material.SetKeyword("_NORMALMAP", normalMap.textureValue != null);

        EditorGUILayout.Space();
        m_MaterialEditor.TexturePropertySingleLine(Styles.environmentMapText, environmentMap);
        if (environmentMap.textureValue != null)
        {
            m_MaterialEditor.ShaderProperty(environmentExposure, "曝光", indent);
            m_MaterialEditor.ShaderProperty(environmentRotation, "旋转", indent);

            float rotation = Mathf.Deg2Rad * environmentRotation.floatValue;
            Cubemap cube = environmentMap.textureValue as Cubemap;
            int mipCount = cube.mipmapCount;
            environmentParam.vectorValue = new Vector4(rotation, environmentExposure.floatValue, mipCount, 0);
        }
        m_MaterialEditor.ShaderProperty(environmentColor, "环境色");



        EditorGUILayout.Space();
        m_MaterialEditor.ShaderProperty(skinBackColor, "皮肤暗部颜色");
        m_MaterialEditor.ShaderProperty(lightColorControl, "暗部颜色");
        m_MaterialEditor.ShaderProperty(lightIntensity, "灯光强度");
        m_MaterialEditor.ShaderProperty(smoothDiff, "明暗交界线硬度");
        Color colorControl = lightColorControl.colorValue;
        colorControl.a = lightIntensity.floatValue;
        lightColorControl.colorValue = colorControl;

        //EditorGUILayout.Space();
        //m_MaterialEditor.ShaderProperty(emissiveColor, "自发光");

        EditorGUILayout.Space();
        if (maesMap.textureValue != null)
        {
            float sMin = smoothnessMin.floatValue;
            float sMax = smoothnessMax.floatValue;
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.MinMaxSlider(Styles.smoothnessRemapText, ref sMin, ref sMax, 0.0f, 1.0f);
            if (EditorGUI.EndChangeCheck())
            {
                smoothnessMin.floatValue = sMin;
                smoothnessMax.floatValue = sMax;
            }
        }
        else
        {
            m_MaterialEditor.ShaderProperty(smoothnessMax, "光滑度");
            smoothnessMin.floatValue = 0;
        }
        m_MaterialEditor.ShaderProperty(metallic, "金属度");
        m_MaterialEditor.ShaderProperty(fresnelStrength, "菲涅尔强度");
        m_MaterialEditor.ShaderProperty(AOStrength, "AO强度");
        m_MaterialEditor.ShaderProperty(specularTint, "非金属反射着色");

        EditorGUILayout.Space();
        m_MaterialEditor.ShaderProperty(sssToggle, "SSS");
        if (sssToggle.floatValue != 0)
        {
            m_MaterialEditor.ShaderProperty(sssColor, "SSS颜色", indent);
        }

        EditorGUILayout.Space();
        m_MaterialEditor.ShaderProperty(rimToggle, "边缘光开关");
        if (rimToggle.floatValue != 0)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.ShaderProperty(rimColorFront, "边缘光亮面颜色");
            m_MaterialEditor.ShaderProperty(rimColorBack, "边缘光暗面颜色");
            m_MaterialEditor.ShaderProperty(rimOffsetX, "亮面范围偏移");
            m_MaterialEditor.ShaderProperty(rimOffsetY, "暗面范围偏移");
            m_MaterialEditor.ShaderProperty(rimSmooth, "边缘光硬度");
            m_MaterialEditor.ShaderProperty(rimPower, "边缘光范围");
            EditorGUI.indentLevel--;
            rimParam.vectorValue = new Vector4(rimOffsetX.floatValue, rimOffsetY.floatValue, rimSmooth.floatValue, rimPower.floatValue);

        }

        EditorGUILayout.Space();
        m_MaterialEditor.ShaderProperty(outlineToggle, "描边开关");
        if (outlineToggle.floatValue != 0)
        {
            EditorGUI.indentLevel++;
            material.shader = Shader.Find("Hidden/Bioum/Character/ToneCommon_Outline");
            m_MaterialEditor.ShaderProperty(outlineScale, "描边粗细");
            m_MaterialEditor.ShaderProperty(outlineColor, "描边颜色");
            EditorGUI.indentLevel--;
        }
        else
        {
            material.shader = Shader.Find("Bioum/Character/ToneCommon");
        }
    }

    void BlendModePopup()
    {
        EditorGUI.showMixedValue = blendMode.hasMixedValue;
        var mode = (BlendMode)blendMode.floatValue;
    
        EditorGUI.BeginChangeCheck();
        mode = (BlendMode)EditorGUILayout.Popup(Styles.blendMode, (int)mode, Styles.blendNames);
    
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
            blendMode.floatValue = (float)mode;
        }
    
        EditorGUI.showMixedValue = false;
    }

    void CullModePopup()
    {
        EditorGUI.showMixedValue = cullMode.hasMixedValue;
        var mode = (CullMode)cullMode.floatValue;
    
        EditorGUI.BeginChangeCheck();
        mode = (CullMode)EditorGUILayout.Popup(Styles.cullingMode, (int)mode, Styles.cullNames);
    
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Culling Mode");
            cullMode.floatValue = (float)mode;
        }
    
        EditorGUI.showMixedValue = false;
    }

}