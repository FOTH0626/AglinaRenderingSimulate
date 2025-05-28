#ifndef FOTH_DISNEY_BRDF_HLSL
#define FOTH_DISNEY_BRDF_HLSL
// # variables go here...
// # [type] [name] [min val] [max val] [default val]
// ::begin parameters
// color baseColor .82 .67 .16
// float metallic 0 1 0
// float subsurface 0 1 0
// float specular 0 1 .5
// float roughness 0 1 .5
// float specularTint 0 1 0
// float anisotropic 0 1 0
// float sheen 0 1 0
// float sheenTint 0 1 .5
// float clearcoat 0 1 0
// float clearcoatGloss 0 1 1
// ::end parameters

#define MY_PI 3.1415926

struct DisneyBrdfData
{
    float3 albedo;
    float metallic;
    float subSurface;
    float specular;
    float roughness;
    float specularTint;
    float anisotropic;
    float sheen;
    float sheenTint;
    float clearcoat;
    float clearcoatGloss;
};

float pow2 (float x ){return  x*x;}

float FresnelSchlick ( float u )
{
    float m = clamp(1-u,0,1);
    
    return pow(m ,5);
}

float GTR1(float NoH, float a)
{
    if (a >= 1) {return 1/MY_PI;}

    float a2 = a * a;
    float t = 1 + (a2 - 1) * NoH * NoH;
    return (a2 -1)/(MY_PI * log(a2) * t);
}
float GTR2(float NoH, float a)
{
    float a2 = a * a;
    float t = 1 + (a2 - 1) * NoH * NoH;
    return a2/(MY_PI * t * t);
}

float GTR2_aniso(float NoH, float Hox, float Hoy, float ax, float ay)
{
    return  1/ (MY_PI * ax * ay * pow2( pow2(Hox/ax) + pow2(Hoy/ay) + NoH*NoH) );
}

float SmithG_GGX(float NoV, float alphaG)
{
    float a = alphaG * alphaG;
    float b = NoV * NoV;
    return 1 / (NoV + sqrt(a + b - a * b));
}

float smithG_GGX_aniso(float NoV, float VoX, float VoY, float ax, float ay)
{
    return 1/( NoV + sqrt( pow2(VoX*ax) + pow2(VoY*ay) + pow2(NoV) ) );
}

float3 mon2lin(float3 x)
{
    return pow(x,2.2);
}

//X -> tangent , Y -> bitangent
float3 DisneyBrdf(float3 lightDir, float3 viewDir, float3 normal, float3 X, float3 Y, DisneyBrdfData brdfData)
{
    float NoL = dot(normal, lightDir);
    float NoV = dot(normal, viewDir);

    if(NoL <= 0 || NoV <= 0)
    {
        return float3(0,0,0);
    }

    float3 H = normalize(lightDir + viewDir);

    float NoH = dot(normal, H);
    float LoH = dot(lightDir, H);

    float3 albedo = brdfData.albedo;
    float metallic = brdfData.metallic;
    float subSurface = brdfData.subSurface;
    float specular = brdfData.specular;
    float roughness = brdfData.roughness;
    float specularTint = brdfData.specularTint; 
    float anisotropic = brdfData.anisotropic;
    float sheen = brdfData.sheen;
    float sheenTint = brdfData.sheenTint;
    float clearcoat = brdfData.clearcoat;
    float clearcoatGloss = brdfData.clearcoatGloss;

    float3 Cdlin = mon2lin(albedo);
    float Cdlum = dot(Cdlin, float3(0.3, 0.6, 0.1));//aluminance approx.

    float3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : float3(1,1,1);
    float3 Cspec0 = lerp(specular*.08*lerp(float3(1,1,1),Ctint,specularTint), Cdlin, metallic);
    float3 Csheen = lerp(float3(1,1,1), Ctint, sheenTint);

    float FL = FresnelSchlick(NoL);
    float FV = FresnelSchlick(NoV);

    float Fd90 = 0.5 + 2 * LoH * LoH * roughness;
    float Fd = lerp(1., Fd90, FL) * lerp(1., Fd90, FV);

    float Fss90 = LoH * LoH * roughness;
    float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    float ss = 1.25 * (Fss * (1/(NoL + NoV) - .5) + 0.5);

    float aspect = sqrt(1 - anisotropic * 0.9);
    float ax = max(1e-3, pow2(roughness)/aspect);
    float ay = max(1e-3, pow2(roughness)*aspect);
    float Ds = GTR2_aniso(NoH,dot(H,X), dot(H,Y), ax, ay);
    float FH = FresnelSchlick(LoH);
    float3 Fs = lerp(Cspec0, float3(1,1,1), FH);
    float Gs = smithG_GGX_aniso(NoL,dot(lightDir,X), dot(lightDir,Y), ax, ay);
    Gs *= smithG_GGX_aniso(NoV, dot(viewDir,X), dot(viewDir,Y), ax, ay);

    float3 Fsheen = FH * sheen * Csheen;

    float Dr = GTR1(NoH,lerp(0.1,0.001,clearcoatGloss));
    float Fr = lerp(0.04,1.0,FH);
    float Gr = SmithG_GGX(NoL, 0.25) * SmithG_GGX(NoV, 0.25);

    
    float3 color = ( (1/MY_PI) * lerp(Fd, ss, subSurface)*Cdlin + Fsheen ) * (1- metallic) + Gs * Fs * Ds + 0.25*clearcoat*Gr*Fr *Dr; 

    return color;
}

#endif