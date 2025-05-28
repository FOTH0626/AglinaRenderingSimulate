Shader "Foth/Shadow"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Alpha ("Alpha", Range(0,1)) = 0.5
        _LightStrength("Light Blend Strength", Range(0,1)) =0
        
        _AlphaTex ("Alpha Tex",2D) = "white"
        
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
            "RenderQueue"="3000"
        }
        LOD 200
        
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        #pragma vertex vert
        #pragma fragment frag

        CBUFFER_START(UnityPerMaterial)

        float4 _Color;
        float _Alpha;
        float _LightStrength;

        sampler2D _AlphaTex;
        
        CBUFFER_END

        struct UniversalAttributes
        {
            float4 positionOS   :POSITION;
            float2 uv : TEXCOORD0;
        };

        struct UniversalVaryings
        {
            float4 positionCS   :SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        UniversalVaryings vert(UniversalAttributes input)
        {
            UniversalVaryings output;
            output.positionCS = TransformObjectToHClip(input.positionOS);
            output.uv = input.uv;

            return output;
        }

        float4 frag (UniversalVaryings input):SV_Target
        {
            Light light = GetMainLight();
            float3 lightColor = light.color;
            lightColor = saturate(normalize(lightColor));

            float2 uv = input.uv;
            
            float3 color = lerp(_Color.rgb,lightColor,_LightStrength);
            //
            // uv.y = smoothstep(0,1,uv.y);
            //
             float finalAlpha = lerp(0,_Alpha,uv.y);

            // float finalAlpha = tex2D(_AlphaTex,uv).r;
            // finalAlpha = pow(finalAlpha,2);
            
            return float4(color,finalAlpha);
            //return float4(uv,0,1);
        }
        
        ENDHLSL
        
        Pass
        {
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
            
            #pragma  vertex vert
            #pragma  fragment frag
            
            ENDHLSL
        }
        

        
    }

}