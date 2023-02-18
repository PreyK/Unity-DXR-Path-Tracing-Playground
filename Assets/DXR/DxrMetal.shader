Shader "RayTracing/DxrMetal"
{
	Properties
	{
		_Color ("Color", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "white" {}
		_Roughness ("Roughness", Range(0, 10)) = 0.5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		// basic rasterization pass that will allow us to see the material in SceneView
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "SimpleLit.cginc"
			ENDCG
		}

		// ray tracing pass
		Pass
		{
			Name "DxrPass"
			Tags{ "LightMode" = "DxrPass" }

			HLSLPROGRAM

			#pragma raytracing test
					   
			#include "Common.cginc"

			float4 _Color;
			float _Roughness;

			Texture2D<float4> _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform int _MaxRayBounce = 1;

			[shader("closesthit")]
			void ClosestHit(inout RayPayload rayPayload : SV_RayPayload, AttributeData attributeData : SV_IntersectionAttributes)
			{
				// stop if we have reached max recursion depth
				if(rayPayload.depth + 1 == _MaxRayBounce)
				{
					return;
				}

				// compute vertex data on ray/triangle intersection
				IntersectionVertex currentvertex;
				GetCurrentIntersectionVertex(attributeData, currentvertex);

				// transform normal to world space
				float3x3 objectToWorld = (float3x3)ObjectToWorld3x4();
				float3 worldNormal = normalize(mul(objectToWorld, currentvertex.normalOS));

				float3 rayOrigin = WorldRayOrigin();
				float3 rayDir = WorldRayDirection();
				// get intersection world position
				float3 worldPos = rayOrigin + RayTCurrent() * rayDir;

				// get random vector
				float3 randomVector = float3(nextRand(rayPayload.randomSeed), nextRand(rayPayload.randomSeed), nextRand(rayPayload.randomSeed)) * 2 - 1;

				// get reflection direction
				float3 reflection = reflect(rayDir, worldNormal);
				// perturb reflection direction to get rought metal effect 
				reflection = normalize(reflection + _Roughness * randomVector);
				
				RayDesc rayDesc;
				rayDesc.Origin = worldPos;
				rayDesc.Direction = reflection;
				rayDesc.TMin = 0.001;
				rayDesc.TMax = 100;

				// Create and init the ray payload
				RayPayload scatterRayPayload;
				scatterRayPayload.color = float3(0.0, 0.0, 0.0);
				scatterRayPayload.randomSeed = rayPayload.randomSeed;
				scatterRayPayload.depth = rayPayload.depth + 1;
				
				// shoot reflection ray
				TraceRay(_RaytracingAccelerationStructure, RAY_FLAG_NONE, RAYTRACING_OPAQUE_FLAG, 0, 1, 0, rayDesc, scatterRayPayload);

				int2 coord = floor(currentvertex.texCoord0 * _MainTex_TexelSize.w);

				float3 a = _MainTex.Load(int3(coord, 0));
				
				rayPayload.color = _Color.xyz*a * scatterRayPayload.color;
			}			

			ENDHLSL
		}
	}
}
