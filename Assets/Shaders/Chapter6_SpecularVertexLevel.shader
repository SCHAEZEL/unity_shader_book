Shader "Unity Shaders Book/Chapter 6/Specular Vertex-Level"
{
    Properties{
        _Diffuse("Diffuse", Color) = (1.0,1.0,1.0)
        _Specular("Specular", Color) = (1.0,1.0,1.0)
        _Gloss("Gloss", Range(8.0, 256.0)) = 20
    }
    
    SubShader
    {
        Pass{
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed3 _Diffuse;
            fixed3 _Specular;
            float _Gloss;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 color : COLOR0;
            };

            v2f vert(a2v v) {
                v2f o;
                fixed4 worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                // 半兰伯特（Half Lambert）
                // fixed3 halfLambert = 0.5 * dot(worldLight, worldNormal) + 0.5; 
                float3 reflectDir = normalize(reflect(-worldLight, worldNormal));
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex));

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; 
                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldLight, worldNormal));
                // 高光 - 镜面反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = ambient + diffuse + specular;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{

                return fixed4(i.color, 1);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}
