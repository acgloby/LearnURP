Shader "URPDemo/ProceduralSky"
{
    Properties
    {
        _SunSize("太阳大小", Range(0,1)) = 0.5
        [HDR]_SunColor("太阳颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _SunInnerBoundary("太阳内圈" , Range(0,0.5)) = 0.4
        _SunOuterBoundary("太阳外圈", Range(0.5,1)) = 0.5
        
        [Space(20)]
        _MoonTex("月亮贴图", 2D) = "black" {}
        [HDR]_MoonColor("月亮颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _MoonSize("月亮大小", Range(0.1,1)) = 0.5
        
        [Space(20)]
        _StarTex("星空贴图", 2D) = "black" {}
        _StarNoiseTex("星空噪声贴图", 2D) = "white" {}
        [HDR]_StarColor("星星颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _StarSpeed("星星闪烁速度", float) = 1

        [Space(20)]
        _SunInfColor("大气颜色",Color) = (1.0, 1.0, 1.0, 1.0)
        _SunInfScale("大气范围",Range(0, 1)) = 0.5

        [Space(20)]
        _CloudColor("云颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _CloudColorHight("高层云颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _CloudNoiseTex1("云噪声贴图1", 2D) = "white" {}
        _CloudNoiseTex2("云噪声贴图2", 2D) = "white" {}
        _CloudSpeed("云速度", float) = 1
        _CloudNoiseSpeed("云扰动速度", float) = 1
        _CloudStep("底层云云范围", Range(0,0.5)) = 0.5
        _Fuzziness("底层云模糊度", Range(0.1,1)) = 0.5
        _CloudStepHight("高层云云范围", Range(0,0.5)) = 0.5
        _FuzzinessHight("高层云模糊度", Range(0.1,1)) = 0.5

        [Space(20)]
        _DayHorWidth("地平线白天宽度",Range(0,1)) = 0.5
        _NightHorWidth("地平线夜晚宽度",Range(0,1)) = 0.5
        _DayHorStrenth("地平线白天强度",Range(0,1)) = 0.5
        _NightHorStrenth("地平线夜晚强度",Range(0,1)) = 0.5
        [HDR]_DayHorColor("地平线白天颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        [HDR]_NightHorColor("地平线夜晚颜色", Color) = (0.0, 0.0, 0.0, 1.0)

    }
    SubShader
    {
        Tags { "RenderType" = "Background" "RenderQueue" = "Background" "PreviewType" = "Skybox"}

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD01;
            };

            
            half _SunSize;
            half _SunInnerBoundary;
            half _SunOuterBoundary;
            half4 _SunColor;

            TEXTURE2D(_StarTex);
            SAMPLER(sampler_StarTex);
            float4 _StarTex_ST;
            TEXTURE2D(_StarNoiseTex);
            SAMPLER(sampler_StarNoiseTex);
            float4 _StarNoiseTex_ST;

            TEXTURE2D(_MoonTex);
            SAMPLER(sampler_MoonTex);
            float4 _MoonTex_ST;
            half4 _MoonColor;
            half _MoonSize;

            half4 _StarColor;
            half _StarSpeed;

            half4 _SunInfColor;
            half _SunInfScale;

            half _CloudSpeed;
            half _CloudNoiseSpeed;
            half4 _CloudColor;
            half4 _CloudColorHight;
            TEXTURE2D(_CloudNoiseTex1);
            SAMPLER(sampler_CloudNoiseTex1);
            float4 _CloudNoiseTex1_ST;
            TEXTURE2D(_CloudNoiseTex2);
            SAMPLER(sampler_CloudNoiseTex2);
            float4 _CloudNoiseTex2_ST;
            half _CloudStep;
            half _Fuzziness;
            half _CloudStepHight;
            half _FuzzinessHight;

            half _DayHorWidth;
            half _NightHorWidth;
            half _DayHorStrenth;
            half _NightHorStrenth;
            half4 _DayHorColor;
            half4 _NightHorColor;

            uniform Matrix LToW;
            uniform float4 DayColor_0;
            uniform float4 DayColor_1;
            uniform float4 DayColor_2;
            uniform float4 NightColor_0;
            uniform float4 NightColor_1;
            uniform float4 NightColor_2;

            v2f vert (appdata v)
            {
                v2f o;
                o.position = TransformObjectToHClip(v.vertex);
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.uv = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                Light light = GetMainLight();

                //---------------   太阳  -----------------
                float sunDist = distance(i.uv.xyz , _MainLightPosition.xyz);
                float sunArea = 1 - sunDist / _SunSize;
                sunArea = smoothstep(_SunInnerBoundary, _SunOuterBoundary, sunArea);
                half3 fallSunColor = half3(_SunColor.r, _SunColor.g * 0.4, _SunColor.b * 0.4);
                half3 finalSunColor = lerp(fallSunColor,_SunColor.rgb,smoothstep(-0.03,0.03,_MainLightPosition.y)) * sunArea;
                //----------------------------------------------

                //---------------   月亮  -----------------
                half3 sunUV = mul(i.uv.xyz, LToW);
                half2 moonUV = sunUV.xy * _MoonTex_ST.xy * (1 / _MoonSize + 0.001) + _MoonTex_ST.zw;
                half4 moonTex = SAMPLE_TEXTURE2D(_MoonTex, sampler_MoonTex, moonUV);
                half3 finalMoonColor = (_MoonColor.rgb * moonTex.rgb * moonTex.a) * step(0,sunUV.z);
                //----------------------------------------------

                //---------------   天空颜色  -----------------
                half3 dayTopColor = lerp(DayColor_1, DayColor_0, saturate(i.uv.y)) * step(0,i.uv.y);
                half3 dayBottomColor = lerp(DayColor_1, DayColor_2, saturate(-i.uv.y)) * step(0,-i.uv.y);
                half3 dayColor = saturate(dayTopColor + dayBottomColor);

                half3 nightTopColor = lerp(NightColor_1, NightColor_0, saturate(i.uv.y))*step(0,i.uv.y);
                half3 nightBottomColor = lerp(NightColor_1, NightColor_2, saturate(-i.uv.y))*step(0,-i.uv.y);
                half3 nightColor = saturate(nightTopColor + nightBottomColor);
                
                half sunNightStep = smoothstep(-0.3,0.25,_MainLightPosition.y);
                half3 skyColor = lerp(nightColor, dayColor, sunNightStep);
                //--------------------------------------------------

                //---------------   大气  -----------------
                half sunMask = smoothstep(-0.4,0.4,-mul(i.uv.xyz,LToW).z) - 0.3;
                half sunInfScaleMask = smoothstep(-0.01,0.1,_MainLightPosition.y) * smoothstep(-0.4,-0.01,-_MainLightPosition.y);
                half3 finalSunInfColor = _SunInfColor * sunMask * _SunInfScale * sunInfScaleMask;
                //----------------------------------------------
                
                //---------------   地平线  -----------------
                half horzionWidth = lerp(_NightHorWidth, _DayHorWidth, sunNightStep);
                half horzionStrenth = lerp(_NightHorStrenth, _DayHorStrenth, sunNightStep);
                half horzionMask = smoothstep(-horzionWidth,0,i.uv.y) * smoothstep(-horzionWidth,0,-i.uv.y);
                half3 horzionColor = lerp(_NightHorColor, _DayHorColor, sunNightStep);
                half3 finalSkyColor = skyColor * (1 - horzionMask) + horzionColor * horzionMask * horzionStrenth;
                //----------------------------------------------

                //---------------   星空，云  -----------------
                half3 normalizeWorldPos = normalize(i.worldPos);
                half2 skyuv = normalizeWorldPos.xz / max(0,normalizeWorldPos.y);
                half4 starNoiseTex = SAMPLE_TEXTURE2D(_StarNoiseTex, sampler_StarNoiseTex, skyuv * _StarNoiseTex_ST.xy + (_StarNoiseTex_ST.zw - _MainLightPosition.xy * _StarSpeed * _Time.x));
                half starNoise = step(starNoiseTex.r,0.7);
                half4 starTex = SAMPLE_TEXTURE2D(_StarTex, sampler_StarTex, skyuv * _StarTex_ST.xy + (_StarTex_ST.zw + _MainLightPosition.xy * _StarSpeed * _Time.x));
                half3 starColor = starTex.rbg * _StarColor * starNoise;
                half skyMask = saturate(1 - smoothstep(-0.7,0,-i.uv.y));
                half3 starMask = lerp(skyMask,0,sunNightStep);
                starColor *= starMask * (1 - moonTex.a);
                
                half2 cloudMoveDir = half2(_MainLightPosition.xy * _CloudSpeed * _Time.x);
                half4 cloudNoiseTex1 = SAMPLE_TEXTURE2D(_CloudNoiseTex1, sampler_CloudNoiseTex1, skyuv * _CloudNoiseTex1_ST.xy + (_CloudNoiseTex1_ST.zw - _MainLightPosition.xy * _CloudNoiseSpeed * _Time.x) + cloudMoveDir);
                half4 cloudNoiseTex2 = SAMPLE_TEXTURE2D(_CloudNoiseTex2, sampler_CloudNoiseTex2, skyuv * _CloudNoiseTex2_ST.xy + (_CloudNoiseTex2_ST.zw + _MainLightPosition.xy * _CloudNoiseSpeed * _Time.x) + cloudMoveDir);
                half cloudNoise1 = cloudNoiseTex1.r;
                half cloudNoise2 = cloudNoiseTex2.r;
                
                half cloudNoiseLow = saturate(smoothstep(_CloudStep * cloudNoiseTex1.r + _Fuzziness, _CloudStep * cloudNoise1, cloudNoise1));
                half cloudNoiseHight = saturate(smoothstep(_CloudStepHight * cloudNoiseTex2.r + _FuzzinessHight, _CloudStepHight * cloudNoise2, cloudNoise2));
                half3 cloudColorLow = (_CloudColor * light.color) * cloudNoiseLow * skyMask;
                half3 cloudColorHight = (_CloudColorHight * light.color) * cloudNoiseHight * skyMask;
                half3 cloudColor = cloudColorLow + cloudColorHight;
                //星星置于云后
                starColor *= (1 - saturate(cloudNoiseLow + cloudNoiseHight));
                //----------------------------------------------
                
                half3 fragColor = finalSkyColor + finalSunInfColor + finalSunColor + finalMoonColor + starColor + cloudColor;
                return half4(fragColor,1.0);
            }
            ENDHLSL
        }
    }
}
