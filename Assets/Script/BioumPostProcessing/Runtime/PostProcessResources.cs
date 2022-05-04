using UnityEngine;

namespace BioumPostProcess
{
    [CreateAssetMenu(menuName = "BioumPost/创建后处理资源引用文件")]
    public sealed class PostProcessResources : ScriptableObject
    {
        public Shader fxaa;
        public Shader bloom;
        public Shader uber;
        public Shader copyColor;
        public Shader copyDepth;

        public Shader fogBlur;
        public Shader screenBlur;

        public Texture2D distortTex;
    }

}
