// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 10/Reflection" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_ReflectionColor ("Reflection Color", Color) = (1, 1, 1, 1)
		_ReflectionAmount ("Reflection Amount", Range(0, 1)) = 1
		_CubeMap ("Reflection CubeMap", Cube) = "_SkyBox" {}
	}
	SubShader {	
		Pass {
			CGPROGRAM

			#pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos    : TEXCOORD1;
				float3 worldRefl   : TEXCOORD2;
				float3 worldViewDir: TEXCOORD3;

				SHADOW_COORDS(2)
			};

			fixed4 _Color;
			fixed4 _ReflectionColor;
			fixed _ReflectionAmount;
			samplerCUBE _CubeMap;
			
			v2f vert(a2v v) {
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.worldViewDir = UnityWorldSpaceViewDir(o.worldNormal);
				
				o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

				TRANSFER_SHADOW(o);

				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 worldViewDir = normalize(i.worldViewDir);
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
				fixed3 reflection = texCUBE(_CubeMap, i.worldRefl).rgb * _ReflectionColor.rgb;

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				fixed3 color = ambient + lerp(diffuse, reflection, _ReflectionAmount) * atten;

				return fixed4(color, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Specular"
}