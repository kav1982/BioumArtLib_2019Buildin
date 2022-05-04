using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Assertions;
using BioumPostProcess;

[CustomEditor(typeof(PostProcessController))]
public class PostProcessControllerEditor : Editor
{
    static class Styles
    {
        public static GUIContent bloomEnable = new GUIContent("辉光");
        public static GUIContent bloomDiffusion = new GUIContent("扩散范围(越高越耗)");
        public static GUIContent bloomIntensity = new GUIContent("强度");
        public static GUIContent bloomThreshold = new GUIContent("阈值");
        public static GUIContent bloomSoftKnee = new GUIContent("散射");

        public static GUIContent ColorLutEnable = new GUIContent("色彩调整");
        public static GUIContent PostExposure = new GUIContent("曝光度");
        public static GUIContent ColorLutTex = new GUIContent("LUT");

        public static GUIContent ToneMapping = new GUIContent("TongMapping(色调映射)");
        public static GUIContent ToneMappingMode = new GUIContent("模式");
        public static GUIContent FilmSlope = new GUIContent("色调Slope");
        public static GUIContent FilmToe = new GUIContent("色调Toe");
        public static GUIContent FilmShoulder = new GUIContent("色调Shoulder");
        public static GUIContent FilmBlackClip = new GUIContent("黑色剔除");
        public static GUIContent FilmWhiteClip = new GUIContent("白色剔除");

        public static GUIContent DistortEnable = new GUIContent("场景扭曲(水下/火焰场景)");
        public static GUIContent DistortIntensity = new GUIContent("扭曲强度");
        public static GUIContent DistortSpeedX = new GUIContent("速度 X");
        public static GUIContent DistortSpeedY = new GUIContent("速度 Y");
        public static GUIContent DistortDensity = new GUIContent("扭曲密度");

        public static GUIContent VignetteEnable = new GUIContent("暗角");
        public static GUIContent VignetteIntensity = new GUIContent("强度");
        public static GUIContent VignetteSmoothness = new GUIContent("边缘过度");
        public static GUIContent VignetteRoundness = new GUIContent("圆形比例");
        public static GUIContent VignetteRounded = new GUIContent("是否为圆");

        public static GUIContent FogOfWarEnable = new GUIContent("战争迷雾");
        public static GUIContent FogColor = new GUIContent("迷雾颜色");
        public static GUIContent FogStartHeight = new GUIContent("起始高度");
        public static GUIContent FogEndHeight = new GUIContent("终止高度");
        public static GUIContent FogDistortTex2D = new GUIContent("扭曲贴图");
        public static GUIContent FogUVTex2D = new GUIContent("UV贴图");
        public static GUIContent FogBlurNum = new GUIContent("模糊次数");

        public static GUIContent DepthTexture = new GUIContent("抓取深度图");
        public static GUIContent ColorTexture = new GUIContent("抓取颜色图");

        public static GUIContent BlurEnable = new GUIContent("模糊");
        public static GUIContent BlurDownSample = new GUIContent("降采样次数");
        public static GUIContent BlurIterations = new GUIContent("模糊次数");
        public static GUIContent BlurSize = new GUIContent("模糊半径");

        public static GUIContent ScreenCapture = new GUIContent("是否截屏");
        public static GUIContent FXAA = new GUIContent("抗锯齿");
    }

 

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUILayout.Space();

        EditorGUILayout.PropertyField(serializedObject.FindProperty("useFXAA"), Styles.FXAA);
        EditorGUILayout.Space();

        BloomGUI();
        EditorGUILayout.Space();

        TonemappingGUI();
        EditorGUILayout.Space();

        ColorGradingGUI();
        EditorGUILayout.Space();

        DistortGUI();
        EditorGUILayout.Space();

        VignetteGUI();
        EditorGUILayout.Space();

        FogOfWarGUI();
        EditorGUILayout.Space();

        BlurGUI();
        EditorGUILayout.Space();

        EditorGUILayout.PropertyField(serializedObject.FindProperty("useCapture"), Styles.ScreenCapture);
        EditorGUILayout.Space();
        EditorGUILayout.PropertyField(serializedObject.FindProperty("useDepthTexture"), Styles.DepthTexture);
        EditorGUILayout.Space();
        EditorGUILayout.PropertyField(serializedObject.FindProperty("useColorTexture"), Styles.ColorTexture);
        EditorGUILayout.Space();

