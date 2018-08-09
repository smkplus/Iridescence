Shader "Smkgames/Surface/Iridescence/Bubble" {
    Properties {
    _Color("Color",Color) = (1,1,1,1)
    _Cube ("Cubemap", CUBE) = "" {}
    _Alpha("Alpha",Range(0,1)) = 1

    [Space(20)][Header(MainTex and ColorRamp)][Space(20)]
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _ColorRamp("ColorRamp",2D) = "white"{}
    _Blend("Blend",Range(0,1)) = 0.5

    [Header(Mask)][Space(20)]
    _Mask("Mask",2D) = "white"{}

    [Space(20)][Header(Adding Distortion)][Space(20)]
    _Noise ("Noise", 2D) = "white" {}
    _Distortion("Distortion",Float) = 6

    [Space(20)][Header(BumpMap and BumpPower)][Space(20)]

    _BumpMap ("Bumpmap", 2D) = "bump" {}
    _BumpPower("BumpPower",Range(0.1,1)) = 0.1

        [Space(20)][Header(Change ColorRamp)][Space(20)]
    _Hue ("Hue", Range(0, 1.0)) = 0
    _Saturation ("Saturation", Range(0, 1.0)) = 0.5
    _Brightness ("Brightness", Range(0, 1.0)) = 0.5
    _Contrast ("Contrast", Range(0, 1.0)) = 0.5
    
    [Space(20)][Header(Smoothness and Metallic)][Space(20)]
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic ("Metallic", Range(0,1)) = 0.0
    _RimPower("RimPower", Range(0, 5)) = 0


    [Space(20)][Header(Vertex Animation)][Space(20)]


    _WindMap ("WindMap", 2D) = "white" {} // Add noies map like fbm noises
    _Speed("Speed",float) = 1
    _Direction("Direction",Vector) = (0,0.2,0,0)

    [Space(20)][Header(Grab Noise)][Space(20)]

    _GrabNoise("GrabNoise",2D) = "white"{}

    }
    SubShader {
 Tags {"RenderType"="Transparent" "Queue"="Transparent"}
            LOD 200
            //  Pass {
            //      ColorMask 0
            //  }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB

            GrabPass { "_MyGrabTexture" }

      CGPROGRAM
    #pragma surface surf Standard fullforwardshadows alpha:fade vertex:vert
    #pragma target 3.5

      struct Input {
          float2 uv_MainTex;
          float3 worldRefl;
          float3 viewDir;
          float2 uv_Mask;
              float2 uv_BumpMap;
          float2 uv_ColorRamp;
          float3 worldPos;
        float4 grabUV;

      };
      
      sampler2D _MainTex,_BubbleTexture,_GrabNoise;
            sampler2D _ColorRamp,_Noise,_Mask;
            sampler2D _BubbleAnimation;
      sampler2D _BumpMap;
      float4 _RimColor;
	  float _BumpIntensity;
      samplerCUBE _Cube;
                  sampler2D _MyGrabTexture;

    float4 _Color;
    float _Metallic;
    float _Glossiness;
    float4 _EmissionColor;
    float _Alpha;

    	  float4 _ColorRamp_ST;
		float _Blend;
		float _BumpPower;
		float _Distortion;
    float _RimPower;

    fixed _Hue, _Saturation, _Brightness, _Contrast;


					inline float3 applyHue(float3 aColor, float aHue)
            {
                float angle = radians(aHue);
                float3 k = float3(0.57735, 0.57735, 0.57735);
                float cosAngle = cos(angle);
                
                return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1 - cosAngle);
            }
			
			inline float4 applyHSBCEffect(float4 startColor, fixed4 hsbc)
            {
                float hue = 360 * hsbc.r;
                float saturation = hsbc.g * 2;
                float brightness = hsbc.b * 2 - 1;
                float contrast = hsbc.a * 2;
 
                float4 outputColor = startColor;
                outputColor.rgb = applyHue(outputColor.rgb, hue);
                outputColor.rgb = (outputColor.rgb - 0.5f) * contrast + 0.5f;
                outputColor.rgb = outputColor.rgb + brightness;
                float3 intensity = dot(outputColor.rgb, float3(0.39, 0.59, 0.11));
    			outputColor.rgb = lerp(intensity, outputColor.rgb, saturation);
                 
                return outputColor;
            }

            sampler2D _WindMap;
            fixed4 _Direction;
            fixed _Speed, _WindAmount;

            void vert(inout appdata_full v,out Input o){
            UNITY_INITIALIZE_OUTPUT(Input,o)
            float4 tex = tex2Dlod(_WindMap, float4(v.texcoord.xy + (_Time.x * _Speed), 0, 0));
            v.vertex.xyz += tex.y *  _Direction.xyz * _Speed;
            float4 hpos = UnityObjectToClipPos (v.vertex);
            o.grabUV = ComputeGrabScreenPos(hpos);
            }

    


      void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			float4 c = tex2D (_MainTex, IN.uv_MainTex);
			float noise = tex2D(_Noise,IN.uv_MainTex);
			//fixed3 normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
//			normal.z /= _BumpPower;
			//o.Normal = normalize(normal); 
			float4 rim = dot (normalize(IN.viewDir), o.Normal);
			float2 distortion = noise*_Distortion;
			//float2 rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));

			float4 mask = tex2D(_Mask,IN.uv_Mask);

			float4 colorRamp = tex2D(_ColorRamp,TRANSFORM_TEX(rim, _ColorRamp)*distortion)*mask;
			colorRamp = max(colorRamp,(1-mask)* c);




    float4 BubbleRim = clamp(1-pow (rim, _RimPower),0,1);

      float4 Bubble = tex2D(_BubbleTexture,IN.uv_MainTex);
      		    fixed4 hsbc = fixed4(_Hue, _Saturation, _Brightness, _Contrast);
			float4 colorRampHSBC = applyHSBCEffect(colorRamp, hsbc);
		//	o.Albedo = lerp(0,colorRampHSBC,_Blend)*BubbleRim;

        				float4 GrabDistortion = tex2D(_GrabNoise,IN.grabUV.xy)/5;
                        float4 BackGround = tex2Dproj( _MyGrabTexture, UNITY_PROJ_COORD(IN.grabUV+GrabDistortion.r))/10;
                o.Albedo = BackGround;

          o.Emission =BackGround+ texCUBE (_Cube, IN.worldRefl).rgb+lerp(0,colorRampHSBC,_Blend)*BubbleRim;
      o.Metallic = _Metallic;
      o.Smoothness = _Glossiness;
      o.Alpha = _Alpha;

      }
      ENDCG
    } 
    Fallback "Diffuse"
  }