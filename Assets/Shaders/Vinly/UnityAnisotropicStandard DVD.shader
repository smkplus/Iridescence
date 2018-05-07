Shader "Bumped Anisotropic Specular" {
     Properties {
         _Color ("Main Color", Color) = (1,1,1,1)
         _MainTex ("Diffuse (RGB) Alpha (A)", 2D) = "white" {}
         _ColorRamp("ColorRamp",2D) = "white"{}
         _SpecularTex ("Specular (R) Gloss (G) Anisotropic Mask (B)", 2D) = "gray" {}
         _BumpMap ("Normal (Normal)", 2D) = "bump" {}
         _AnisoTex ("Anisotropic Direction (Normal)", 2D) = "bump" {}
         _AnisoOffset ("Anisotropic Highlight Offset", Range(-1,1)) = -0.2
         _Cutoff ("Alpha Cut-Off Threshold", Range(0,1)) = 0.5
     }

     SubShader{
         Tags { "RenderType" = "Opaque" }
     Blend SrcAlpha OneMinusSrcAlpha

     Cull Off
         CGPROGRAM
         
             struct SurfaceOutputAniso {
                 fixed3 Albedo;
                 fixed3 Normal;
                 fixed4 AnisoDir;
                 fixed3 Emission;
                 half Specular;
                 fixed Gloss;
                 fixed Alpha;
             };
             sampler2D _ColorRamp;

             float _AnisoOffset, _Cutoff;
             inline fixed4 LightingAniso (SurfaceOutputAniso s, fixed3 lightDir, fixed3 viewDir, fixed atten)
             {
				fixed3 h = normalize(normalize(lightDir) + normalize(viewDir));
				float NdotL = 1-saturate(dot(s.Normal, lightDir));
                float2 NdotV = dot(s.Normal,viewDir);

				fixed HdotA = dot(normalize(s.Normal + s.AnisoDir.rgb), h);
				float aniso = abs(sin(radians((HdotA + _AnisoOffset) * 180)));

				float spec = saturate(dot(s.Normal, h));
				spec = saturate(pow(lerp(spec, aniso, s.AnisoDir.a), s.Gloss * 128) * s.Specular);

                float4 colorRamp = tex2D(_ColorRamp,NdotV);


				fixed4 c;
				c.rgb = ((s.Albedo * _LightColor0.rgb * NdotL) + (_LightColor0.rgb * spec)) * (atten * 2);
				c.a = 1;
				clip(s.Alpha - _Cutoff);
				return c*colorRamp;
             }

             #pragma surface surf Aniso
             #pragma target 3.0
             
             struct Input
             {
                 float2 uv_MainTex;
                 float2 uv_AnisoTex;
                 float2 uv_ColorRamp;
             };
             
             sampler2D _MainTex, _SpecularTex, _BumpMap, _AnisoTex;
                 
             void surf (Input IN, inout SurfaceOutputAniso o)
             {
				fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);
				 o.Albedo = albedo.rgb;
				 o.Alpha = albedo.a;
				 o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
				 fixed3 spec = tex2D(_SpecularTex, IN.uv_MainTex).rgb;
				 o.Specular = spec.r;
				 o.Gloss = spec.g;
				 o.AnisoDir = fixed4(UnpackNormal(tex2D(_AnisoTex, IN.uv_AnisoTex)), spec.b);
             }
         ENDCG
     }
     FallBack "Transparent/Cutout/VertexLit"
}