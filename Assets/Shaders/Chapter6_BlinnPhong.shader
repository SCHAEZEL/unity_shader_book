Shader "Unity Shaders Book/Chapter 6/Blinn-Phong"
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
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v) {
                v2f o;
                o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul((float3x3)unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                float3 reflectDir = normalize(reflect(-worldLight, i.worldNormal));
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfVector = normalize(worldLight + viewDir);

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; 
                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldLight, i.worldNormal));
                // 高光 - 镜面反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(i.worldNormal, halfVector)), _Gloss);

                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}
