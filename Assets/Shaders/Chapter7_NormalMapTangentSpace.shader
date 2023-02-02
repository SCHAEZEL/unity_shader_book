Shader "Unity Shaders Book/Chapter 7/Normal Map Tangent Space"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", float) = 1.0
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8,256)) = 20
    }

    SubShader
    {
        Pass{
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            float4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                float4 tangent : TANGENT;
                fixed4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                fixed3 lightDir : TEXCOORD0;
                fixed3 viewDir : TEXCOORD1;
                fixed4 uv : TEXCOORD2;
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                fixed3 binormal = cross(v.tangent.xyz, v.normal) * v.tangent.w;
                float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed3 albedo = tex2D(_MainTex, i.uv.xy) * _Color;
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);

                // fixed3 tangentNormal;
				// tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				// tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 halfVector = normalize(tangentLightDir + tangentViewDir);

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; 

                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(tangentLightDir, tangentNormal));
                // 高光 - 镜面反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfVector)), _Gloss);
                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}


