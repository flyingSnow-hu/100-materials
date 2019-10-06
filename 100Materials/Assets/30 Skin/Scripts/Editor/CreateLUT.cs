using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class CreateLUT
{
    [MenuItem("Skin/PreIntegrated LUT")]
    public static void CreatePILUT()
    {
        string path = "/30 Skin/Textures/PILUT.png";
        const int texSize = 512;

        Texture2D tex = new Texture2D(texSize, texSize, TextureFormat.RGB24, mipChain:false, linear:true);
        var target = RenderTexture.GetTemporary(texSize, texSize, 0, RenderTextureFormat.ARGB32);
        var mat = new Material(Shader.Find("Editor/LUTCreator"));
        Graphics.Blit(tex,target,mat);
        RenderTexture.active = target;
        tex.ReadPixels(new Rect(0, 0, texSize, texSize), 0, 0);
        System.IO.File.WriteAllBytes(Application.dataPath + path, tex.EncodeToPNG());
        AssetDatabase.Refresh();
    }
}
