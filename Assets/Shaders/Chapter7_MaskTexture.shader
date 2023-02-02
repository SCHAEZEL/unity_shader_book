Shader "Unity Shaders Book/Chapter 7/Mask Texture"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _BumpMap ("BumpTex", 2D) = "bump" {}
        _BumpScale ("BumpScale", Float) = 1.0
        _Specular ("Specular", Color) = (1,1,1,1)
        _SpecularMask ("SpecularMask", 2D) = "white"{}
        _SpecularScale ("SpecularScale", Float) = 1.0
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
            float _BumpScale;
            fixed4 _Specular;
            sampler2D _SpecularMask;
            float _SpecularScale;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                float4 tangent : TANGENT;
                fixed4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                fixed2 uv : TEXCOORD0;
                fixed3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.lightDir);
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv.xy));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 halfVector = normalize(tangentLightDir + tangentViewDir);
                fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));
                // 高光 - 镜面反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfVector)), _Gloss) * specularMask;
                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}