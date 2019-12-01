using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class GrabTexInCamera : MonoBehaviour
{
    public Material GrabDepthMat = null;
    new private Camera camera;
    private RenderTexture target;
    private RenderTexture targetDepth;

    private void OnEnable() 
    {
        camera = GetComponent<Camera>();
        camera.depthTextureMode = DepthTextureMode.None;
        
        target = RenderTexture.GetTemporary(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.Default);
        targetDepth = RenderTexture.GetTemporary(camera.pixelWidth, camera.pixelHeight, 24, RenderTextureFormat.Depth);
        camera.SetTargetBuffers(target.colorBuffer, targetDepth.depthBuffer);  
        Shader.SetGlobalTexture("_DepthBuffer", targetDepth);

        // var cmdBuffer = new CommandBuffer();
        // cmdBuffer.name = "AfterSkyBox";
        // cmdBuffer.SetGlobalTexture("_DepthBuffer", targetDepth);
        // camera.AddCommandBuffer(CameraEvent.AfterSkybox,cmdBuffer);

        var cmdBuffer = new CommandBuffer();
        cmdBuffer.name = "BlitAll";
        cmdBuffer.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CameraTarget);
        camera.AddCommandBuffer(CameraEvent.AfterSkybox,cmdBuffer);
    }

    private void OnDisable() 
    {        
    }
}
