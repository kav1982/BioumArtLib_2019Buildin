using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BQuadTree : MonoBehaviour
{

    class Node
    {
        public int level;
        public int x;
        public int z;
        public int size;
        public int flag;// 0 node 1 shadowdata  
        public Node parent;
        public Node[] children;
        public int index;

        internal void insert(int vx, int vz)
        {

            if (size <= 1) { flag = 1; return; }
            if (children == null)
            {
                children = new Node[4];
                children[0] = new Node() { x = x, z = z, size = size / 2, level = level + 1, parent = this };
                children[1] = new Node() { x = x + size / 2, z = z, size = size / 2, level = level + 1, parent = this };
                children[2] = new Node() { x = x, z = z + size / 2, size = size / 2, level = level + 1, parent = this };
                children[3] = new Node() { x = x + size / 2, z = z + size / 2, size = size / 2, level = level + 1, parent = this };
            }
            int offset = 0;
            if (vx > x + size / 2) offset++;
            if (vz > z + size / 2) offset += 2;
            children[offset].insert(vx, vz);
        }

        public void draw(float drawScale = 1.0f)
        {

            if (children == null)
            {
                Gizmos.color = flag == 1 ? Color.red : Color.green;
                Gizmos.DrawWireCube(new Vector3(x, 0, z) * drawScale + new Vector3(size, 0, size) * 0.5f * drawScale,
                    new Vector3(size, 0.1f, size) * drawScale);
            }
            //	if(flag==1)
            //print("level:" + level + ",size:" + size  +",x:"+x+","+",z:"+z);
            if (children != null)
            {
                foreach (var item in children)
                {
                    item.draw(drawScale);
                }
            }
        }
        private void calCount(ref int count)
        {

            count += 1;
            if (children != null)
            {
                foreach (var item in children)
                {
                    item.calCount(ref count);
                }
            }
        }
        public void clipSameNode(bool recursion = true)
        {
            if (children == null) return;
            int dataCount = 0;
            foreach (var item in children)
            {
                if (item.flag == 1)
                {
                    dataCount++;
                }
            }

            if (dataCount == 4)
            {
                if (flag != 1)
                {
                    flag = 1;
                    children = null;
                    if (parent != null) parent.clipSameNode(false);
                }
            }
            else if (recursion)
            {
                foreach (var item in children)
                {
                    item.clipSameNode();
                }
            }

        }
        public List<Node> getAllNodes()
        {

            List<Node> nodes = new List<Node>();
            nodes.Add(this);
            int startIndex = 0;
            int endIndex = nodes.Count;
            while (startIndex != endIndex)
            {


                for (int i = startIndex; i < endIndex; i++)
                {
                    if (nodes[i].children != null)
                    {
                        nodes.AddRange(nodes[i].children);
                    }
                }
                startIndex = endIndex;
                endIndex = nodes.Count;
            }
            return nodes;
        }
        public void printCount()
        {
            int count = 0;
            calCount(ref count);
            print(count);
        }

        public bool find(int fx, int fz)
        {
            if (children == null)
            {
                return flag == 1;
            }
            int offset = 0;
            if (fx > x + size / 2) offset++;
            if (fz > z + size / 2) offset += 2;
            return children[offset].find(fx, fz);
        }
    }

    public Texture2D tex;
    public Light light;
    public Shader SSVolShadow;
    private Material drawMaterial;
    private RenderTexture rt_mask;
    public Transform testPoint;

    public bool clipMode;
    private List<int2> shaodws;
    public bool debugCellMode = false;
    // Use this for initialization
    void Start()
    {

        initShadowData();
    }

    private void initShadowData()
    {
        shaodws = findPosInShadow(-light.transform.forward);

        Node root = new Node();
        root.x = 0;
        root.z = 0;
        root.size = 1024;

        foreach (var item in shaodws)
        {
            root.insert(item.x, item.z);
        }

        root.clipSameNode();

        root.printCount();
        var nodes = root.getAllNodes();
        print(nodes.Count);
        int width = Mathf.CeilToInt(Mathf.Sqrt(nodes.Count));

        drawMaterial = new Material(SSVolShadow);

        rt_mask = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.R8);
        Shader.SetGlobalTexture("_TestQTreeMaskTex", rt_mask);
        tex = new Texture2D(width, width, TextureFormat.RGBAFloat, false);//其实 rfloat 就可以 但为了不想看到报错 就用rgba
        tex.filterMode = FilterMode.Point;
        tex.wrapMode = TextureWrapMode.Clamp;
        var colors = tex.GetPixels();
        //print("------");
        for (int i = 0; i < nodes.Count; i++)
        {
            nodes[i].index = i;
        }
        for (int i = 0; i < nodes.Count; i++)
        {
            // print(nodes[i].Item);
            colors[i].r = nodes[i].x;
            colors[i].g = nodes[i].z;
            colors[i].b = nodes[i].children != null ? nodes[i].children[0].index : -1;
            colors[i].a = nodes[i].flag;

        }
        tex.SetPixels(colors);
        tex.Apply();
        Shader.SetGlobalTexture("_TestQTreeTex", tex);
        Shader.SetGlobalInt("_TestQTreeWidth", width);
    }
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Graphics.Blit(src, rt_mask, drawMaterial, 0);
        Graphics.Blit(src, dest, drawMaterial, 1);
    }

    // Update is called once per frame
    void OnDrawGizmos()
    {

        Node root = new Node();
        root.x = 0;
        root.z = 0;
        root.size = 1024;
        // foreach (Transform item in testPoint)
        {
            //  root.insert(Mathf.CeilToInt(item.position.x*10), Mathf.CeilToInt(item.position.z*10));
        }
        foreach (var item in shaodws)
        {
            root.insert(item.x, item.z);
        }
        if (clipMode)
        {

            root.clipSameNode();

        }
        root.printCount();
        //root.insert(41, 82);
        float drawScale = 100 / 1000.0f;
        root.draw(drawScale);
    }
    //utils 
    public struct int2
    {
        public int x, z;
        public override string ToString()
        {
            return x + "," + z;
        }
    }
    public static List<int2> findPosInShadow(Vector3 rayDir)
    {
        //0.1米一个阴影单位
        List<int2> list = new List<int2>();
        for (int x = 0; x < 1000; x++)
        {
            for (int z = 0; z < 1000; z++)
            {
                if ((Physics.Raycast(new Vector3(x * 0.1f, 0.001f, z * 0.1f), rayDir, 100) ? 1 : 0)
                    + (Physics.Raycast(new Vector3(x * 0.1f, 0.001f, z * 0.1f) + new Vector3(-1, 0, 0) * 0.18f, rayDir, 100) ? 1 : 0)
                    + (Physics.Raycast(new Vector3(x * 0.1f, 0.001f, z * 0.1f) + new Vector3(0, -1, 0) * 0.18f, rayDir, 100) ? 1 : 0)
                    + (Physics.Raycast(new Vector3(x * 0.1f, 0.001f, z * 0.1f) + new Vector3(0, 0, -1) * 0.18f, rayDir, 100) ? 1 : 0)
                         + (Physics.Raycast(new Vector3(x * 0.1f, 0.001f, z * 0.1f) + new Vector3(1, 0, 0) * 0.18f, rayDir, 100) ? 1 : 0)
                    + (Physics.Raycast(new Vector3(x * 0.1f, 0.001f, z * 0.1f) + new Vector3(0, 1, 0) * 0.18f, rayDir, 100) ? 1 : 0)
                    + (Physics.Raycast(new Vector3(x * 0.1f, 0.001f, z * 0.1f) + new Vector3(0, 0, 1) * 0.18f, rayDir, 100) ? 1 : 0)
                    > 2
                    )
                {
                    list.Add(new int2() { x = x, z = z });
                }
            }
        }
        return list;
    }
}