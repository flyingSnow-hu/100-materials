// *********
// Basic PBR Shader
// by flyingsnow.hu@gmail.com 
// TODO Shadow
// TODO Lightmap
// TODO 法线贴图
// TODO Add Pass
// TODO AO && Emission
// *********

Shader "Unlit/PBRBase"
{
    Properties
    {
        _Diffuse ("Texture", 2D) = "white" {}
        _TintColor ("Tint Color", Color) = (1,1,1,1)
        [Normal][NoScaleOffset]_Normal ("Normal", 2D) = "bump" {}
        [NoScaleOffset]_Metallic ("Metallic (R)", 2D) = "white" {}
        [NoScaleOffset]_Smoothness ("Smoothness (G)", 2D) = "white" {}
        [NoScaleOffset]_AO ("AO (B)", 2D) = "white" {}
        [NoScaleOffset]_MetallicScale ("Metallic Scale", Range(0,1)) = 1
        [NoScaleOffset]_SmoothnessScale ("Smoothness Scale", Range(0,1)) = 1
        [NoScaleOffset]_AOScale ("AO Scale", Range(0,1)) = 1
        [NoScaleOffset]_Emission ("Emission",2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "./include/BRDF.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos:TEXCOORD1;

                float3 normal : TEXCOORD2;
                float3 tangent : TEXCOORD3;
                float3 binormal : TEXCOORD4;

                // UNITY_SHADOW_COORDS(5)
            };

            texture2D _Diffuse,_Normal,_Metallic,_Smoothness,_AO,_Emission;
            SamplerState sampler_Diffuse;
            float4 _Diffuse_ST;
            half _MetallicScale,_SmoothnessScale,_AOScale;
            half4 _TintColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Diffuse);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
                o.binormal = normalize(cross(o.normal,o.tangent) * v.tangent.w);
                // UNITY_TRANSFER_SHADOW(o,v.uv1);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 color = _Diffuse.Sample(sampler_Diffuse,i.uv) * _TintColor;
                half3 albedo = color.rgb;
                half alpha = color.a;
                
                half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                half3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                half3 halfDir = normalize(viewDir + lightDir);
                half3 tangentNormal = UnpackNormal(_Normal.Sample(sampler_Diffuse, i.uv));
                
                half3 normalDir = normalize(
                                    tangentNormal.x * i.tangent +
                                    tangentNormal.y * i.binormal +
                                    tangentNormal.z * i.normal
                                );

                half nv = max(dot(normalDir, viewDir), 0.0);
                half nl = saturate(dot(normalDir,lightDir));

                half metallic = _Metallic.Sample(sampler_Diffuse,i.uv).r * _MetallicScale;
                half smoothness = _Smoothness.Sample(sampler_Diffuse,i.uv).g * _SmoothnessScale;
                half ao = _AO.Sample(sampler_Diffuse,i.uv).b * _AOScale;
                
                half perceptualRoughness =  1 - smoothness;
                half roughness = sqrt(max(0.002, perceptualRoughness));

                half3 f0; half oneMinusReflectivity;
                albedo = DiffuseAndSpecularFromMetallic (albedo, metallic, /* out */f0, /* out */oneMinusReflectivity);

                half3 diffuse = albedo * oneMinusReflectivity;
                half3 specBRDF = BRDF(normalDir, lightDir, viewDir,  roughness, f0);
                half3 specular = specBRDF  * UNITY_PI;
                half3 direct = (diffuse + specular) * _LightColor0.rgb * nl;

                half3 indirectDiffuse = IndirectDiffuse(albedo, normalDir, roughness, f0, metallic, nv);
                half3 indirectSpecular = IndirectSpecular(smoothness, perceptualRoughness, roughness, viewDir, normalDir, 
                                                          oneMinusReflectivity, f0, nv);
                
                float3 indirect = indirectDiffuse + indirectSpecular;

                fixed4 col;
                col.rgb = direct + indirect;
                col.a = alpha;
                return col;
            }
            ENDCG
        }
    }
}
