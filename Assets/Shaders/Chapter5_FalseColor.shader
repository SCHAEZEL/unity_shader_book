Shader "Unity Shaders Book/Chapter 5/False Color"
{
    SubShader
    {
        Pass{
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f{
                float4 pos : SV_POSITION;
                fixed4 color : COLOR0;
            };

			v2f vert(appdata_full v) {
                fixed3 offset = fixed3(0.5,0.5,0.5);
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = fixed4(v.normal * 0.5 + offset, 1.0);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                return fixed4(i.color);
            }
            ENDCG
        }
    }
}