        serializedObject.ApplyModifiedProperties();
    }

    void BloomGUI()
    {
        SerializedProperty bloomToggle = serializedObject.FindProperty("useBloom");
        EditorGUILayout.PropertyField(bloomToggle, Styles.bloomEnable);

        EditorGUI.indentLevel++;
        if (bloomToggle.boolValue)
        {
            EditorGUILayout.PropertyField(serializedObject.FindProperty("bloomDiffusion"), Styles.bloomDiffusion);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("bloomIntensity"), Styles.bloomIntensity);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("bloomThreshold"), Styles.bloomThreshold);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("bloomSoftKnee"), Styles.bloomSoftKnee);
        }
        EditorGUI.indentLevel--;
    }

    void TonemappingGUI()
    {
        SerializedProperty toneMappingToggle = serializedObject.FindProperty("useToneMapping");
        EditorGUILayout.PropertyField(toneMappingToggle, Styles.ToneMapping);

        EditorGUI.indentLevel++;
        if (toneMappingToggle.boolValue)
        {
            EditorGUILayout.PropertyField(serializedObject.FindProperty("toneMappingMode"), Styles.ToneMappingMode);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("FilmSlope"), Styles.FilmSlope);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("FilmToe"), Styles.FilmToe);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("FilmShoulder"), Styles.FilmShoulder);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("FilmBlackClip"), Styles.FilmBlackClip);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("FilmWhiteClip"), Styles.FilmWhiteClip);
        }
        EditorGUI.indentLevel--;
    }

    void DistortGUI()
    {
        SerializedProperty distortToggle = serializedObject.FindProperty("useScreenDistort");
        EditorGUILayout.PropertyField(distortToggle, Styles.DistortEnable);

        EditorGUI.indentLevel++;
        if (distortToggle.boolValue)
        {
            EditorGUILayout.PropertyField(serializedObject.FindProperty("distortIntensity"), Styles.DistortIntensity);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("distortDensity"), Styles.DistortDensity);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("distortSpeedX"), Styles.DistortSpeedX);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("distortSpeedY"), Styles.DistortSpeedY);
        }
        EditorGUI.indentLevel--;
    }

    void VignetteGUI()
    {
        SerializedProperty vignetteToggle = serializedObject.FindProperty("useVignette");
        EditorGUILayout.PropertyField(vignetteToggle, Styles.VignetteEnable);

        EditorGUI.indentLevel++;
        if (vignetteToggle.boolValue)
        {
            EditorGUILayout.PropertyField(serializedObject.FindProperty("vignetteIntensity"), Styles.VignetteIntensity);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("vignetteSmoothness"), Styles.VignetteSmoothness);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("vignetteRoundness"), Styles.VignetteRoundness);

            SerializedProperty roundedToggle = serializedObject.FindProperty("vignetteRounded");
            EditorGUILayout.PropertyField(roundedToggle, Styles.VignetteRounded);
        }
        EditorGUI.indentLevel--;
    }

    void FogOfWarGUI()
    {
        SerializedProperty fogOfWarToggle = serializedObject.FindProperty("useFogOfWar");
        EditorGUILayout.PropertyField(fogOfWarToggle, Styles.FogOfWarEnable);
        EditorGUI.indentLevel++;
        if(fogOfWarToggle.boolValue)
        {
            EditorGUILayout.PropertyField(serializedObject.FindProperty("fogColor"), Styles.FogColor);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("fogStartHeight"), Styles.FogStartHeight);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("fogEndHeight"), Styles.FogStartHeight);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("fogDistortTex"), Styles.FogDistortTex2D);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("fogUVTex"), Styles.FogUVTex2D);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("fogBlurNum"), Styles.FogBlurNum);
        }
        EditorGUI.indentLevel--;
    }

    void BlurGUI()
    {
        SerializedProperty blurToggle = serializedObject.FindProperty("useBlur");
        EditorGUILayout.PropertyField(blurToggle, Styles.BlurEnable);
        EditorGUI.indentLevel++;
        if (blurToggle.boolValue)
        {
            EditorGUILayout.PropertyField(serializedObject.FindProperty("blurSize"), Styles.BlurSize);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("blurIterations"), Styles.BlurIterations);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("blurDownSample"), Styles.BlurDownSample);
        }
        EditorGUI.indentLevel--;
    }

    void ColorGradingGUI()
    {
        SerializedProperty colorLutToggle = serializedObject.FindProperty("useColorGrading");
        EditorGUILayout.PropertyField(colorLutToggle, Styles.ColorLutEnable);

        EditorGUI.indentLevel++;
        if (colorLutToggle.boolValue)
        {
            EditorGUILayout.PropertyField(serializedObject.FindProperty("postExposure"), Styles.PostExposure);
            SerializedProperty Lut2DTex = serializedObject.FindProperty("LutTex2D");
            EditorGUILayout.PropertyField(Lut2DTex, Styles.ColorLutTex);

            if (Lut2DTex.objectReferenceValue != null)
            {
                var importer = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(Lut2DTex.objectReferenceValue)) as TextureImporter;

                // Fails when using an internal texture as you can't change import settings on
                // builtin resources, thus the check for null
                if (importer != null)
                {
                    bool valid = importer.anisoLevel == 0 &&
                        importer.mipmapEnabled == false &&
                        importer.sRGBTexture == false &&
                        importer.textureCompression == TextureImporterCompression.Uncompressed &&
                        importer.wrapMode == TextureWrapMode.Clamp;

                    if (!valid)
                        DrawFixMeBox("贴图导入设置不正确", () => SetLutImportSettings(importer));
                }

                //if (lut.width != lut.height * lut.height)
                //{
                //    EditorGUILayout.HelpBox("The Lookup Texture size is invalid. Width should be Height * Height.", MessageType.Error);
                //}
            }
        }
        EditorGUI.indentLevel--;
    }
    public static void DrawFixMeBox(string text, Action action)
    {
        Assert.IsNotNull(action);

        EditorGUILayout.HelpBox(text, MessageType.Warning);

        GUILayout.Space(-32);
        using(new EditorGUILayout.HorizontalScope())
        {
            GUILayout.FlexibleSpace();

            if (GUILayout.Button("修复", GUILayout.Width(60)))
                action();

            GUILayout.Space(8);
        }
        GUILayout.Space(11);
    }

    void SetLutImportSettings(TextureImporter importer)
    {
        importer.textureType = TextureImporterType.Default;
        importer.mipmapEnabled = false;
        importer.anisoLevel = 0;
        importer.sRGBTexture = false;
        importer.npotScale = TextureImporterNPOTScale.None;
        importer.textureCompression = TextureImporterCompression.Uncompressed;
        importer.alphaSource = TextureImporterAlphaSource.None;
        importer.wrapMode = TextureWrapMode.Clamp;
        importer.SaveAndReimport();
        AssetDatabase.Refresh();
    }
}