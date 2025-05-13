#ifndef FOTH_PBS_HLSL
#define FOTH_PBS_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

float distributionGGX(float3 N, float3 H, float roughness)
{
    float a = roughness * roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float nom    = a2;
    float denom  = (NdotH2 * (a2 - 1.0) + 1.0);
    denom        = PI * denom * denom;
	
    return nom / denom;
}

float3 fresnelSchlick(float HoV, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - HoV, 5.0);
} 

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float nom   = NdotV;
    float denom = NdotV * (1.0 - roughness) + roughness;
	
    return nom / denom;
}
  
float geometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx1 = GeometrySchlickGGX(NdotV, roughness); // 视线方向的几何遮挡
    float ggx2 = GeometrySchlickGGX(NdotL, roughness); // 光线方向的几何阴影
	
    return ggx1 * ggx2;
}

float3 CookTorranceBRDF( float3 baseColor, float metallic, float roughness, float3 normal, float3 lightDir, float3 viewDir)
{
    float3 H = ( viewDir + lightDir )/2;
    
    float3 f0 = float3(0.04,0.04,0.04);
    f0 = lerp(f0, baseColor, metallic);

    float3 F = fresnelSchlick(max( dot(H, viewDir), 0.0), f0);

    float D = distributionGGX(normal, H, roughness);

    float G = geometrySmith(normal, viewDir, lightDir, roughness);

    float NoL = dot(normal, lightDir);
    float NoV = dot(normal, viewDir);
    
    float3 nom = D * F * G;
    float denom = 4 * max(NoV, 0.0) * max(NoL, 0.0);

    float3 specular = nom / max( denom , 1e-5);

    float3 ks = F ;
    float3 kd = float3(1.0,1.0,1.0) - ks;
    kd *= 1.0 - metallic;

    float3 color = (kd * baseColor + specular) * NoL;

    return color;
    
}

// float metallic = otherData.r;
// float ao = otherData.b;
// float roughness = otherData.a;
// roughness *= 0.2;
//                 
// float3 H = (viewDirWS + lightDirectionWS)/2;
//
//
// float3 f0 = float3(0.04,0.04,0.04);
// f0 = lerp(f0, baseColor, metallic);
//                 
//                 
// float3 F = fresnelSchlick(max(dot(H,viewDirWS), 0.0), f0);
//
// float3 ks = F;
//
// float3 kd = float3(1,1,1) - ks;
// // kd *= (1.0 - metallic);
//  
// float3 pixelNormalTS;
// pixelNormalTS.xyz = otherData2.rgb;
// // pixelNormalTS.z = sqrt(1.0 - saturate( dot(pixelNormalTS.xy, pixelNormalTS.xy) ) );
// // return float4(pixelNormalTS,1);
// float3 pixelNormalWS = TransformTangentToWorld(pixelNormalTS, float3x3(tangentWS,bitangentWS,normalWS));
// pixelNormalWS = normalize(pixelNormalWS);
//
//
//
// float NDF = distributionGGX(pixelNormalWS, H, roughness);
// float G = geometrySmith(pixelNormalWS, viewDirWS, lightDirectionWS, roughness);
//
// float3 num = NDF * G * F  ;
//                 
// float NoL = max(dot(pixelNormalWS,lightDirectionWS), 0.0);
//                 
//                 
// float denom = 4.0 * max(dot(pixelNormalWS,viewDirWS), 0.0) * NoL;
//
// float3 specular = num / max(denom,1e-5);
//
// kd = 0.5 * kd + 0.5;
// baseColor = ( kd * baseColor+ specular) * NoL;

#endif