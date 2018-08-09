Shader "Smkgames/Surface/Bubble" {
    Properties {
    _Color("Color",Color) = (1,1,1,1)
    _Cube ("Cubemap", CUBE) = "" {}
    _BubbleTexture("BubbleTexture",2D) = "white"{}
    _Metallic("Metallic",Range(0,1)) = 1
    _Smoothness("Smoothness",Range(0,1)) = 1
    _TextureAlpha("TextureAlpha",Range(0,1)) = 0.5
    _Alpha("Alpha",Range(0,1)) = 1
    }
    SubShader {
 Tags {"RenderType"="Transparent" "Queue"="Transparent"}
            LOD 200
             Pass {
                 ColorMask 0
             }
ZWrite Off
                 Blend SrcAlpha OneMinusSrcAlpha
                 ColorMask RGB

      CGPROGRAM
    #pragma surface surf Standard fullforwardshadows alpha:fade

      struct Input {
          float2 uv_MainTex;
          float2 uv_BubbleTexture;
          float3 worldRefl;
          float3 viewDir;
      };
      sampler2D _MainTex,_BubbleTexture;
      samplerCUBE _Cube;
    float4 _Color;
    float _Metallic;
    float _Smoothness;
    float4 _EmissionColor;
    float _TextureAlpha;
    float _Alpha;
      void surf (Input IN, inout SurfaceOutputStandard o) {
      float3 NdotL = dot(o.Normal , normalize(IN.viewDir));
      float3 Rim = 1-NdotL;
      float4 Bubble = lerp(0,tex2D(_BubbleTexture,NdotL),_TextureAlpha);
          o.Albedo = Bubble * 0.5 * _Color;
          o.Emission = texCUBE (_Cube, IN.worldRefl).rgb*_Color*Rim;
      o.Metallic = _Metallic;
      o.Smoothness = _Smoothness;
      o.Alpha = _Alpha;

      }
      ENDCG
    } 
    Fallback "Diffuse"
  }