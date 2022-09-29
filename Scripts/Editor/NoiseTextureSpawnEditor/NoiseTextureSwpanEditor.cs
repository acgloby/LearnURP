using System;
using System.IO;
using UnityEditor;
using UnityEngine;

public enum NoiseType
{
    PERLIN = 0,
    SIMPLE = 1,
    CELLULAR = 2,
    FBM = 3
}

public enum ImageType
{
    JPG = 0,
    PNG = 1,
    TGA = 2,
    EXR = 3
}

public class NoiseTextureSwpanEditor : EditorFramework<NoiseTextureSwpanEditor>
{ 
    private int m_width = 512;
    private int m_height = 512;

    private float m_scale = 10;
    private float m_offsetX;
    private float m_offsetY;
    private float m_power = 1;

    private Texture2D tex2D;
    private NoiseType noiseType;
    private ImageType imageType = ImageType.PNG;
    private string savePath;
    private string textureName;

    [MenuItem("Tool/噪声贴图生成工具")]
    public static void Init()
    {
        OpenEditor();
        window.minSize = new Vector2(650, 700);
        window.titleContent = new GUIContent("噪声贴图生成工具");
    }

    protected override void OnGUI()
    {
        base.OnGUI();
        EditorGUILayout.BeginHorizontal();
        noiseType = (NoiseType)EditorGUILayout.EnumPopup("Noise类型", noiseType, GUILayout.Width(300), GUILayout.ExpandHeight(false));
        GUILayout.Space(30);
        imageType = (ImageType)EditorGUILayout.EnumPopup("图片类型", imageType, GUILayout.Width(300), GUILayout.ExpandHeight(false));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        m_width = EditorGUILayout.IntField("宽", m_width, GUILayout.Width(200), GUILayout.ExpandHeight(false));
        GUILayout.Space(130);
        m_height = EditorGUILayout.IntField("高", m_height, GUILayout.Width(200), GUILayout.ExpandHeight(false));
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.BeginHorizontal();
        m_offsetX = EditorGUILayout.FloatField("偏移X", m_offsetX, GUILayout.Width(200), GUILayout.ExpandHeight(false));
        GUILayout.Space(130);
        m_offsetY = EditorGUILayout.FloatField("偏移Y", m_offsetY, GUILayout.Width(200), GUILayout.ExpandHeight(false));
        EditorGUILayout.EndHorizontal();
        m_scale = EditorGUILayout.Slider("缩放", m_scale, 0f, 100f, GUILayout.Width(400), GUILayout.ExpandHeight(false));
        m_power = EditorGUILayout.Slider("强度", m_power, 1f, 10f, GUILayout.Width(400), GUILayout.ExpandHeight(false));
        EditorGUILayout.BeginHorizontal();
        textureName = EditorGUILayout.TextField("贴图名称", textureName, GUILayout.Width(400), GUILayout.ExpandHeight(false));
        if (GUILayout.Button("另存为",GUILayout.Width(80), GUILayout.ExpandHeight(false)))
        {
            savePath = EditorUtility.OpenFolderPanel("另存为", Application.dataPath, textureName);
        }
        if (GUILayout.Button("保存到文件", GUILayout.Width(80), GUILayout.ExpandHeight(false)))
        {
            SaveTextureFile();
        }
        EditorGUILayout.EndHorizontal();

        if (GUILayout.Button("生成贴图", GUILayout.Width(200),GUILayout.Height(30)))
        {
            tex2D = GenerateTexture();
        }
        if (!string.IsNullOrEmpty(savePath))
        {
            EditorGUILayout.LabelField(string.Format("{0}/{1}", savePath, textureName));
        }
        if (tex2D != null)
            EditorGUI.DrawPreviewTexture(new Rect(5, 160, tex2D.width, tex2D.height), tex2D);
    }

    /// <summary>
    /// 生成贴图
    /// </summary>
    /// <returns></returns>
    private Texture2D GenerateTexture()
    {
        Texture2D texture = new Texture2D(m_width, m_height);

        for (int x = 0; x < m_width; x++)
        {
            for (int y = 0; y < m_height; y++)
            {
                Color color = CalculateColor(x, y);
                texture.SetPixel(x, y, color);
            }
        }
        //保存贴图修改
        texture.Apply();

        return texture;
    }

    /// <summary>
    /// 计算噪声
    /// </summary>
    /// <param name="x"></param>
    /// <param name="y"></param>
    /// <returns></returns>
    private Color CalculateColor(int x, int y)
    {
        float xCoord = (float)x / m_width * m_scale + m_offsetX;
        float yCoord = (float)y / m_height * m_scale + m_offsetY;
        float noise = 1;
        Vector2 coord = new Vector2(xCoord, yCoord);

        switch (noiseType)
        {
            case NoiseType.PERLIN:
                noise = Mathf.PerlinNoise(xCoord, yCoord);
                break;
            case NoiseType.SIMPLE:
                noise = simple_noise(coord);
                break;
            case NoiseType.CELLULAR:
                noise = cellular_noise(coord);
                break;
            case NoiseType.FBM:
                noise = fbm_noise(coord);
                break;
        }
        noise = Mathf.Pow(noise, m_power);
        

        return new Color(noise, noise, noise);
    }

