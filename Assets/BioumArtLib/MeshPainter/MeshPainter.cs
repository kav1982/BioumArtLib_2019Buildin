using UnityEngine;
using System.Collections;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
using System.IO;
#endif

[ExecuteInEditMode]
[RequireComponent(typeof(MeshCollider))]
public class MeshPainter : MonoBehaviour
{

#if UNITY_EDITOR
    [CustomEditor(typeof(MeshPainter))]
    public class MeshPainterEditor : Editor
    {
        enum PaintMode
        {
            Texture,
            Model,
        }
        static PaintMode paintMode;

        string controlTexName = "";

        bool isPaint;
        bool createCombinedTexture;

        static float brushSize = 16f;
        static float brushStronger = 0.5f;

        static GameObject prefab;
        static float prefabSizeRandom = 0;
        static float prefabRotateRandomX = 0;
        static float prefabRotateRandomY = 0;
        static float prefabRotateRandomZ = 0;
        static bool rotateFollowTerrain = true;
        Texture[] brushTex;
        Texture2D[] splatTextures;

        int selBrush = 0;
        int selTex = 0;

        int brushSizeInPourcent;
        Texture2D controlTex;
        void OnSceneGUI()
        {
            if (isPaint)
            {
                Painter();
                SetBrushParam();
            }
        }

        GUIStyle boolBtnOn;
        public override void OnInspectorGUI()
        {
            boolBtnOn = new GUIStyle(GUI.skin.GetStyle("Button"));  // button 样式

            GUILayout.BeginHorizontal();
            GUILayoutOption[] options = new GUILayoutOption[] { GUILayout.Width(100) };
            EditorGUILayout.LabelField("绘制模式选择", options);
            paintMode = (PaintMode)EditorGUILayout.EnumPopup(paintMode);
            GUILayout.EndHorizontal();

            GUILayout.Space(10);
            GUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
            isPaint = GUILayout.Toggle(isPaint, "点击开始绘制", boolBtnOn, GUILayout.Width(100), GUILayout.Height(25)); //编辑模式开关
            GUILayout.FlexibleSpace();
            GUILayout.EndHorizontal();

            GUILayout.Space(10);
            BrushParamInspector();
            switch (paintMode)
            {
                case PaintMode.Texture:
                    TextureModeInspector();
                    break;
                case PaintMode.Model:
                    ModelModeInspector();
                    break;
            }

            // GUILayout.Space(20);
            // GUILayout.BeginHorizontal();
            // GUILayout.FlexibleSpace();
            // createCombinedTexture = GUILayout.Toggle(createCombinedTexture, "合并贴图", boolBtnOn, GUILayout.Width(100), GUILayout.Height(25)); //创建纹理数组
            // GUILayout.FlexibleSpace();
            // GUILayout.EndHorizontal();
            // CreateCombinedTextureInspector();
        }

        void BrushParamInspector()
        {
            brushSize = EditorGUILayout.Slider("笔刷大小", brushSize, 0.1f, 100); //笔刷大小
            brushStronger = EditorGUILayout.Slider("笔刷强度", brushStronger, 0, 1); //笔刷强度
        }

        //绘制刷贴图模式的面板
        void TextureModeInspector()
        {
            if (Check())
            {
                IniBrush();
                layerTex();
                GUILayout.BeginHorizontal();
                GUILayout.FlexibleSpace();
                GUILayout.BeginHorizontal("box", GUILayout.Width(340));
                selTex = GUILayout.SelectionGrid(selTex, splatTextures, 4, "gridlist", GUILayout.Width(340), GUILayout.Height(86));
                GUILayout.EndHorizontal();
                GUILayout.FlexibleSpace();
                GUILayout.EndHorizontal();

                GUILayout.BeginHorizontal();
                GUILayout.FlexibleSpace();
                GUILayout.BeginHorizontal("box", GUILayout.Width(318));
                selBrush = GUILayout.SelectionGrid(selBrush, brushTex, 9, "gridlist", GUILayout.Width(340), GUILayout.Height(70));
                GUILayout.EndHorizontal();
                GUILayout.FlexibleSpace();
                GUILayout.EndHorizontal();
            }
        }

