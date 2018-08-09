// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/Iridescence/SimpleIridescence" {
	Properties {
		[Space(20)][Header(MainTex and ColorRamp)][Space(20)]
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_ColorRamp("ColorRamp",2D) = "white"{}
		_Blend("Blend",Range(0,1)) = 0.5

		[Space(20)][Header(Mask)][Space(20)]
		_Mask("Mask",2D) = "white"{}

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
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

      sampler2D _MainTex,_ColorRamp,_Mask;
      sampler2D _BumpMap;
      float4 _RimColor;
	  float _BumpIntensity;

		struct Input {
          float2 uv_MainTex;
		  float2 uv_Mask;
          float2 uv_BumpMap;
		  float2 uv_ColorRamp;
          float3 viewDir;
		  float3 worldPos;
		};

	  float4 _ColorRamp_ST;
		half _Glossiness;
		half _Metallic;
		float _Blend;
		float _BumpPower;

		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

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
		

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			float4 c = tex2D (_MainTex, IN.uv_MainTex);
			fixed3 normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			normal.z /= _BumpPower;
			o.Normal = normalize(normal); 
			float2 rim = dot (normalize(IN.viewDir), o.Normal);
			//float2 rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));

			float4 mask = tex2D(_Mask,IN.uv_Mask);
			float4 colorRamp = tex2D(_ColorRamp,TRANSFORM_TEX(rim, _ColorRamp))*mask;

			colorRamp = max(colorRamp,(1-mask)* c);

		    fixed4 hsbc = fixed4(_Hue, _Saturation, _Brightness, _Contrast);
			float4 colorRampHSBC = applyHSBCEffect(colorRamp, hsbc);
			o.Albedo = lerp(c,colorRampHSBC,_Blend);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