    private void SaveTextureFile()
    {
        if (tex2D == null)
            return;
        byte[] bytes = null;
        string sufixx = "";
        switch (imageType)
        {
            case ImageType.JPG:
                bytes = tex2D.EncodeToJPG();
                sufixx = "jpg";
                break;
            case ImageType.PNG:
                bytes = tex2D.EncodeToPNG();
                sufixx = "png";
                break;
            case ImageType.TGA:
                bytes = tex2D.EncodeToTGA();
                sufixx = "tga";
                break;
            case ImageType.EXR:
                bytes = tex2D.EncodeToEXR();
                sufixx = "exr";
                break;
        }
        if (bytes == null)
            return;

        if (string.IsNullOrEmpty(savePath))
            savePath = Application.dataPath;
        if (!Directory.Exists(savePath))
        {
            Directory.CreateDirectory(savePath);
        }
        if (string.IsNullOrEmpty(textureName))
        {
            File.WriteAllBytes(string.Format("{0}/{1}.{2}", savePath, DateTime.Now.ToFileTime(), sufixx), bytes);
        }
        else
        {
            File.WriteAllBytes(string.Format("{0}/{1}.{2}", savePath, textureName, sufixx), bytes);
        }
        AssetDatabase.Refresh();
    }

    #region cellular noise
    float simple_noise(Vector2 coord)
    {
        Vector2 i = floor(coord);
        Vector2 f = fract(coord);

        // 4 corners of a rectangle surrounding our point
        float tl = rand(i);
        float tr = rand(i + new Vector2(1.0f, 0.0f));
        float bl = rand(i + new Vector2(0.0f, 1.0f));
        float br = rand(i + new Vector2(1.0f, 1.0f));

        Vector2 cubic = f * f * (new Vector2(3.0f, 3.0f) - 2.0f * f);

        float topmix = mix(tl, tr, cubic.x);
        float botmix = mix(bl, br, cubic.x);
        float wholemix = mix(topmix, botmix, cubic.y);

        return wholemix;
    }
    #endregion
    #region cellular noise
    float cellular_noise(Vector2 coord)
    {
        Vector2 i = floor(coord);
        Vector2 f = fract(coord);

        float min_dist = 99999.0f;
        // going through the current tile and the tiles surrounding it
        for (float x = -1.0f; x <= 1.0; x++)
        {
            for (float y = -1.0f; y <= 1.0; y++)
            {

                // generate a random point in each tile,
                // but also account for whether it's a farther, neighbouring tile
                Vector2 node = rand2(i + new Vector2(x, y)) + new Vector2(x, y);

                // check for distance to the point in that tile
                // decide whether it's the minimum
                float dist = Mathf.Sqrt((f - node).x * (f - node).x + (f - node).y * (f - node).y);
                min_dist = Mathf.Min(min_dist, dist);
            }
        }
        return min_dist;
    }
    #endregion
    #region fbm noise
    float fbm_noise(Vector2 coord)
    {
        int OCTAVES = 4;

        float normalize_factor = 0.0f;
        float value = 0.0f;
        float scale = 0.5f;

        for (int i = 0; i < OCTAVES; i++)
        {
            value += Mathf.PerlinNoise(coord.x, coord.y) * scale;
            normalize_factor += scale;
            coord *= 2.0f;
            scale *= 0.5f;
        }
        return value / normalize_factor;
    }
    #endregion
    #region 数学库
    Vector2 mod(Vector2 coord, float a)
    {
        return new Vector2(coord.x % a, coord.y % a);
    }
    float fract(float x)
    {
        return x - Mathf.Floor(x);
    }
    Vector2 fract(Vector2 x)
    {
        return new Vector2(x.x - Mathf.Floor(x.x), x.y - Mathf.Floor(x.y));
    }
    Vector2 floor(Vector2 x)
    {
        return new Vector2(Mathf.Floor(x.x), Mathf.Floor(x.y));
    }
    float rand(Vector2 coord)
    {
        // prevents randomness decreasing from coordinates too large
        coord = mod(coord, 10000.0f);
        // returns "random" float between 0 and 1
        return fract(Mathf.Sin(Vector2.Dot(coord, new Vector2(12.9898f, 78.233f))) * 43758.5453f);
    }
    float mix(float x, float y, float level)
    {
        return x * (1 - level) + y * level;
    }
    Vector2 rand2(Vector2 coord)
    {
        // prevents randomness decreasing from coordinates too large
        coord = mod(coord, 10000.0f);
        // returns "random" vec2 with x and y between 0 and 1
        return fract((new Vector2(Mathf.Sin(Vector2.Dot(coord, new Vector2(127.1f, 311.7f))), Mathf.Sin(Vector2.Dot(coord, new Vector2(269.5f, 183.3f))))) * 43758.5453f);
    }
    #endregion

}
