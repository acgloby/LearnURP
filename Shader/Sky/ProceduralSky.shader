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
        [HDR]_SunInfColor("大气颜色",Color) = (1.0, 1.0, 1.0, 1.0)
        _SunInfScale("大气范围",Range(0, 1)) = 0.5

        [Space(20)]
        _CloudColor("云颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _CloudNoiseTex1("云噪声贴图1", 2D) = "white" {}
        _CloudOffset("云偏移",Range(-1,1)) = 0
        _CloudSpeed("云速度", float) = 1
        _CloudNoiseSpeed("云扰动速度", float) = 1
        _LitStrength("LitStrength" ,Range(0,1)) = 0.5
        _BackLitStrength("BackLitStrength" ,Range(0,1)) = 0.5
        _EdgeLitStrength("EdgeLitStrength" ,Range(0,1)) = 0.5
        _CloudPower("云密度", Range(1,10)) = 2




        [Space(20)]
        _DayHorWidth("地平线白天宽度",Range(0,1)) = 0.5
        _NightHorWidth("地平线夜晚宽度",Range(0,1)) = 0.5
        _DayHorStrenth("地平线白天强度",Range(0,1)) = 0.5
        _NightHorStrenth("地平线夜晚强度",Range(0,1)) = 0.5
        _DayHorColor("地平线白天颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _NightHorColor("地平线夜晚颜色", Color) = (0.0, 0.0, 0.0, 1.0)

        [HDR]_MieColor("MieColor",Color) = (1.0, 1.0, 1.0, 1.0)
        _MieStrength("MieStrength",Range(0,1)) = 0.5
        _PlanetRadius("PlanetRadius",float) = 0.5
        _AtmosphereHeight("AtmosphereHeight",Range(0,1)) = 0.5
        _DensityScaleHeight("DensityScaleHeight",Range(0.5,1)) = 0.6
        _ExtinctionM("ExtinctionM",Range(0,1)) = 0.5
        _MieG("MieG",Range(0,1)) = 0.5
        _ScatteringM("ScatteringM",Range(0,1)) = 0.5

        _AuroraColorSeed("AuroraColorSeed",Range(0,1)) = 0.5
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
            //开启北极光
            #pragma shader_feature _USE_AURORA

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

            half _CloudOffset;
            half _CloudSpeed;
            half _CloudNoiseSpeed;
            half4 _CloudColor;
            TEXTURE2D(_CloudNoiseTex1);
            SAMPLER(sampler_CloudNoiseTex1);
            float4 _CloudNoiseTex1_ST;
            half _LitStrength;
            half _BackLitStrength;
            half _EdgeLitStrength;
            half _CloudPower;


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

            half _AuroraColorSeed;

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

            
            // 带状极光
            // From https://www.shadertoy.com/view/XtGGRt
            // Author: nimitz
            float2x2 mm2(in float a)
            {
                float c = cos(a);
                float s = sin(a);
                return float2x2(c,s,-s,c);
            }
            float tri(in float x)
            {
                return clamp(abs(frac(x)-.5),0.01,0.49);
            }
            float2 tri2(in float2 p)
            {
                return float2(tri(p.x)+tri(p.y),tri(p.y+tri(p.x)));
            }

            float triNoise2d(in float2 p, float spd)
            {
                float z=1.8;
                float z2=2.5;
                float rz = 0.;
                p = mul(p, mm2(p.x*0.06));
                float2 bp = p;
                for (float i=0.; i<5.; i++ )
                {
                    float2 dg = tri2(bp*1.85)*.75;
                    dg = mul(dg, mm2(_Time.y*spd));
                    p -= dg/z2;

                    bp *= 1.3;
                    z2 *= .45;
                    z *= .42;
                    p *= 1.21 + (rz-1.0)*.02;
                    
                    rz += tri(p.x+tri(p.y))*z;
                    p = mul(p, -float2x2(0.95534, 0.29552, -0.29552, 0.95534));
                }
                return clamp(1./pow(rz*29., 1.3),0.,.55);
            }

            float hash21(in float2 n)
            { 
                return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
            }
            float4 aurora(float3 ro, float3 rd)
            {
                float4 col = 0;
                float4 avgCol = 0;
                
                for(float i=0.;i<50.;i++)
                {
                    float of = 0.006*hash21(rd.xy)*smoothstep(0.,15., i);
                    float pt = ((.8+pow(i,1.4)*.002)-ro.y)/(rd.y*2.+0.4);
                    pt -= of;
                    float3 bpos = ro + pt*rd;
                    float2 p = bpos.zx;
                    float rzt = triNoise2d(p, 0.06);
                    float4 col2 = float4(0,0,0, rzt);
                    col2.rgb = (sin(1.-float3(2.15,-.5, 1.2)+i * 0.043 * _AuroraColorSeed)*0.5+0.5)*rzt;
                    avgCol =  lerp(avgCol, col2, .5);
                    col += avgCol*exp2(-i*0.065 - 2.5)*smoothstep(0.,5., i);			
                }		
                col *= (clamp(rd.y*15.+.4,0.,1.));
                return col*1.8;
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
                half sunDist = distance(i.uv.xyz , _MainLightPosition.xyz);
                half sunArea = 1 - sunDist / _SunSize;
                sunArea = smoothstep(_SunInnerBoundary, _SunOuterBoundary, sunArea);
                half3 fallSunColor = half3(_SunColor.r, _SunColor.g * 0.4, _SunColor.b * 0.4);
                half3 finalSunColor = lerp(fallSunColor,_SunColor.rgb,smoothstep(-0.03,0.03,_MainLightPosition.y)) * sunArea;
                //太阳光晕
                half3 sunLight = saturate((1 - sunDist - 0.4)) * (1 - sunArea);
                finalSunColor = lerp(finalSunColor,sunLight,sunLight.r);
                //----------------------------------------------

                //---------------   月亮  -----------------
                half3 sunUV = mul(i.uv.xyz, LToW);
                half2 moonUV = sunUV.xy * _MoonTex_ST.xy * -1 * (1 / (_MoonSize + 0.0001)) + _MoonTex_ST.zw;
                moonUV = moonUV * 0.5 + 0.5;
                half4 moonTex = SAMPLE_TEXTURE2D(_MoonTex, sampler_MoonTex, moonUV);
                half4 moonMaskTex = SAMPLE_TEXTURE2D(_MoonTex, sampler_MoonTex, moonUV + half2(_MoonMask,0));
                half moonMask = max(0,1 - (moonMaskTex.a * step(0,sunUV.z))) * moonTex.a * step(0,sunUV.z);
                half3 finalMoonColor = _MoonColor.rgb * moonTex.rgb * moonMask;
                half moonDist = distance(i.uv.xyz , -_MainLightPosition.xyz);
                half3 moonLight = saturate((1 - moonDist - 0.4)) * (1 - moonMask);
                finalMoonColor = lerp(finalMoonColor,moonLight,moonLight.r);
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
                half4 finalSunInfColor = _SunInfColor * sunMask * _SunInfScale * sunInfScaleMask;
                //----------------------------------------------
                
                //---------------   地平线  -----------------
                half horzionWidth = lerp(_NightHorWidth, _DayHorWidth, sunNightStep);
                half horzionStrenth = lerp(_NightHorStrenth, _DayHorStrenth, sunNightStep);
                half horzionMask = smoothstep(-horzionWidth,0,i.uv.y) * smoothstep(-horzionWidth,0,-i.uv.y);
                half3 horzionColor = lerp(_NightHorColor, _DayHorColor, sunNightStep);
                half3 finalSkyColor = lerp(skyColor, horzionColor, horzionMask * horzionStrenth);
                //----------------------------------------------

                //---------------   星空  -----------------
                half3 normalizeWorldPos = normalize(i.worldPos);
                half2 skyuv = normalizeWorldPos.xz / max(0,normalizeWorldPos.y);
                half4 starNoiseTex = SAMPLE_TEXTURE2D(_StarNoiseTex, sampler_StarNoiseTex, skyuv * _StarNoiseTex_ST.xy + (_StarNoiseTex_ST.zw - _MainLightPosition.xy * _StarSpeed * _Time.x));
                half starNoise = step(starNoiseTex.r,0.7);
                half4 starTex = SAMPLE_TEXTURE2D(_StarTex, sampler_StarTex, skyuv * _StarTex_ST.xy + (_StarTex_ST.zw + half2(0, -1) * _StarSpeed * TimeSpeed * _Time.x));
                half3 starColor = starTex.rbg * _StarColor * starNoise;
                half skyMask = saturate(1 - smoothstep(-0.7,0,-i.uv.y));
                half starMask = lerp(skyMask,0,sunNightStep);
                starColor *= starMask * (1 - moonTex.a);
                //----------------------------------------------
                
                //---------------   云   -----------------
                half2 clouduv = normalizeWorldPos.xz / max(0,normalizeWorldPos.y + 0.2);
                half2 cloudMoveDir = half2(CloudDirection.xy * _CloudSpeed * _Time.x);
                half2 cloudOffset1 = _CloudNoiseTex1_ST.zw - CloudDirection.xy * _CloudNoiseSpeed * _Time.x + cloudMoveDir;
                half4 cloudNoiseTex1 = SAMPLE_TEXTURE2D(_CloudNoiseTex1, sampler_CloudNoiseTex1, clouduv * _CloudNoiseTex1_ST.xy + cloudOffset1);
                half4 cloudNoiseTex12 = SAMPLE_TEXTURE2D(_CloudNoiseTex1, sampler_CloudNoiseTex1, clouduv * _CloudNoiseTex1_ST.xy + cloudOffset1 - half2(_CloudOffset,_CloudOffset));
                half4 cloudNoiseTex13 = SAMPLE_TEXTURE2D(_CloudNoiseTex1, sampler_CloudNoiseTex1, clouduv * _CloudNoiseTex1_ST.xy + cloudOffset1 + half2(_CloudOffset,_CloudOffset));

                half stepCloud = cloudNoiseTex1.r * cloudNoiseTex12.r;
                half cloudLight = saturate(cloudNoiseTex1.r - cloudNoiseTex12.r) * _LitStrength;
                half cloudBackLight = saturate(cloudNoiseTex1.r - cloudNoiseTex13.r) * _BackLitStrength;
                half cloudEdgeLight = pow(1 - cloudNoiseTex1.r,4) * _EdgeLitStrength;
                half finalCloudLight = (cloudLight + cloudBackLight + cloudEdgeLight);
                stepCloud = pow(stepCloud,_CloudPower);
                finalCloudLight = pow(finalCloudLight,_CloudPower);
                half cloudMask = skyMask * stepCloud;
                half3 cloudColor = lerp(_CloudColor,light.color.rgb,finalCloudLight);
              
                //星星、月亮、太阳置于云后
                starColor *= (1 - cloudMask);
                finalMoonColor *= (1 - cloudMask);
                finalSunColor *= (1 - cloudMask);
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

                half4 inscattering = IntegrateInscattering(rayStart, rayDir, rayLength, -light.direction.xyz, 16);
                scatteringColor = _MieColor * _MieStrength * inscattering.rgb * sunNightStep;
                //---------------------------------------------

                //---------------  极光  ------------------
                // 极光消耗巨大,不适用
                #if _USE_AURORA
                    half3 n = normalize(i.uv);
                    half4 auroraCol = smoothstep(0, 1.5, aurora(float3(0, 0, -6.7), n)) * skyMask;
                #endif
                //---------------------------------------------

                half3 fragColor = finalSkyColor + starColor + scatteringColor + finalSunColor + finalMoonColor;
                fragColor = lerp(fragColor,finalSunInfColor,finalSunInfColor.a);
                //fragColor = lerp(fragColor,finalSunColor,sunArea * sunNightStep);
                // fragColor = lerp(fragColor,finalMoonColor,moonMask);
                fragColor = lerp(fragColor,cloudColor,cloudMask);
                #if _USE_AURORA
                    fragColor = lerp(fragColor,auroraCol.rgb,auroraCol.a * (1 - sunNightStep));
                #endif
               
                return half4(fragColor,1.0);
            }
            ENDHLSL
        }
    }
    CustomEditor "ProceduralSkyGUI"
}