        //绘制刷模型模式的面板
        void ModelModeInspector()
        {
            GUILayout.Space(10);
            GUILayout.BeginHorizontal();
            GUILayoutOption[] options = new GUILayoutOption[] { GUILayout.Width(100) };
            EditorGUILayout.LabelField("欲绘制的模型", options);
            prefab = (GameObject)EditorGUILayout.ObjectField(prefab, typeof(GameObject), true);
            GUILayout.EndHorizontal();
            GUILayout.Space(10);
            rotateFollowTerrain = EditorGUILayout.Toggle("是否跟随地表旋转", rotateFollowTerrain);
            prefabSizeRandom = EditorGUILayout.Slider("随机大小", prefabSizeRandom, 0, 1);
            prefabRotateRandomX = EditorGUILayout.Slider("随机旋转X", prefabRotateRandomX, 0, 1);
            prefabRotateRandomY = EditorGUILayout.Slider("随机旋转Y", prefabRotateRandomY, 0, 1);
            prefabRotateRandomZ = EditorGUILayout.Slider("随机旋转Z", prefabRotateRandomZ, 0, 1);
        }

        void CreateCombinedTextureInspector()
        {
            if (createCombinedTexture && splatTextures != null)
            {
                int texCount = splatTextures.Length;

                //获取所有贴图中的最大尺寸
                int maxTexelSize = 0;
                for (int texIndex = 0; texIndex < texCount; texIndex++)
                {
                    int xyMax = Mathf.Max(splatTextures[texIndex].width, splatTextures[texIndex].height);
                    if (xyMax > maxTexelSize)
                        maxTexelSize = xyMax;
                }
                maxTexelSize = Mathf.Min(maxTexelSize, 1024);

                int combinedTextureSize = maxTexelSize * 2;
                Color[] colors = new Color[combinedTextureSize * combinedTextureSize];

                
                for (int j = 0; j < colors.Length; j++)
                {
                    colors[j] = Color.yellow;
                }


                //合并贴图
                Texture2D combinedTexture = new Texture2D(combinedTextureSize, combinedTextureSize);
                combinedTexture.SetPixels(colors);


                //保存资源
                string folder = GetTerrainTextureFolder();
                string path = folder + currentScene.name + "_TerrainCombinedTexture" + ".tga";
                byte[] bytes = combinedTexture.EncodeToTGA();
                File.WriteAllBytes(path, bytes);
                AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);

                //贴图导入设置
                TextureImporter textureIm = AssetImporter.GetAtPath(path) as TextureImporter;
                textureIm.textureCompression = TextureImporterCompression.Compressed;
                textureIm.isReadable = false;
                textureIm.anisoLevel = 2;
                textureIm.mipmapEnabled = true;
                textureIm.wrapMode = TextureWrapMode.Clamp;
                textureIm.sRGBTexture = true;

                TextureImporterPlatformSettings platformSetting = new TextureImporterPlatformSettings();
                platformSetting.name = "Android";
                platformSetting.overridden = true;
                platformSetting.format = TextureImporterFormat.ASTC_RGB_6x6;
                textureIm.SetPlatformTextureSettings(platformSetting);

                platformSetting.name = "iOS";
                platformSetting.overridden = true;
                platformSetting.format = TextureImporterFormat.ASTC_RGB_6x6;
                textureIm.SetPlatformTextureSettings(platformSetting);

                platformSetting.name = "Standalone";
                platformSetting.overridden = true;
                platformSetting.format = TextureImporterFormat.BC7;
                textureIm.SetPlatformTextureSettings(platformSetting);

                AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate); //刷新

