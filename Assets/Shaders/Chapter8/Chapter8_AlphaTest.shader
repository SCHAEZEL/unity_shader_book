Shader "Unity Shaders Book/Chapter 7/Alpha Test"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" }

        Pass{
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed _Cutoff;

            struct a2v {
                float4 vertex : POSITION;
                fixed2 texcoord : TEXCOORD0;
                fixed3 normal : TEXCOORD1;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                fixed2 uv : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }   


            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // fixed3 worldViewDir = UnityWorldSpaceViewDir(i.worldPos);

                fixed4 texColor = tex2D(_MainTex, i.uv);
                clip(texColor.a - _Cutoff);

                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0 * albedo * saturate(dot(worldNormal, worldLightDir));
                return fixed4(ambient + diffuse, 1.0);
            }

            ENDCG
        }   
    }
    FallBack "Transparent/Cutout/VertexLit"
}

