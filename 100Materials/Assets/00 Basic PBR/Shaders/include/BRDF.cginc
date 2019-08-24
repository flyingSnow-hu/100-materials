#ifndef __BRDF_CGINC__
#define __BRDF_CGINC__

#include "UnityStandardBRDF.cginc"

inline half _D(half3 halfDir, half3 normalDir, half roughness)
{
    half alpha = roughness * roughness;
    half squAlpha = alpha * alpha;
    half nh = dot(normalDir,halfDir);
    half d = (nh * nh * (squAlpha - 1) + 1);
    return squAlpha/(UNITY_PI * d * d);
}

/// 实际 G1 的倒数，并且省略了 nd，和外面的 nl nv 抵消
inline half _G1(half3 d, half3 normalDir, half k)
{
    half nd = dot(normalDir,d);
    return nd * (1 - k) + k;
}

inline half _G_direct(half3 lightDir, half3 viewDir, half3 normalDir, half roughness)
{
    half r1 = (roughness + 1);
    half k = (r1 * r1) / 8;
    return _G1(lightDir,normalDir,k) * _G1(viewDir,normalDir,k);
}

inline half3 _F(half3 f0, half3 vh)
{
    return f0 + (1 - f0) * exp2((-5.55473 * vh - 6.98316) * vh);
}

float3 RoughnessF(float3 f0, float roughness, float nv)
{
    float oneMinusRoughness = 1.0 - roughness;
    return f0 + (max(float3(oneMinusRoughness, oneMinusRoughness, oneMinusRoughness), f0) - f0) * exp2((-5.55473 * nv - 6.98316) * nv);
}

inline half3 BRDF(half3 normalDir, half3 lightDir, half3 viewDir, half roughness, half3 f0)
{
    half3 halfDir = normalize(lightDir + viewDir);
    half vh = saturate(dot(viewDir,halfDir));
    return _F(f0, vh) * _D(halfDir, normalDir, roughness) * 0.25 /
           _G_direct(lightDir, viewDir, normalDir, roughness);
}

half3 IndirectDiffuse(half3 albedo, half3 normalDir, half roughness, half f0, half metallic, half nv)
{
    half3 ambient_contrib = ShadeSH9(float4(normalDir, 1));
    float3 ambient = 0.03 * albedo;
    float3 iblDiffuse = max(half3(0, 0, 0), ambient.rgb + ambient_contrib);
    float kdLast = (1 - RoughnessF(f0, roughness, nv)) * (1 - metallic);
    return iblDiffuse * kdLast * albedo;
}

half3 IndirectSpecular(half smoothness, half perceptualRoughness, half roughness, half3 viewDir, half3 normalDir, 
    half3 oneMinusReflectivity, half3 f0, half nv)
{    
    float mip_roughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
    float3 reflectVec = reflect(-viewDir, normalDir);
    half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;
    half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip); 
    float3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);

#   ifdef UNITY_COLORSPACE_GAMMA
        float surfaceReduction = 1.0 - 0.28 * roughness * perceptualRoughness;  //Gamma空间
#   else
        float surfaceReduction = 1.0 / (roughness*roughness + 1.0); //Linear空间
#   endif

    float grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
    return iblSpecular * surfaceReduction * FresnelLerp(f0, grazingTerm, nv);
}

#endif