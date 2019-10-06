Shader "Editor/LUTCreator"
{
    Properties
    {
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float3 ToneMapping(float3 color)
            {
                float3 offset0 = float3(0.004,0.004,0.004);
                float3 offset1 = float3(0.5,0.5,0.5);
                float3 offset2 = float3(1.7,1.7,1.7);
                float3 offset3 = float3(0.06,0.06,0.06);
                float3 x = max(0, color-offset0);
                return (x*(6.2*x+offset1))/(x*(6.2*x+offset2)+offset3);
            }

            float G(float r, float v)
            {
                float vv = 2 * v;
                float exponent = -r * r / vv;
                return exp(exponent) / (vv * UNITY_PI);
            }

            float3 R(float r)
            {
                return float3(0.233, 0.455, 0.649) * G(r, 0.0064) + 
                       float3(0.100, 0.336, 0.344) * G(r, 0.0484) + 
                       float3(0.118, 0.198, 0    ) * G(r, 0.187 ) + 
                       float3(0.113, 0.007, 0.007) * G(r, 0.567 ) + 
                       float3(0.358, 0.004, 0    ) * G(r, 1.99  ) + 
                       float3(0.078, 0    , 0    ) * G(r, 7.41  ); 
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float theta = acos(i.uv.x * 2 - 1);
                float curvature = 1 / max(0.001, i.uv.y);
                float3 totalLight = 0;
                float3 totalWeight = 0;

                for (float x = -UNITY_PI/2; x < UNITY_PI/2; x+=0.01)
                {                    
                    float distance = abs(2 * curvature * sin(x / 2));
                    float3 weight = R(distance);
                    totalLight += saturate(cos(theta + x)) * weight;
                    totalWeight += weight;
                }

                float3 color = totalLight / totalWeight;
                color = ToneMapping(color);
                return fixed4(color.rgb, 1);
            }
            ENDCG
        }
    }
}
