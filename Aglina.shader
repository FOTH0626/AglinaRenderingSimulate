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
        
        _AlphaClip("Alpha Clipping",Range(0,1))=0.333
        
        _Strength("AO Strength", Range(0,1)) = 0.01
        
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

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "fothPBS.hlsl"

        float3 OctToUnitVector(float2 oct)
        {
          float3 N = float3(oct, 1-dot(1,abs(oct)) );
          float t = max(-N.z,0);
          N.x += N.x >= 0 ? (-t) : t;
          N.y += N.y >= 0 ? (-t) : t;
          return normalize(N);
        }

        CBUFFER_START(UnityPerMaterial)

        float4 _Color;
        sampler2D _BaseColorTex;
        sampler2D _RampMap;

        sampler2D _OtherTex;
        sampler2D _OtherTex2;
        sampler2D _OtherTex3;
        
        float _AlphaClip;

        float3 _OutlineColor;
        float _OutlineWidth;
        float _MaxOutlineZOffset;

        float _Strength;
        
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

        float4 MainFS (UniversalVaryings input) : SV_Target
        {
            float3 normalWS = normalize(input.normalWS);
            float3 positionWS = input.positionWSAndFogFactor.xyz;
            float3 viewDirWS = normalize(input.viewDirectionWS);
            float3 tangentWS = normalize(input.tangentWS.xyz);
            float3 bitangentWS = input.tangentWS.w * cross(normalWS, tangentWS);

            float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
            Light mainLight = GetMainLight(shadowCoord);
            
            float3 lightDirectionWS = normalize(mainLight.direction);
            float3 lightColor = mainLight.color;

            float4 MainTex = tex2D(_BaseColorTex,input.uv);
            
            float3 baseColor = MainTex.rgb;
            baseColor *= _Color;

            float baseAlpha = 1.0;
            #if _DOMAIN_HAIR
            {
                baseAlpha = MainTex.a;
            }
            #endif
            

            float NdotL = dot(normalWS, lightDirectionWS);
            float HalfLambert = 0.5 * NdotL + 0.5;

            float4 otherData = tex2D(_OtherTex, input.uv);
            float4 otherData2 = tex2D(_OtherTex2, input.uv);

            float3 rampColor = tex2D(_RampMap,float2(HalfLambert,1));
            baseColor *= rampColor;
            
            

            #if _DOMAIN_CLOTH
            {
                float metallic = otherData.r;
                float ao = otherData.b;
                float roughness = otherData.a;
                
                float3 pixelNormalTS;
                pixelNormalTS.xyz = otherData2.rgb;
                // pixelNormalTS.z = sqrt(1.0 - saturate( dot(pixelNormalTS.xy, pixelNormalTS.xy) ) );
                // return float4(pixelNormalTS,1);
                float3 pixelNormalWS = TransformTangentToWorld(pixelNormalTS, float3x3(tangentWS,bitangentWS,normalWS));
                pixelNormalWS = normalize(pixelNormalWS);

                float3 pbrColor = CookTorranceBRDF(baseColor, metallic, roughness, pixelNormalWS, lightDirectionWS, viewDirWS);
                pbrColor = saturate(pbrColor);
                pbrColor *= ao ;
                
                return float4(pbrColor, 1 );
            }
            #endif
            
            
            return float4(baseColor,1);
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
