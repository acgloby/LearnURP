Shader "URPDemo/PBR"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _MainColor ("Color", color) = (1.0,1.0,1.0,1.0)
        _NormalTex ("Normal Texture", 2D) = "bump" {}
        _NormalScale("Normal Scale", float) = 1.0
        _AOTex ("AO Texture", 2D) = "white" {}
        _RoughnessTex ("Roughness Texture", 2D) = "white" {}
        _MetallicTex ("Metallic Texture", 2D) = "white" {}
        _Roughness("Roughness",Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "PBRFunction.hlsl"


            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD01;
                float3 normal : TEXCOORD2;
                float3 tangent : TEXCOORD3;
                float3 bitangent : TEXCOORD4;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            float4 _NormalTex_ST;

            TEXTURE2D(_AOTex);
            SAMPLER(sampler_AOTex);
            float4 _AOTex_ST;

            TEXTURE2D(_RoughnessTex);
            SAMPLER(sampler_RoughnessTex);
            float4 _RoughnessTex_ST;

            TEXTURE2D(_MetallicTex);
            SAMPLER(sampler_MetallicTex);
            float4 _MetallicTex_ST;

            half4 _MainColor;
            float _NormalScale;
            float _Roughness;
            float _Metallic;



            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.position = TransformObjectToHClip(v.vertex);
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.normal = normalize(TransformObjectToWorldNormal(v.normal));
                o.tangent = normalize(TransformObjectToWorld(v.tangent));
                o.bitangent = normalize(cross(o.normal,o.tangent)) * v.tangent.w * unity_WorldTransformParams.w;
                o.uv = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 baseTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv * _MainTex_ST.xy + _MainTex_ST.zw);
                half4 aoTex = SAMPLE_TEXTURE2D(_AOTex,sampler_AOTex,i.uv*_AOTex_ST.xy+_AOTex_ST.zw);
                half4 roughnessTex = SAMPLE_TEXTURE2D(_RoughnessTex,sampler_RoughnessTex,i.uv*_RoughnessTex_ST.xy+_RoughnessTex_ST.zw);
                half4 metallicTex = SAMPLE_TEXTURE2D(_MetallicTex,sampler_MetallicTex,i.uv*_MetallicTex_ST.xy+_MetallicTex_ST.zw);
                half4 normalTex = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv);
                half3 unpack_normal = UnpackNormal(normalTex);
                Light light = GetMainLight();
                half3 lightColor = light.color;

                half3 Albedo = baseTex.rgb * _MainColor;
                half Ao = aoTex.r;
                half Roughness = roughnessTex.r * _Roughness;
                half Smoothness = 1 - Roughness;
                half Metallic = metallicTex.a * _Metallic;


                half3 N = normalize(unpack_normal.x * i.tangent * _NormalScale + unpack_normal.y * i.bitangent * _NormalScale + unpack_normal.z * i.normal);
                half3 L = normalize(light.direction);
                half3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 H = normalize(V + L);
                half3 R = reflect(-L, N);

                half NdotV = max(dot(N, V), 0.000001);
                half NdotL = max(dot(N, L), 0.000001);
                half NdotH = max(dot(N, H), 0.000001);
                half HdotV = max(dot(H, V), 0.000001);
                half HdotL = max(dot(H, L), 0.000001);

                half3 F0 = half3(0.04, 0.04, 0.04);
                F0 = lerp(F0, Albedo, Metallic);

                half D = D_Function(NdotH, Roughness);
                half G = G_Function(NdotL, NdotV, Roughness);
                half3 F = F_Function(HdotL, F0);
                //直接光高光
                half3 directSpecular = D * G * F / (4.0 * NdotL * NdotV);

                half3 kS = F;
                half3 kD = (1-kS)*(1-Metallic);
                //直接光漫反射
                half3 directDiffuse = kD*Albedo*lightColor*NdotL;

                //直接光颜色
                half3 directColor = directDiffuse + directSpecular;

                //间接光漫反射
                half3 shColor = SH_IndirectionDiffuse(N)*Ao;
                half3 indirKS = IndirFresnelSchlick(NdotV,F0,Roughness);
                half3 indirKD = (1-indirKS)*(1-Metallic);
                half3 indirDiffuseColor = shColor*indirKD*Albedo;
                
                //间接光高光
                half3 indirSpecularCubeColor = IndirSpecularCube(N,V,Roughness,Ao);
                half3 indirSpecularCubeFactor = IndirSpecularFactor(Roughness,Smoothness,directSpecular,F0,NdotV);
                half3 indirSpecularColor = indirSpecularCubeColor * indirSpecularCubeFactor;
                
                //间接光颜色
                half3 indirColor = indirSpecularColor + indirDiffuseColor;

                half3 fragColor = directColor + indirColor;

                return half4(fragColor,1.0);
            }
            ENDHLSL
        }
    }
}
