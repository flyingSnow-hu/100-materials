Shader "Debug/Hide"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGINCLUDE

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
        };

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            return o;
        }

        v2f vert_expand (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex * 1.03);
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            return fixed4(1,0,0,1);
        }
        ENDCG

        Pass
        {
            Stencil {
                Ref 1
                Comp always
                Pass replace
            }
            ColorMask 0
            ZTest Off
            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }

        Pass
        {
            Stencil {
                Ref 1
                Comp NotEqual
                Pass Replace
                Fail Zero
            }

            ZTest Off
            ZWrite On

            CGPROGRAM
            #pragma vertex vert_expand
            #pragma fragment frag
            ENDCG
        }
    }
}
