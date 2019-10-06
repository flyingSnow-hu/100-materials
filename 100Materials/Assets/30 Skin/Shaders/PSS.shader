Shader "30 Skin/PSS"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Normal]_NormalTex ("Normal", 2D) = "bump" {}
        _LUTTex ("LUT Texture", 2D) = "white" {}
        _RadiusScale ("Radius Scale", Float) = 1
        _Shiness ("Shiness", Float) = 100
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD1;
                float3 binormal : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };

            sampler2D _MainTex, _NormalTex, _LUTTex;
            float4 _MainTex_ST;
            float _RadiusScale;
            float _Shiness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.binormal = cross(o.normal, o.tangent) * v.tangent.w;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;

                float3x3 tbn = float3x3(i.tangent, i.binormal, i.normal);
                half3 tanNormal0 = UnpackNormal(tex2D(_NormalTex, i.uv));
                half3 worldNormal0 = normalize(mul(tanNormal0, tbn));

                half3 tanNormal3 = Unity_SafeNormalize(UnpackNormal(tex2Dbias(_NormalTex, float4(i.uv,0,10))));
                half3 worldNormal3 = normalize(mul(tanNormal3, tbn));

                // diffuse
                half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                half nl = saturate(dot(lightDir, worldNormal3)*0.5+0.5);
                half reverseR = saturate(_RadiusScale * length(fwidth(worldNormal3)) / length(fwidth(i.worldPos)));
                half3 lut = tex2D(_LUTTex, float2(nl,reverseR)).rgb;
                half3 diffuse = albedo * _LightColor0.xyz * lut;

                // Blinn-Phong Specular
                half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                half3 halfDir = normalize(lightDir + viewDir);
                half nh = saturate(dot(worldNormal0, halfDir));
                half3 specular = 0.2 * _LightColor0.xyz * pow(nh, _Shiness);

                fixed4 color = fixed4(diffuse + specular, 1);

                return color;
            }
            ENDCG
        }
    }
}