                createCombinedTexture = false;
            }
        }

        //快捷键设置笔刷
        void SetBrushParam()
        {
            Event e = Event.current;

            if (e.keyCode == KeyCode.LeftBracket)
            {
                brushSize -= brushSize / 20;
                brushSize = Mathf.Max(0.01f, brushSize);
            }
            else if (e.keyCode == KeyCode.RightBracket)
            {
                brushSize += brushSize / 20;
            }
            else if (e.keyCode == KeyCode.Minus)
            {
                brushStronger = Mathf.Clamp01(brushStronger -= 0.02f);
            }
            else if (e.keyCode == KeyCode.Equals)
            {
                brushStronger = Mathf.Clamp01(brushStronger += 0.02f);
            }
        }

        //获取材质球中的贴图
        void layerTex()
        {
            Transform Select = Selection.activeTransform;
            Material mat = Select.GetComponent<MeshRenderer>().sharedMaterial;
            int texCount = (int)mat.GetFloat("_TexCount");

            splatTextures = new Texture2D[texCount];
            splatTextures[0] = (Texture2D)mat.GetTexture("_Splat0");
            splatTextures[1] = (Texture2D)mat.GetTexture("_Splat1");
            if (texCount > 2)
                splatTextures[2] = (Texture2D)mat.GetTexture("_Splat2");
            if (texCount > 3)
                splatTextures[3] = (Texture2D)mat.GetTexture("_Splat3");
        }

        //获取笔刷  
        void IniBrush()
        {
            if (brushTex == null)
            {
                string[] CS_GUID = AssetDatabase.FindAssets("MeshPainter");  // find MeshPainter.cs
                string MeshPainterFolder = AssetDatabase.GUIDToAssetPath(CS_GUID[0]);
                ArrayList BrushList = new ArrayList();
                Texture BrushesTL;
                int BrushNum = 0;
                do
                {
                    BrushesTL = (Texture)AssetDatabase.LoadAssetAtPath(MeshPainterFolder + "/Brushes/Brush" + BrushNum + ".png", typeof(Texture));

                    if (BrushesTL)
                    {
                        BrushList.Add(BrushesTL);
                    }
                    BrushNum++;
                } while (BrushesTL);
                brushTex = BrushList.ToArray(typeof(Texture)) as Texture[];
            }
        }

        //检查
        bool Check()
        {
            bool Check = false;
            Transform Select = Selection.activeTransform;
            Material mat = Select.GetComponent<MeshRenderer>().sharedMaterial;
            if (mat.shader == Shader.Find("Bioum/Scene/Terrain"))
            {
                Texture ControlTex = mat.GetTexture("_ControlTex");
                if (ControlTex == null)
                {
                    EditorGUILayout.HelpBox("当前模型材质球中未找到混合贴图，绘制功能不可用！", MessageType.Error);

                    if (GUILayout.Button("创建混合贴图(512)"))
                    {
                        createControlTex(512);
                    }
                    if (GUILayout.Button("创建混合贴图(1024)"))
                    {
                        createControlTex(1024);
                    }
                    if (GUILayout.Button("创建混合贴图(2048)"))
                    {
                        createControlTex(2048);
                    }
                }
                else
                {
                    Check = true;
                }
            }
            else
            {
                EditorGUILayout.HelpBox("shader错误, 请使用'Bioum/Scene/Terrain'", MessageType.Error);
            }
            return Check;
        }

        string terrainTextureFolder;
        Scene currentScene;
        string GetTerrainTextureFolder()
        {
            if (terrainTextureFolder == null)
            {
                currentScene = SceneManager.GetActiveScene();
                EditorSceneManager.SaveScene(currentScene);

                terrainTextureFolder = currentScene.path.Remove(currentScene.path.Length - currentScene.name.Length - 7) + "/TerrainTextures/"; //  .../folder/sceneName.unity  =>  .../folder/textures/
                if (!Directory.Exists(terrainTextureFolder))
                {
                    Directory.CreateDirectory(terrainTextureFolder);
                    AssetDatabase.Refresh();
                }
            }

            return terrainTextureFolder;
        }

        //创建Control贴图
        void createControlTex(int texelSize)
        {
            string folder = GetTerrainTextureFolder();

            //创建一个新的Control贴图
            Texture2D newControlTex = new Texture2D(texelSize, texelSize, TextureFormat.ARGB32, false);
            Color[] colorBase = new Color[texelSize * texelSize];
            for (int t = 0; t < colorBase.Length; t++)
            {
                colorBase[t] = new Color(1, 0, 0, 0);
            }
            newControlTex.SetPixels(colorBase);

            //判断是否重名
            bool exportNameSuccess = true;
            for (int num = 1; exportNameSuccess; num++)
            {
                string Next = currentScene.name + "_Control" + num;
                if (!File.Exists(folder + currentScene.name + ".tga"))
                {
                    controlTexName = currentScene.name + "_Control";
                    exportNameSuccess = false;
                }
                else if (!File.Exists(folder + Next + ".tga"))
                {
                    controlTexName = Next;
                    exportNameSuccess = false;
                }
            }

            //保存贴图
            string path = folder + controlTexName + ".tga";
            byte[] bytes = newControlTex.EncodeToTGA();
            File.WriteAllBytes(path, bytes);
            AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);

            //control贴图导入设置
            TextureImporter textureIm = AssetImporter.GetAtPath(path) as TextureImporter;
            textureIm.textureCompression = TextureImporterCompression.Uncompressed;
            textureIm.isReadable = true;
            textureIm.anisoLevel = 1;
            textureIm.mipmapEnabled = false;
            textureIm.wrapMode = TextureWrapMode.Clamp;
            textureIm.sRGBTexture = false;
            AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate); //刷新
            setControlTex(path); //设置Control贴图
        }

        //设置Control贴图
        void setControlTex(string path)
        {
            Texture2D ControlTex = (Texture2D)AssetDatabase.LoadAssetAtPath(path, typeof(Texture2D));
            Selection.activeTransform.gameObject.GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_ControlTex", ControlTex);
        }

        void Painter()
        {
            Transform currentSelect = Selection.activeTransform;

            MeshFilter temp = currentSelect.GetComponent<MeshFilter>(); //获取当前模型的MeshFilter
            float orthographicSize = (brushSize * currentSelect.localScale.x) * (temp.sharedMesh.bounds.size.x / 200); //笔刷在模型上的正交大小

            Event e = Event.current; //检测输入
            HandleUtility.AddDefaultControl(0);
            Ray mouseRay = HandleUtility.GUIPointToWorldRay(e.mousePosition); //从鼠标位置发射一条射线
            MeshCollider collider = currentSelect.GetComponent<MeshCollider>();

            if (collider.Raycast(mouseRay, out RaycastHit raycastHit, Mathf.Infinity))
            {
                DrawCircle(raycastHit.point, raycastHit.normal, orthographicSize); // 在鼠标位置绘制一个圆

                switch (paintMode)
                {
                    case PaintMode.Texture:
                        DrawTexture(e, raycastHit, currentSelect);
                        break;
                    case PaintMode.Model:
                        if (prefab == null)
                        {
                            return;
                        }
                        //模型位置随机分布
                        RaycastHit randomHit;
                        Ray randomRay = HandleUtility.GUIPointToWorldRay(e.mousePosition);
                        randomRay.origin += GetRandomPoint(orthographicSize);
                        collider.Raycast(randomRay, out randomHit, Mathf.Infinity);

                        DrawModel(e, randomHit, currentSelect);
                        break;
                }

            }
        }

        //获取球形范围内的随机点
        Vector3 GetRandomPoint(float sphereSize)
        {
            //随机球坐标
            float phi = Random.Range(0, Mathf.PI * 2);
            float theta = Random.Range(0, Mathf.PI);
            float radius = sphereSize;

            //球坐标转笛卡尔坐标
            Vector3 point = new Vector3();
            point.x = radius * Mathf.Sin(phi) * Mathf.Cos(theta);
            point.z = radius * Mathf.Sin(phi) * Mathf.Sin(theta);
            point.y = radius * Mathf.Cos(phi);

            return point;
        }

        bool ToggleF = false;
        //画混合贴图
        void DrawTexture(Event e, RaycastHit raycastHit, Transform currentSelect)
        {
            if (!Check())
            {
                return;
            }
            controlTex = (Texture2D)currentSelect.gameObject.GetComponent<MeshRenderer>().sharedMaterial.GetTexture("_ControlTex"); //从材质球中获取Control贴图
            brushSizeInPourcent = (int)Mathf.Round((brushSize * controlTex.width) / 100); //笔刷在模型上的大小

            //鼠标点击或按下并拖动进行绘制
            if ((e.type == EventType.MouseDrag || e.type == EventType.MouseDown) && e.alt == false && e.shift == false && e.control == false && e.button == 0)
            {
                //选择绘制的通道
                Color targetColor = new Color(1f, 0f, 0f, 0f);
                switch (selTex)
                {
                    case 0:
                        targetColor = new Color(1f, 0f, 0f, 0f);
                        break;
                    case 1:
                        targetColor = new Color(0f, 1f, 0f, 0f);
                        break;
                    case 2:
                        targetColor = new Color(0f, 0f, 1f, 0f);
                        break;
                    case 3:
                        targetColor = new Color(0f, 0f, 0f, 1f);
                        break;

                }

                Vector2 pixelUV = raycastHit.textureCoord;

                //计算笔刷所覆盖的区域
                int PuX = Mathf.FloorToInt(pixelUV.x * controlTex.width);
                int PuY = Mathf.FloorToInt(pixelUV.y * controlTex.height);
                int x = Mathf.Clamp(PuX - brushSizeInPourcent / 2, 0, controlTex.width - 1);
                int y = Mathf.Clamp(PuY - brushSizeInPourcent / 2, 0, controlTex.height - 1);
                int width = Mathf.Clamp((PuX + brushSizeInPourcent / 2), 0, controlTex.width) - x;
                int height = Mathf.Clamp((PuY + brushSizeInPourcent / 2), 0, controlTex.height) - y;

                Color[] terrainBay = controlTex.GetPixels(x, y, width, height, 0); //获取Control贴图被笔刷所覆盖的区域的颜色

                Texture2D TBrush = brushTex[selBrush] as Texture2D; //获取笔刷性状贴图
                float[] brushAlpha = new float[brushSizeInPourcent * brushSizeInPourcent]; //笔刷透明度

                //根据笔刷贴图计算笔刷的透明度
                for (int i = 0; i < brushSizeInPourcent; i++)
                {
                    for (int j = 0; j < brushSizeInPourcent; j++)
                    {
                        brushAlpha[j * brushSizeInPourcent + i] = TBrush.GetPixelBilinear(((float)i) / brushSizeInPourcent, ((float)j) / brushSizeInPourcent).a;
                    }
                }

                //计算绘制后的颜色
                for (int i = 0; i < height; i++)
                {
                    for (int j = 0; j < width; j++)
                    {
                        int index = (i * width) + j;
                        float Stronger = brushAlpha[Mathf.Clamp((y + i) - (PuY - brushSizeInPourcent / 2), 0, brushSizeInPourcent - 1) * brushSizeInPourcent + Mathf.Clamp((x + j) - (PuX - brushSizeInPourcent / 2), 0, brushSizeInPourcent - 1)] * brushStronger;

                        terrainBay[index] = Color.Lerp(terrainBay[index], targetColor, Stronger);
                    }
                }
                Undo.RegisterCompleteObjectUndo(controlTex, "meshPaint"); //保存历史记录以便撤销

                controlTex.SetPixels(x, y, width, height, terrainBay, 0); //把绘制后的Control贴图保存起来
                controlTex.Apply();
                ToggleF = true;
            }
            else if (e.type == EventType.MouseUp && e.alt == false && ToggleF == true)
            {
                SaveTexture(); //绘制结束保存Control贴图
                ToggleF = false;
            }
        }

        float time = 0;
        //在地表刷模型
        void DrawModel(Event e, RaycastHit raycastHit, Transform currentSelect)
        {
            //鼠标按下或者拖动
            if ((e.type == EventType.MouseDrag || e.type == EventType.MouseDown) && e.alt == false && e.shift == false && e.control == false && e.button == 0)
            {
                time += Time.deltaTime;
                float timeThe = (1 - brushStronger) * 5;
                if (time > timeThe)
                {
                    Vector3 pos = raycastHit.point; // + new Vector3(Random.Range(-randomRange, randomRange), 0, Random.Range(-randomRange, randomRange));

                    Quaternion rot;
                    if (rotateFollowTerrain)
                    {
                        rot = Quaternion.LookRotation(raycastHit.normal);
                    }
                    else
                    {
                        rot = Quaternion.LookRotation(Vector3.up);
                    }
                    GameObject go = Instantiate(prefab, pos, rot);
                    go.transform.parent = currentSelect;

                    //随机旋转
                    float randomRangeX = prefabRotateRandomX * 90;
                    float randomRangeY = prefabRotateRandomY * 90;
                    float randomRangeZ = prefabRotateRandomZ * 90;
                    Vector3 randomRot = new Vector3(Random.Range(-randomRangeX, randomRangeX), Random.Range(-randomRangeY, randomRangeY), Random.Range(-randomRangeZ, randomRangeZ));
                    go.transform.Rotate(randomRot);

                    //随机大小
                    go.transform.localScale *= Random.Range(1 - prefabSizeRandom, 1 + prefabSizeRandom);

                    time = 0;
                }

            }
        }

        void DrawCircle(Vector3 center, Vector3 normal, float size)
        {
            Handles.color = Color.yellow; //颜色
            Handles.DrawWireDisc(center, normal, size); //根据笔刷大小在鼠标位置显示一个圆
            Handles.color = new Color(1, 0.2f, 0.2f, 1); //颜色
            Handles.DrawWireArc(center, normal, Vector3.right, brushStronger * 360, size + size * 0.05f);
        }
        public void SaveTexture()
        {
            var path = AssetDatabase.GetAssetPath(controlTex);
            var bytes = controlTex.EncodeToTGA();
            File.WriteAllBytes(path, bytes);
            //AssetDatabase.Refresh();
            //AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);//刷新
            //AssetDatabase.SaveAssets();
        }
    }
#endif
}
