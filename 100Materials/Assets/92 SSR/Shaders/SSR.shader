Shader "9 PostProcess/92 SSR"
{
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        // ZTest Off
        ZWrite Off
        // Stencil {
        //     Ref 0
        //     ReadMask 1
        //     Comp Equal
        // }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "HLSLSupport.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;  // for debug
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;

                float2 uv : TEXCOORD5;
            };

            sampler2D _ColorTex;

            sampler2D_float _DepthBuffer;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // #if UNITY_UV_STARTS_AT_TOP
                //     if (_MainTex_TexelSize.y < 0)
                //             uv.y = 1-uv.y;
                // #endif
                // float depth = SAMPLE_DEPTH_TEXTURE(_DepthBuffer, fixed2(1,1) - i.uv);
                // fixed3 color = tex2D(_ColorTex,i.uv).rgb;
				// depth = LinearEyeDepth(depth);


                half3 normalDir = half3(0,1,0);
                half3 eyeVec = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);
                // 获取反射向量
                half3 reflectDir = reflect(eyeVec, normalDir);
                float stepLength = 0;
                fixed3 color = fixed3(0,0,0);                
// // 获取视深度d
// float d = -mul(UNITY_MATRIX_V, float4(i.worldPos,1)).z;
// // 获取p的屏幕坐标ps
// float4 ps = mul(UNITY_MATRIX_VP, float4(i.worldPos,1));
// ps.xyz /= ps.w;
// ps.y *= _ProjectionParams.x;
// ps.xy = (ps.xy * 0.5 + float3(0.5,0.5,0.5));
// // 从深度图取深度ds
// float ds = SAMPLE_DEPTH_TEXTURE(_DepthBuffer, ps.xy);
// ds = LinearEyeDepth(ds);

//     // return fixed4(ds.rrr,1);
// if (ds > d)
// {    
//     return fixed4(0,0,1,1);
// }else
// {
//     return fixed4(1,1,1,1);
// }


                UNITY_LOOP
                for(int t = 0;t < 100;t++)
                {
                    // 步进取点p
                    float3 p = reflectDir * stepLength + i.worldPos;
                    // 获取点p的视深度d
                    float d = -mul(UNITY_MATRIX_V, float4(p,1)).z;
                    // 获取p的屏幕坐标ps
                    float4 ps = mul(UNITY_MATRIX_VP, float4(p,1));
                    ps.xyz /= ps.w;
                    ps.y *= _ProjectionParams.x;
                    ps.xy = (ps.xy * 0.5 + float3(0.5,0.5,0.5));
                    // 从深度图取深度ds
                    float ds = SAMPLE_DEPTH_TEXTURE(_DepthBuffer, ps.xy);
                    ds = LinearEyeDepth(ds);
                    // 对比d和ds
                    color = tex2D(_ColorTex,saturate(ps.xy)).rgb;
                    if (ds < d) 
                    {
                        // 在一定误差内就可以返回
                        break;
                    }else
                    {
                        // 否则调整步长
                        stepLength += 0.1;
                    }
                }
                return fixed4(color.rgb,1);
            }
            ENDCG
        }
    }
}
