#ifndef FOTH_PBS_HLSL
#define FOTH_PBS_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

float _pbrSpecularStrength;

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
    float r = roughness + 1;
    float k = r * r /8.0;
    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
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

float3 TrickedCookTorranceBRDF( float3 baseColor, float metallic, float roughness, float3 normal, float3 lightDir, float3 viewDir)
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

    //the _pbrSpecularStrength is a not physically correct trick  
    float3 color = (kd * baseColor  + _pbrSpecularStrength * specular) * NoL;

    return color;

}



#endif