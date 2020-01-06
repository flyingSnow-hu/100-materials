using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public class GrabTexInCamera : MonoBehaviour
{
    private readonly int COLOR_ID = Shader.PropertyToID("_ColorTex");
    private readonly int DEPTH_ID = Shader.PropertyToID("_DepthBuffer");
    public Material GrabDepthMat = null;
    new private Camera camera;
    private RenderTexture target;
    private RenderTexture targetDepth;

    private void OnEnable() 
    {
        camera = GetComponent<Camera>();
        camera.depthTextureMode = DepthTextureMode.None;
        
        target = RenderTexture.GetTemporary(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.ARGB32);
        targetDepth = RenderTexture.GetTemporary(camera.pixelWidth, camera.pixelHeight, 24, RenderTextureFormat.Depth);
        camera.SetTargetBuffers(target.colorBuffer, targetDepth.depthBuffer);  

        var cmdBufferOpaque = new CommandBuffer();
        cmdBufferOpaque.name = "BlitOpaque";
        cmdBufferOpaque.GetTemporaryRT(COLOR_ID,camera.pixelWidth, camera.pixelHeight,0,FilterMode.Bilinear,GraphicsFormat.B10G11R11_UFloatPack32);
        cmdBufferOpaque.GetTemporaryRT(DEPTH_ID,camera.pixelWidth, camera.pixelHeight,0,FilterMode.Point,GraphicsFormat.R16_SFloat);
        cmdBufferOpaque.Blit(target.colorBuffer,COLOR_ID);
        cmdBufferOpaque.Blit(targetDepth.depthBuffer,DEPTH_ID);
        camera.AddCommandBuffer(CameraEvent.AfterSkybox,cmdBufferOpaque);

        
        var cmdBufferAll = new CommandBuffer();
        cmdBufferAll.name = "BlitToScreen";
        cmdBufferAll.Clear();
        cmdBufferAll.Blit(target.colorBuffer, BuiltinRenderTextureType.CameraTarget);
        camera.AddCommandBuffer(CameraEvent.AfterEverything,cmdBufferAll);
    }

    private void OnDisable() 
    { 
        RenderTexture.ReleaseTemporary(target);    
        RenderTexture.ReleaseTemporary(targetDepth);    
    }
}
