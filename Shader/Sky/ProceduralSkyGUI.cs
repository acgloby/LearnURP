using UnityEditor;
using UnityEngine;

public class ProceduralSkyGUI : ShaderGUI
{
    private bool useAurora = false;
    private Material mat; 
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        useAurora = EditorGUILayout.Toggle("开启极光", useAurora);
        base.OnGUI(materialEditor, properties);
        mat = materialEditor.target as Material;
        SetKeyword("_USE_AURORA", useAurora);


    }

    private void SetKeyword(string keyword, bool enable)
    {
        if (enable)
        {
            mat.EnableKeyword(keyword);
        }
        else
        {
            mat.DisableKeyword(keyword);
        }
    }
}
