Shader "Smkgames/Surface/Bubble" {
    Properties {
    _Color("Color",Color) = (1,1,1,1)
    _Cube ("Cubemap", CUBE) = "" {}
    _BubbleTexture("_BubbleTexture",2D) = "white"{}
    _Metallic("Metallic",Range(0,1)) = 1
    _Smoothness("Smoothness",Range(0,1)) = 1
    _Alpha("Alpha",Float) = 1
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
          float3 worldRefl;
          float3 viewDir;
          float3 Normal;
      };
      sampler2D _MainTex,_BubbleTexture;
      samplerCUBE _Cube;
    float4 _Color;
    float _Metallic;
    float _Smoothness;
    float4 _EmissionColor;
    float _Alpha;
      void surf (Input IN, inout SurfaceOutputStandard o) {
      fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

      float3 Rim = 1-dot(o.Normal , normalize(IN.viewDir));
      float4 Bubble = tex2D(_BubbleTexture,IN.uv_MainTex);
          o.Albedo = c.rgb * 0.5 * _Color;
          o.Emission = texCUBE (_Cube, IN.worldRefl).rgb*_Color*Rim;
      o.Metallic = _Metallic;
      o.Smoothness = _Smoothness;
      o.Alpha = _Alpha;

      }
      ENDCG
    } 
    Fallback "Diffuse"
  }