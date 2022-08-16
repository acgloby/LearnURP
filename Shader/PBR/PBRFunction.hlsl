#ifndef PBR_Function_INCLUDE
#define PBR_Function_INCLUDE

//D项 法线微表面分布函数 
half D_Function(half NdotH,half roughness)
{
    half a2 = roughness * roughness;
    half dotNH2 = NdotH * NdotH;
    
    //分子
    half nom = a2;
    //分母
    half denom = dotNH2 * (a2 - 1) + 1;
    denom = denom * denom * PI;
    return nom / denom;
}

//G项子项
half G_Section(half dot,half k)
{
    half nom = dot;
    half denom = lerp(dot, 1, k);
    return nom / denom;
}

//G项
half G_Function(half NdotL,half NdotV,half roughness)
{
    half k = pow(1 + roughness, 2) / 8;
    half gnl = G_Section(NdotL, k);
    half gnv = G_Section(NdotV, k);
    return gnl * gnv;
}

//F项 直接光
half3 F_Function(half HdotL,half3 F0)
{
    half fresnel = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
    return lerp(fresnel, 1, F0);
}

//F项 间接光
half3 IndirFresnelSchlick(half NdotV,half3 F0,half roughness)
{
    half Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
    return F0 + Fre * saturate(1 - roughness - F0);
}

//间接光漫反射 球谐函数 光照探针
half3 SH_IndirectionDiffuse(half3 normalWS)
{
    float4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;
    float3 color = SampleSH9(SHCoefficients, normalWS);
    return max(0, color);
}

//间接光高光 反射探针
half3 IndirSpecularCube(half3 normalWS, half3 viewWS, half roughness, half AO)
{
    half3 reflectDirWS = reflect(-viewWS, normalWS);
    //Unity内部不是线性 调整下拟合曲线求近似
    roughness = roughness * (1.7 - 0.7 * roughness);
    //把粗糙度remap到0-6 7个阶级 然后进行lod采样
    half lod = roughness * 6;
    //根据不同的等级进行采样 
    half4 specColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, lod);
    #if !defined(UNITY_USE_NATIVE_HDR)
    //用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，
    //解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
    return DecodeHDREnvironment(specColor, unity_SpecCube0_HDR) * AO;
    #else
    return specColor.rgb * AO;
    #endif
}

//间接高光 曲线拟合 放弃LUT采样而使用曲线拟合
half3 IndirSpecularFactor(half roughness,half smoothness,half3 BRDFSpecular,half3 F0,half NdotV)
{
    #ifdef UNITY_COLORSPACE_GAMMA
    half surReduction = 1 - 0.28 * roughness * roughness;
    #else
    half surReduction = 1 / (roughness * roughness + 1);
    #endif
    //Lighting.hlsl 274行
    #if defined(SHADER_API_GLES)
    half reflectivity = BRDFSpecular.r;
    #else
    half reflectivity = max(max(BRDFSpecular.r, BRDFSpecular.g), BRDFSpecular.b);
    #endif
    half grazingTSection = saturate(reflectivity + smoothness);
    //lighting.hlsl第512行
    half fresnel = Pow4(1 - NdotV);
    return lerp(F0, grazingTSection, fresnel) * surReduction;
}


#endif