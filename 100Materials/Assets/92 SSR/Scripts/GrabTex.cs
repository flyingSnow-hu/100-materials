using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class GrabTex : MonoBehaviour
{
    public Material GrabDepthMat = null;
    new private Camera camera;
    private CommandBuffer commandBuffer;

    private void OnEnable() 
    {
        if (commandBuffer != null) return;

        if (commandBuffer == null) GrabDepthMat = new Material(Shader.Find("Hidden/GrabDepth"));

        camera = GetComponent<Camera>();
        camera.depthTextureMode = DepthTextureMode.None;

        commandBuffer = new CommandBuffer();
        commandBuffer.name = "GrabDepth";
        int depthID = Shader.PropertyToID("_DepthBuffer");
        commandBuffer.GetTemporaryRT(depthID, -1, -1, 16, FilterMode.Bilinear, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        commandBuffer.Blit(BuiltinRenderTextureType.None, depthID, GrabDepthMat);
        commandBuffer.SetGlobalTexture("_DepthBuffer", depthID);

        camera.AddCommandBuffer(CameraEvent.BeforeForwardAlpha, commandBuffer);
    }

    private void OnDisable() 
    {        
        if (commandBuffer == null) return;

        camera.RemoveCommandBuffers(CameraEvent.BeforeForwardAlpha);
        commandBuffer = null;
    }
}
