Shader "Unity Shaders Book/Chapter 9/Forward Rendering"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Gloss ("Gloss", Range(8,256)) = 20
        _Specular ("Specular", Color) = (1,1,1,1)
    }
    SubShader
    {   
		Tags { "RenderType"="Opaque" }
        
        Pass{
            Tags { "LightMode"="ForwardBase" "RenderMode"="Not Important"}
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed _Gloss;
            fixed4 _Specular;

            struct a2v{
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                fixed4 texcoord : TEXCOORD0;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                fixed2 uv : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color;
                fixed3 halfVector = normalize(worldViewDir + worldLightDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));
                fixed3 specular = _LightColor0.rgb * _Specular * pow(saturate(dot(worldNormal, halfVector)), _Gloss);

                fixed atten = 1.0;

                fixed shadow = SHADOW_ATTENUATION(i);

                return fixed4(ambient + (diffuse + specular) * atten * shadow, 1.0);
            }
            
            ENDCG
        }

        Pass{
            Tags { "LightMode"="ForwardAdd" "RenderMode"="Not Important" }

            Blend One One

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed _Gloss;
            fixed4 _Specular;

            struct a2v{
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                fixed4 texcoord : TEXCOORD0;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                fixed2 uv : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldPos : TEXCOORD2;
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
                
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                    fixed3 atten = 1.0;
                #else
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
					#if defined (POINT)
				        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #elif defined (SPOT)
				        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w 
                                                         * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #else
                        fixed3 atten = 1.0;
                    #endif
                #endif

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color;
                fixed3 halfVector = normalize(worldViewDir + worldLightDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));
                fixed3 specular = _LightColor0.rgb * _Specular * pow(saturate(dot(worldNormal, halfVector)), _Gloss);

                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }
            
            ENDCG
        }
    }
	FallBack "Specular"
}
