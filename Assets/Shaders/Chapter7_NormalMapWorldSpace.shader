Shader "Unity Shaders Book/Chapter 7/Normal Map World Space"
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
                fixed4 uv : TEXCOORD0;
                float4 T2W0 : TEXCOORD1;
                float4 T2W1 : TEXCOORD2;
                float4 T2W2 : TEXCOORD3;
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);
                fixed3 worldNormal = UnityObjectToWorldDir(v.normal);
                fixed3 worldBinormal = cross(worldTangent.xyz, worldNormal) * v.tangent.w;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);

                o.T2W0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.T2W1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.T2W2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                float3x3 rotation = float3x3(i.T2W0.xyz, i.T2W1.xyz, i.T2W2.xyz);
                float3 worldPos = float3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 albedo = tex2D(_MainTex, i.uv.xy) * _Color;
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                // bump = normalize(half3(dot(i.T2W0.xyz, bump), dot(i.T2W1.xyz, bump), dot(i.T2W2.xyz, bump)));
                bump = mul(rotation, bump);


                fixed3 halfVector = normalize(worldLightDir + worldViewDir);

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; 

                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(bump, worldLightDir));
                // 高光 - 镜面反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump, halfVector)), _Gloss);
                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}