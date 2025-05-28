Shader "Foth/Aglina"
{
    Properties
    {
        [KeywordEnum(None,Face,Eye,Body,Cloth,Hair)] _Domain("Domain", FLoat) = 0
        
        [Header(MainMap)]
        _Color ("MainColor",Color) = (1,1,1,1)
        [NoScaleOffset]_BaseColorTex ("BaseColor", 2D) = "black"{}
        [NoScaleOffset]_RampMap ("Ramp",2D) = "white"{}
        [NoScaleOffset]_OtherTex ("Other Texture",2D) = "white"{}
        [NoScaleOffset]_OtherTex2 ("Other Texture 2",2D) = "white"{}
        [NoScaleOffset]_OtherTex3 ("Other Texture 3",2D) = "white"{}
        [NoScaleOffset]_OtherTex4 ("Other Texture 4",2D) = "white"{}
        
        [HideInInspector]_HeadCenter  ("Head Center",Vector)  = (0,0,0)
        [HideInInspector]_HeadForward ("Head Forward",Vector) = (0,0,0)
        [HideInInspector]_HeadRight   ("Head Right",Vector)   = (0,0,0)       
        
        
        [Space(10)]
        _EmissionColor("Emission Color",Color) = (1,1,1,1)
        _EmissionIntensity("Emission Intensity",Range(1,10)) = 1

        [Header(DisneyPBR)]
        _Subsurface ("Subsurface", Range(0,1)) = 0
        _Specular ("Specular", Range(0,1)) = 0.5
        _SpecularTint ("Specular Tint", Range(0,1)) = 0
        _Anisotropic ("Anisotropic", Range(0,1)) = 0
        _Sheen ("Sheen", Range(0,1)) = 0
        _SheenTint ("Sheen Tint", Range(0,1)) = 0.5
        _Clearcoat ("Clearcoat", Range(0,1)) = 0
        _ClearcoatGloss ("Clearcoat Gloss", Range(0,1)) = 1
        
        [Header(Hair)]
        _PrimaryShift("Primary Shift",Range(0,1)) = 0
        _SpecularColor("Specular Color",Color) = (1,1,1,1)
        _SpecExponent("Specular Exponent",Range(1,10)) = 1
        _SpecularThreshold("Specular Threshold",Range(0,0.2)) = 0
        _SpecularRange ("Specular Range", Range(0,1)) = 0.01

        
        
        
        [Space(30)]
        _AlphaClip("Alpha Clipping",Range(0,1))=0.333
        
        [Header(Outline)]
        [Toggle(_OUTLINE_PASS)] _Outline("Outline",Float) = 1
        _OutlineColor ("Outline Color ",Color)=(0,0,0,1)
        _OutlineWidth ("Outline Width",Range(0,10)) = 1
        _MaxOutlineZOffset ("Max Outline Z Offset",Range(0,1))=0.01
        
        [Header(Option)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull (Default back)",Float)=2
        [Enum(Off,0,On,1)] _ZWrite ("ZWrite (Default On)",Float)=1
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlendMode ("Src blend mode (Default One)",Float)=1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlendMode ("Dst blend mode (Default Zero)",Float)=0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp ("Blend operation (Default Add)",Float)=0
        _StencilRef ("Stencil reference",Int)=0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil compare function",Int)=0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPassOp ("Stencil pass operation",Int)=0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilFailOp ("Stencil fail operation",Int)=0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilZFailOp ("Stencil Z fail operation",Int)=0
      
        [Header(SRP Default)]
        [Toggle(_SRP_DEFAULT_PASS)]_SRPDefaultPass ("SRP Default Pass",Int)=0
        [Enum(UnityEngine.Rendering.BlendMode)]_SRPSrcBlendMode ("SRP src blend mode (Default One)",Float)=1
        [Enum(UnityEngine.Rendering.BlendMode)]_SRPDstBlendMode ("SRP dst blend mode (Default Zero)",Float)=0
        [Enum(UnityEngine.Rendering.BlendOp)]_SRPBlendOp ("SRP blend operation (Default Add)",Float) =0
        
        _SRPStencilRef ("SRP stencil reference",Int)=0
        [Enum(UnityEngine.Rendering.CompareFunction)]_SRPStencilComp ("SRP stencil compare function",Int)=0
        [Enum(UnityEngine.Rendering.StencilOp)]_SRPStencilPassOp ("SRP stencil pass operation",Int)=0
        [Enum(UnityEngine.Rendering.StencilOp)]_SRPStencilFailOp ("SRP stencil fail operation",Int)=0
        [Enum(UnityEngine.Rendering.StencilOp)]_SRPStencilZFailOp ("SRP stencil Z fail operation",Int)=0
    }
    

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }
        
        HLSLINCLUDE

        #pragma shader_feature_local _DOMAIN_FACE
        #pragma shader_feature_local _DOMAIN_EYE
        #pragma shader_feature_local _DOMAIN_BODY
        #pragma shader_feature_local _DOMAIN_HAIR
        #pragma shader_feature_local _DOMAIN_CLOTH

        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS SCREEN

        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "DisneyPBR.hlsl"

        float3 OctToUnitVector(float2 oct)
        {
          float3 N = float3(oct, 1-dot(1,abs(oct)) );
          float t = max(-N.z,0);
          N.x += N.x >= 0 ? (-t) : t;
          N.y += N.y >= 0 ? (-t) : t;
          return normalize(N);
        }

        float3 GetLutColor(float3 OriginColor, sampler2D Lut)
        {
            //1024 * 32 texture
            float height = 31 * OriginColor.b;
            float lutLevel = floor(height);
            float tirilinearPercentage =  height - lutLevel;
            float lowU = (OriginColor.r / 32) + lutLevel * (1.0/32);
            float highU = (OriginColor.r / 32) + (lutLevel + 1.0) * (1.0/32);
            float V = OriginColor.g;
            float2 lowUV = float2(lowU,V);
            float2 highUV = float2(highU,V);

            return lerp(tex2D(Lut,lowUV), tex2D(Lut,highUV),tirilinearPercentage).rgb;
        }

        float3 TTShiftTangent(float3 T, float3 N, float shift)
        {
            return normalize(T + N * shift);
        }

        float StrandSpecular(float3 T, float3 V, float3 L, float exponent)
        {
            float3 halfDir     = normalize(L + V);
            float dotTH    = dot(T, halfDir);
            float sinTH    = max(0.01, sqrt(1 - pow(dotTH, 2)));
            float dirAtten     = smoothstep(-1, 0, dotTH); 
            // real dirAttn = saturate(TdotH + 1.0);
            return dirAtten * pow(sinTH, exponent);
        }

        float random (float2 st) {
            return frac(sin(dot(st, float2(12.9898,78.233) ) )*43758.5453123);
        }

        CBUFFER_START(UnityPerMaterial)

        float4 _Color;
        sampler2D _BaseColorTex;
        sampler2D _RampMap;

        sampler2D _OtherTex;
        sampler2D _OtherTex2;
        sampler2D _OtherTex3;
        sampler2D _OtherTex4;

        float3 _HeadCenter;
        float3 _HeadForward;
        float3 _HeadRight;

        float _Subsurface;
        float _Specular;
        float _SpecularTint;
        float _Anisotropic;
        float _Sheen;
        float _SheenTint;
        float _Clearcoat;
        float _ClearcoatGloss;
        
        float _AlphaClip;
        float4 _EmissionColor;
        float _EmissionIntensity;


        float3 _OutlineColor;
        float _OutlineWidth;
        float _MaxOutlineZOffset;


        float _PrimaryShift;
        float3 _SpecularColor;
        float _SpecExponent;
        float _SpecularThreshold;
        float _SpecularRange;

        
        CBUFFER_END
        

        struct UniversalAttributes
        {
            float4 positionOS   : POSITION;
            float4 tangentOS    : TANGENT;
            float3 normalOS     : NORMAL;
            float2 texcoord     : TEXCOORD0;
        };

        struct UniversalVaryings
        {
            float2 uv                       :TEXCOORD0;
            float4 positionWSAndFogFactor   :TEXCOORD1;
            float3 normalWS                 :TEXCOORD2;
            float4 tangentWS                :TEXCOORD3;
            float3 viewDirectionWS          :TEXCOORD4;
            float4 positionCS               :SV_POSITION;
        };

        UniversalVaryings MainVS(UniversalAttributes input)
        {
            
            VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
            VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS,input.tangentOS);

            UniversalVaryings output ;           
            output.positionCS = positionInputs.positionCS;
            output.positionWSAndFogFactor = float4(positionInputs.positionWS, ComputeFogFactor(positionInputs.positionCS.z));

            output.normalWS = normalInputs.normalWS;
            output.tangentWS.xyz = normalInputs.tangentWS;
            output.tangentWS.w = input.tangentOS.w * GetOddNegativeScale();

            output.viewDirectionWS = unity_OrthoParams.w == 0 ? GetCameraPositionWS() - positionInputs.positionWS : GetWorldToViewMatrix()[2].xyz;

            output.uv = input.texcoord;
            
            return output;
        }

        float4 MainFS (UniversalVaryings input, bool isFrontFace : SV_IsFrontFace) : SV_Target
        {
            float3 normalWS = normalize(input.normalWS);
            normalWS *= isFrontFace ? 1 : -1 ;
            
            float3 positionWS = input.positionWSAndFogFactor.xyz;
            float3 viewDirWS = normalize(input.viewDirectionWS);
            float3 tangentWS = normalize(input.tangentWS.xyz);
            float3 bitangentWS = input.tangentWS.w * cross(normalWS, tangentWS);

            float2 uv = input.uv;

            float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
            Light mainLight = GetMainLight(shadowCoord);
            
            float3 mainlightDirectionWS = normalize(mainLight.direction);

            float3 mainlightColor = mainLight.color;

            float4 MainTex = tex2D(_BaseColorTex,uv);
            
            float3 baseColor = MainTex.rgb;
            baseColor *= _Color;

            float3 finalColor = baseColor;



            float baseAlpha = 1.0;
            #if _DOMAIN_HAIR
            {
                baseAlpha = MainTex.a;
            }
            #endif
            

            float NoL = dot(normalWS, mainlightDirectionWS);
            float RemapNoL = 0.5 * NoL + 0.5;
            float halfLambert = RemapNoL * RemapNoL;

            float4 otherData = tex2D(_OtherTex, uv);
            float4 otherData2 = tex2D(_OtherTex2, uv);

            float3 rampColor = tex2D(_RampMap,float2(halfLambert,1));

            float3 rampDiffuse = lerp( rampColor* baseColor, baseColor ,halfLambert);

            

            // Multi Light Cloth PBR
            #if _DOMAIN_CLOTH
            {
                //TODO：Guess and Explain an other shading moding in id 2
                
                float metallic = otherData.r;
                float ao = otherData.b;
                float roughness = otherData.a;
                DisneyBrdfData brdfData;
                {
                    brdfData.albedo = baseColor;
                    brdfData.subSurface = _Subsurface;
                    brdfData.anisotropic = _Anisotropic;
                    brdfData.sheen = _Sheen;
                    brdfData.sheenTint = _SheenTint;
                    brdfData.clearcoat = _Clearcoat;
                    brdfData.clearcoatGloss = _ClearcoatGloss;
                    brdfData.specular = _Specular;
                    brdfData.specularTint = _SpecularTint;
                    brdfData.metallic = metallic;
                    brdfData.roughness = roughness;
                }
                
                float3 pixelNormalTS;
                pixelNormalTS.xyz = otherData2.rgb;
                // pixelNormalTS.z = sqrt(1.0 - saturate( dot(pixelNormalTS.xy, pixelNormalTS.xy) ) );
                // return float4(pixelNormalTS,1);
                float3 pixelNormalWS = TransformTangentToWorld(pixelNormalTS, float3x3(tangentWS,bitangentWS,normalWS));
                pixelNormalWS = normalize(pixelNormalWS);
                pixelNormalWS *= isFrontFace ? 1 : -1;

                float3 pbrColor =mainLight.color*mainLight.shadowAttenuation * mainLight.distanceAttenuation* DisneyBrdf(mainlightDirectionWS,
                                                viewDirWS,
                                                pixelNormalWS,
                                                tangentWS,bitangentWS,brdfData);
                
                // Addition Light Cloth PBR
                float3 SumAdditionalLightColor = 0;
                {
                    uint pixelLightCount = GetAdditionalLightsCount();
                    LIGHT_LOOP_BEGIN(pixelLightCount)
                        float3 additionalLightColor = 0;
                        Light additionalLight = GetAdditionalLight(lightIndex, positionWS,half4(1,1,1,1));
                    
                        float3 additionalLightDir = additionalLight.direction;
                        additionalLightDir = normalize(additionalLightDir);
                    
                        float additionNoL = dot(normalWS, additionalLightDir);
                        additionalLightColor += additionNoL > 0 ? DisneyBrdf(additionalLightDir,viewDirWS,pixelNormalWS,tangentWS,bitangentWS,brdfData) : 0;

                        additionalLightColor *= additionalLight.color
                                                * additionalLight.distanceAttenuation
                                                * additionalLight.shadowAttenuation ;

                        SumAdditionalLightColor += additionalLightColor;

                    LIGHT_LOOP_END
                }

                float3 ambient = SampleSH(pixelNormalWS);
                ambient *= ao;

                finalColor = ambient*0.05 + saturate(pbrColor) + saturate(SumAdditionalLightColor);

            }
            #endif
            
      
            //Cloth Emission
            #if _DOMAIN_CLOTH
            {
                float3 emission = tex2D(_OtherTex3,uv);
                emission *= _EmissionColor.xyz * _EmissionIntensity;

                finalColor += emission;
            }
            #endif



            #if _DOMAIN_HAIR
            {

                // _PrimaryShift("Primary Shift",Range(0,1)) = 0
                // _SpecularColor("Specular Color",Color) = (1,1,1,1)
                // _SpecExponent("Specular Exponent",Range(0,10)) = 1
                // _SpecularThreshold("Specular Threshold",Range(0,1)) = 0.5

                bool isFrontHair = otherData2.r < 0.5;
                
                //point from root to hair tip
                float3 hairTangentWS = -bitangentWS;

                float ao = otherData2.b;
                float pixelShiftTangent = tex2D(_OtherTex3,uv).r;
                
                float3 pixelNormalTS = otherData.rgb;
                float3x3 tbn = float3x3(tangentWS,bitangentWS,normalWS);
                float3 pixelNormalWS = TransformTangentToWorld(pixelNormalTS, tbn);

                float3 sphereNormalWS = normalize(positionWS - _HeadCenter);




                hairTangentWS = hairTangentWS + _PrimaryShift * pixelShiftTangent * pixelNormalWS;
                
                float3 halfVector = normalize(viewDirWS + mainlightDirectionWS);
                float dotTH = dot(hairTangentWS, halfVector);
                float sinTH = sqrt(1.0 - min(1.0,dotTH * dotTH) );
                float dirAtten = smoothstep(-1, 0, dotTH);
                

                float3 specularStrength = dirAtten * pow(sinTH, _SpecExponent);
                
                specularStrength *=  _SpecularColor.rgb;

                // float3 diffuse = baseColor * 

                float3 headForwardWS = normalize(_HeadForward- _HeadCenter);
                float3 headRightWS = normalize(_HeadRight- _HeadCenter);
                float3 headUpWS = normalize(cross(headForwardWS, headRightWS));

                float dotUpSphere = dot(sphereNormalWS, headUpWS);
                dotUpSphere = dotUpSphere * 0.5 + 0.5;
                

                float viewDirProjHeadUp = dot(viewDirWS,headUpWS);

                float remapViewProjHeadUp = 0.65  + smoothstep(0,1,viewDirProjHeadUp)*0.4;
                remapViewProjHeadUp += 0.025 * pixelShiftTangent;
                remapViewProjHeadUp *= isFrontHair;
                
                float lowerBound = smoothstep(dotUpSphere+_SpecularRange,dotUpSphere,remapViewProjHeadUp + _SpecularThreshold);//remapViewProjHeadUp < dotUpSphere ?  1   : 0;

                // float c = a > dotUpSphere - 0.07 ? 1 :0 ; 
                float upperBound = smoothstep(dotUpSphere - _SpecularRange, dotUpSphere, remapViewProjHeadUp + _SpecularThreshold);
                float specularUpperBound = smoothstep(0.98,0.9,dotUpSphere) ;

                float spcularArea = remapViewProjHeadUp * lowerBound * upperBound * specularUpperBound * otherData2.g ;

                float pixelSpecularArea = tex2D(_OtherTex2,uv).g;
                spcularArea *= pixelSpecularArea;

                specularStrength *= spcularArea * pow(dot(pixelNormalWS,halfVector),2);

                float noFrontHairSpecular = pow(dot(pixelNormalWS, halfVector),5) ;

                baseColor *= ao;

                finalColor =  rampDiffuse +  baseColor * lerp(noFrontHairSpecular,specularStrength,isFrontHair)  ;
                
                return float4( finalColor,baseAlpha);
            }
            #endif


            #if _DOMAIN_FACE
            {
                
                float3 headForwardWS = normalize(_HeadForward- _HeadCenter);
                float3 headRightWS = normalize(_HeadRight- _HeadCenter);
                float3 headUpWS = normalize(cross(headForwardWS, headRightWS));
                
                // bool atFaceFront = dot(headForwardWS,viewDirWS) > 0 ? true : false ;
                // bool atFaceRight = dot(headRightWS,viewDirWS) > 0 ? true : false;

                float3 viewDirProjHeadWS = viewDirWS - dot(viewDirWS,headUpWS) * headUpWS;
                viewDirProjHeadWS = normalize(viewDirProjHeadWS);

                float VoR = dot(viewDirProjHeadWS,headRightWS);

                bool viewOnFaceRight = VoR > 0;

    

                float UvUoffset = 0.04 * (saturate(VoR + 0.5) * 2 -1);

                float3 lipsSpecular = tex2D(_OtherTex, float2(uv.x+UvUoffset,uv.y));

                //max offset is 0.04

                //otherData 2 : r ?
                // g : sdf mask ,white stands for light ,black stands for sdf


                // otherData3.r is sdf tex

                float3 lightDirProjHeadWS = mainlightDirectionWS - dot(mainlightDirectionWS,headUpWS) * headUpWS;
                lightDirProjHeadWS = normalize(lightDirProjHeadWS);

                float sinX = dot(lightDirProjHeadWS,headRightWS);
                float cosX = dot(lightDirProjHeadWS,-headForwardWS);

                float angleThreshold = atan2(sinX,cosX)/3.1415926;

                angleThreshold = angleThreshold > 0 ? (1-angleThreshold) : (1+angleThreshold);

                float2 sdfUV = uv;

                if (sinX < 0 )
                {
                    sdfUV.x = 1 - sdfUV.x;
                }
        
                float4 otherData3 = tex2D(_OtherTex3, sdfUV);
                //TODO : it seems that 3 channel refering diffirent weather
                float sdfMap = otherData3.b;
                
                
                // 1 is in light , 0 is shadow
                float sdfShadow = smoothstep(angleThreshold-0.03,angleThreshold,sdfMap);


                float3 sdfFace = lerp(baseColor*0.4,baseColor, sdfShadow);

                float lerpNoL = otherData2.g;

                 float3 a = lerp(sdfFace,rampDiffuse,lerpNoL);

                lipsSpecular *= sdfShadow;


                

                return float4(a+lipsSpecular,1);
            }
            #endif
            
            
            
            
            return float4(finalColor,baseAlpha);
        } 
        
        ENDHLSL


        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode"="ShadowCaster"
            }
            ZWrite [_ZWrite]
            ZTest LEqual
            ColorMask 0
            Cull [_Cull]
            
            HLSLPROGRAM
            
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma vertex vert
            #pragma fragment frag
            
            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
            };
            struct Varyings
            {
            float2 uv               : TEXCOORD0;
            float4 positionCS       : SV_POSITION;
            };
            
            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS =  TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
            #if CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - positionWS);
            #else
                float3 lightDirectionWS = _LightDirection;
            #endif
                
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS,normalWS,lightDirectionWS));
            #if UNITY_REVERSED_Z
                positionCS.z =  min(positionCS.z,UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z =  max(positionCS.z,UNITY_NEAR_CLIP_VALUE);
            #endif
    
                return positionCS;
            }


            Varyings vert(Attributes input)
            {
                Varyings output;
                output.uv = input.texcoord;
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }
            float4 frag(Varyings input):SV_TARGET
            {
                clip(1.0 -_AlphaClip);
                return 0;
            }
            
            ENDHLSL
        }        

        Pass
        {
            Name"DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
            
            ZWrite [_ZWrite]
            ColorMask 0
            Cull [_Cull]
            
            HLSLPROGRAM

            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                return  output;
            }

            half4 frag(Varyings input): SV_TARGET
            {
                clip(1.0 - _AlphaClip);
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags
            {
            "LightMode" = "DepthNormals"
            }
            ZWrite [_ZWrite]
            Cull [_Cull]
            
            HLSLPROGRAM

            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS   :POSITION;
                float4 tangentOS    :TANGENT;
                float2 texcoord     :TEXCOORD0;
                float3 normalOS     :NORMAL;
            };
            struct Varyings
            {
                float4 positionCS   :SV_POSITION;
                float2 uv           :TEXCOORD0;
                float3 normalWS     :TEXCOORD1;
                float4 tangentWS    :TEXCOORD2;  //xyz:tangent,w:sign
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                output.uv =input.texcoord;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS,input.tangentOS);

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                output.normalWS = half3(normalInput.normalWS);
                float sign = input.tangentOS.w * float(GetOddNegativeScale());
                output.tangentWS = half4(normalInput.tangentWS.xyz, sign);
                return output;
            }
            half4 frag(Varyings input): SV_TARGET
            {
                clip(1.0 - _AlphaClip);
                float3 normalWS = input.normalWS.xyz;
                return half4(NormalizeNormalPerPixel(normalWS),0.0);
            }
            ENDHLSL
        }

        //Main pass
        Pass
        {
            Name"UniversalForward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Cull [_Cull]
            Blend[_SrcBlendMode] [_DstBlendMode]
            BlendOp [_BlendOp]
            ZWrite [_ZWrite]
            Stencil
            {
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass [_StencilPassOp]
                Fail [_StencilFailOp]
                ZFail [_StencilZFailOp]
            }
            HLSLPROGRAM

            #pragma  vertex MainVS
            #pragma  fragment MainFS
            
            ENDHLSL
        }


        //Outline Pass
        Pass
        {
            Name"UniversalForwardOnly"
            Tags
            {
                "LightMode" = "UniversalForwardOnly"
            }
            Cull Front
            ZWrite On
            Stencil
            {
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass [_StencilPassOp]
                Fail [_StencilFailOp]
                ZFail [_StencilZFailOp]
            }
            
            HLSLPROGRAM

            #pragma shader_feature_local _OUTLINE_PASS

            #pragma  vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

            // If your project has a faster way to get camera fov in shader, you can replace this slow function to your method.
            // For example, you write cmd.SetGlobalFloat("_CurrentCameraFOV",cameraFOV) using a new RendererFeature in C#.
            // For this tutorial shader, we will keep things simple and use this slower but convenient method to get camera fov
            float GetCameraFOV()
            {
                //https://answers.unity.com/questions/770838/how-can-i-extract-the-fov-information-from-the-pro.html
                float t = unity_CameraProjection._m11;
                float Rad2Deg = 180 / 3.1415;
                float fov = atan(1.0f / t) * 2.0 * Rad2Deg;
                return fov;
            }
            
            float ApplyOutlineDistanceFadeOut(float inputMulFix)
            {
                //make outline "fadeout" if character is too small in camera's view
                return saturate(inputMulFix);
            }
            
            float GetOutlineCameraFovAndDistanceFixMultiplier(float positionVS_Z)
            {
                float cameraMulFix;
                if(unity_OrthoParams.w == 0)
                {
                      ////////////////////////////////
                      // Perspective camera case
                      ////////////////////////////////
                
                      // keep outline similar width on screen accoss all camera distance       
                      cameraMulFix = abs(positionVS_Z);
                
                      // can replace to a tonemap function if a smooth stop is needed
                      cameraMulFix = ApplyOutlineDistanceFadeOut(cameraMulFix);
                
                      // keep outline similar width on screen accoss all camera fov
                      cameraMulFix *= GetCameraFOV();       
                }
                  else
                  {
                      ////////////////////////////////
                      // Orthographic camera case
                      ////////////////////////////////
                      float orthoSize = abs(unity_OrthoParams.y);
                      orthoSize = ApplyOutlineDistanceFadeOut(orthoSize);
                      cameraMulFix = orthoSize * 50; // 50 is a magic number to match perspective camera's outline width
                  }
                
                  return cameraMulFix * 0.00005; // mul a const to make return result = default normal expand amount WS
                }
            
            // Push an imaginary vertex towards camera in view space (linear, view space unit), 
            // then only overwrite original positionCS.z using imaginary vertex's result positionCS.z value
            // Will only affect ZTest ZWrite's depth value of vertex shader
            
            // Useful for:
            // -Hide ugly outline on face/eye
            // -Make eyebrow render on top of hair
            // -Solve ZFighting issue without moving geometry
            float4 NiloGetNewClipPosWithZOffset(float4 originalPositionCS, float viewSpaceZOffsetAmount)
            {
              if(unity_OrthoParams.w == 0)
              {
                  ////////////////////////////////
                  //Perspective camera case
                  ////////////////////////////////
                  float2 ProjM_ZRow_ZW = UNITY_MATRIX_P[2].zw;
                  float modifiedPositionVS_Z = -originalPositionCS.w + -viewSpaceZOffsetAmount; // push imaginary vertex
                  float modifiedPositionCS_Z = modifiedPositionVS_Z * ProjM_ZRow_ZW[0] + ProjM_ZRow_ZW[1];
                  originalPositionCS.z = modifiedPositionCS_Z * originalPositionCS.w / (-modifiedPositionVS_Z); // overwrite positionCS.z
                  return originalPositionCS;    
              }
              else
              {
                  ////////////////////////////////
                  //Orthographic camera case
                  ////////////////////////////////
                  originalPositionCS.z += -viewSpaceZOffsetAmount / _ProjectionParams.z; // push imaginary vertex and overwrite positionCS.z
                  return originalPositionCS;
              }
            }
            

            
            struct Attributes
            {
              float4 positionOS   :POSITION;
              float4 tangentOS    :TANGENT;
              float3 normalOS     :NORMAL;
              float2 texcoord     :TEXCOORD0;
              float2 texcoord1    :TEXCOORD1;
            };
            
            struct Varyings
            {
              float2 uv           :TEXCOORD0;
              float fogFactor     :TEXCOORD1;
              float4 positionCS   :SV_POSITION;
            };
            
            Varyings vert(Attributes input)
            {
            #if !_OUTLINE_PASS
                return (Varyings)0;
            #endif
            
            
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                float width = _OutlineWidth;
                width *= GetOutlineCameraFovAndDistanceFixMultiplier(positionInputs.positionVS.z);
                
                float2 oct = input.texcoord1;
                float3 smoothNormal = OctToUnitVector(oct);
                float3x3 tbn = float3x3(
                    normalInputs.tangentWS,
                    normalInputs.bitangentWS,
                    normalInputs.normalWS
                );
                smoothNormal = mul(smoothNormal, tbn);
                
                float3 positionWS = positionInputs.positionWS.xyz;
                // positionWS += normalInputs.normalWS * width;
                positionWS += smoothNormal * width;
                
                Varyings output = (Varyings)0;
                output.positionCS = NiloGetNewClipPosWithZOffset( TransformWorldToHClip(positionWS), _MaxOutlineZOffset);
                output.uv = input.texcoord;
                output.fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
                
                return  output;
            }
  
            float4 frag(Varyings input) : SV_Target
            {
                #if !_OUTLINE_PASS
                clip(-1);
                #endif
            
                float3 outlineColor = _OutlineColor * 0.3;
                float4 color = float4(outlineColor, 1);
                color.rgb = MixFog(color.rgb, input.fogFactor);
                return color;
            }
            
            ENDHLSL
            
        }
    }
}
