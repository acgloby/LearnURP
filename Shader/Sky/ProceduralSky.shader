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
        _MoonMask("月亮遮罩偏移",Range(-1,1)) = 0
        
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

        [HDR]_MieColor("MieColor",Color) = (1.0, 1.0, 1.0, 1.0)
        _MieStrength("MieStrength",Range(0,1)) = 0.5
        _PlanetRadius("PlanetRadius",float) = 0.5
        _AtmosphereHeight("AtmosphereHeight",Range(0,1)) = 0.5
        _DensityScaleHeight("DensityScaleHeight",Range(0,1)) = 0.5
        _ExtinctionM("ExtinctionM",Range(0,1)) = 0.5
        _MieG("MieG",Range(0,1)) = 0.5
        _ScatteringM("ScatteringM",Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Background"
            "RenderQueue" = "Background"
            "PreviewType" = "Skybox"
        }

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
            half _MoonMask;

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

            half4 _MieColor;
            half _MieStrength;
            half _PlanetRadius;
            half _AtmosphereHeight;
            half _DensityScaleHeight;
            half _ExtinctionM;
            half _MieG;
            half _ScatteringM;

            uniform Matrix LToW;
            uniform float4 DayColor_0;
            uniform float4 DayColor_1;
            uniform float4 DayColor_2;
            uniform float4 NightColor_0;
            uniform float4 NightColor_1;
            uniform float4 NightColor_2;
            uniform float4 CloudDirection;
            uniform float TimeSpeed;

            half MiePhaseFunction(half cosAngle)
            {
                half g = _MieG;
                half g2 = g * g;
                half phase = (1.0 / (4.0 * PI)) * ((3.0 * (1.0 - g2)) / (2.0 * (2.0 + g2))) * ((1 + cosAngle * cosAngle) / (pow((1 + g2 - 2 * g*cosAngle), 3.0 / 2.0)));
                return phase;
            }

            void ComputeOutLocalDensity(half3 position, half3 lightDir, out half localDPA, out half DPC)
            {
                half3 planetCenter = half3(0,-_PlanetRadius,0);
                half height = distance(position,planetCenter) - _PlanetRadius;
                localDPA = exp(-(height/_DensityScaleHeight));

                DPC = 0;
            }
            half4 IntegrateInscattering(half3 rayStart,half3 rayDir,half rayLength, half3 lightDir,half sampleCount)
            {
                half3 stepVector = rayDir * (rayLength / sampleCount);
                half stepSize = length(stepVector);

                half scatterMie = 0;

                half densityCP = 0;
                half densityPA = 0;
                half localDPA = 0;

                half prevLocalDPA = 0;
                half prevTransmittance = 0;
                
                ComputeOutLocalDensity(rayStart,lightDir, localDPA, densityCP);
                
                densityPA += localDPA*stepSize;
                prevLocalDPA = localDPA;

                half Transmittance = exp(-(densityCP + densityPA)*_ExtinctionM)*localDPA;
                
                prevTransmittance = Transmittance;
                

                for(half i = 1.0; i < sampleCount; i += 1.0)
                {
                    half3 P = rayStart + stepVector * i;
                    
                    ComputeOutLocalDensity(P,lightDir,localDPA,densityCP);
                    densityPA += (prevLocalDPA + localDPA) * stepSize/2;

                    Transmittance = exp(-(densityCP + densityPA)*_ExtinctionM)*localDPA;

                    scatterMie += (prevTransmittance + Transmittance) * stepSize/2;
                    
                    prevTransmittance = Transmittance;
                    prevLocalDPA = localDPA;
                }

                scatterMie = scatterMie * MiePhaseFunction(dot(rayDir,-lightDir.xyz));

                half3 lightInscatter = _ScatteringM*scatterMie;

                return half4(lightInscatter,1);
            }
            half2 RaySphereIntersection(half3 rayOrigin, half3 rayDir, half3 sphereCenter, half sphereRadius) 
            {
                rayOrigin -= sphereCenter;

                half a = dot(rayDir, rayDir);
                half b = 2.0 * dot(rayOrigin, rayDir);
                half c = dot(rayOrigin, rayOrigin) - (sphereRadius * sphereRadius);

                half d = b * b - 4 * a * c;

                if (d < 0)
                {
                    return -1;
                }
                else
                {
                    d = sqrt(d);
                    return half2(-b - d, -b + d) / (2 * a);
                }
            }


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
                half2 moonUV = sunUV.xy * _MoonTex_ST.xy * (1 / _MoonSize + 0.0001) + _MoonTex_ST.zw;
                half4 moonTex = SAMPLE_TEXTURE2D(_MoonTex, sampler_MoonTex, moonUV);
                half4 moonMaskTex = SAMPLE_TEXTURE2D(_MoonTex, sampler_MoonTex, moonUV + half2(_MoonMask,0));
                half3 finalMoonColor = (_MoonColor.rgb * moonTex.rgb * moonTex.a) * step(0,sunUV.z);
                half3 moonMask = max(0,1 - (moonMaskTex.a * step(0,sunUV.z)));
                finalMoonColor *= moonMask;
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
                half3 finalSunInfColor = _SunInfColor.rgb * sunMask * _SunInfScale * sunInfScaleMask;
                //----------------------------------------------
                
                //---------------   地平线  -----------------
                half horzionWidth = lerp(_NightHorWidth, _DayHorWidth, sunNightStep);
                half horzionStrenth = lerp(_NightHorStrenth, _DayHorStrenth, sunNightStep);
                half horzionMask = smoothstep(-horzionWidth,0,i.uv.y) * smoothstep(-horzionWidth,0,-i.uv.y);
                half3 horzionColor = lerp(_NightHorColor, _DayHorColor, sunNightStep);
                half3 finalSkyColor = skyColor * (1 - horzionMask) + horzionColor * horzionMask * horzionStrenth;
                //----------------------------------------------

                //---------------   星空  -----------------
                half3 normalizeWorldPos = normalize(i.worldPos);
                half2 skyuv = normalizeWorldPos.xz / max(0,normalizeWorldPos.y);
                half4 starNoiseTex = SAMPLE_TEXTURE2D(_StarNoiseTex, sampler_StarNoiseTex, skyuv * _StarNoiseTex_ST.xy + (_StarNoiseTex_ST.zw - _MainLightPosition.xy * _StarSpeed * _Time.x));
                half starNoise = step(starNoiseTex.r,0.7);
                half4 starTex = SAMPLE_TEXTURE2D(_StarTex, sampler_StarTex, skyuv * _StarTex_ST.xy + (_StarTex_ST.zw + half2(0, -1) * _StarSpeed * TimeSpeed * _Time.x));
                half3 starColor = starTex.rbg * _StarColor * starNoise;
                half skyMask = saturate(1 - smoothstep(-0.7,0,-i.uv.y));
                half3 starMask = lerp(skyMask,0,sunNightStep);
                starColor *= starMask * (1 - moonTex.a);
                //----------------------------------------------
                
                //---------------   云   -----------------
                half2 cloudMoveDir = half2(CloudDirection.xy * _CloudSpeed * _Time.x);
                half4 cloudNoiseTex1 = SAMPLE_TEXTURE2D(_CloudNoiseTex1, sampler_CloudNoiseTex1, skyuv * _CloudNoiseTex1_ST.xy + (_CloudNoiseTex1_ST.zw - CloudDirection.xy * _CloudNoiseSpeed * _Time.x) + cloudMoveDir);
                half4 cloudNoiseTex2 = SAMPLE_TEXTURE2D(_CloudNoiseTex2, sampler_CloudNoiseTex2, skyuv * _CloudNoiseTex2_ST.xy + (_CloudNoiseTex2_ST.zw + CloudDirection.xy * _CloudNoiseSpeed * _Time.x) + cloudMoveDir);
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

                //--------------- 大气散射 -----------------
                //参考代码
                //https://zhuanlan.zhihu.com/p/237502022
                //https://zhuanlan.zhihu.com/p/540692272
                float3 scatteringColor = 0;

                float3 rayStart = float3(0,0.6,0);
                float3 rayDir = normalize(i.uv.xyz);

                float3 planetCenter = float3(0, -_PlanetRadius, 0);
                float2 intersection = RaySphereIntersection(rayStart,rayDir,planetCenter,_PlanetRadius + _AtmosphereHeight);
                float rayLength = intersection.y;

                intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius);
                if (intersection.x > 0)
                    rayLength = min(rayLength, intersection.x*100);

                float4 inscattering = IntegrateInscattering(rayStart, rayDir, rayLength, -light.direction.xyz, 16);
                scatteringColor = _MieColor * _MieStrength * inscattering.rgb;
                //---------------------------------------------
                
                half3 fragColor = finalSkyColor + finalSunInfColor + finalSunColor + finalMoonColor + starColor + cloudColor + scatteringColor;
                return half4(fragColor,1.0);
            }
            ENDHLSL
        }
    }
}
