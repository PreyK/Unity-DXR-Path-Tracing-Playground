Shader "RayTracing/DxrDiffuse"
{
	Properties
	{
		_Color ("Color", Color) = (1, 1, 1, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_UseNormalMap("use normal map", Int) = 0
		_NormalScale ("Normal Scale", Range(0, 10)) = 1
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
			Texture2D<float4> _MainTex;
			uniform float4 _MainTex_TexelSize;

			Texture2D<float4> _NormalMap;
			uniform float4 _NormalMap_TexelSize;

			uniform int _UseNormalMap;
			uniform float _NormalScale;



			[shader("closesthit")]
			void ClosestHit(inout RayPayload rayPayload : SV_RayPayload, AttributeData attributeData : SV_IntersectionAttributes)
			{
				// stop if we have reached max recursion depth
				if(rayPayload.depth + 1 == gMaxDepth)
				{
					return;
				}
				// compute vertex data on ray/triangle intersection
				IntersectionVertex currentvertex;
				GetCurrentIntersectionVertex(attributeData, currentvertex);

				// transform normal to world space
				float3x3 objectToWorld = (float3x3)ObjectToWorld3x4();
				float3 worldNormal = normalize(mul(objectToWorld, currentvertex.normalOS));



				//normal map
				int2 normalCord = floor(currentvertex.texCoord0 * _NormalMap_TexelSize.w);
				float4 normalTex = _NormalMap.Load(int3(normalCord, 0));
				float3 tnormal = UnpackScaleNormal(normalTex, _NormalScale);

				float3 worldTang = normalize(mul(objectToWorld, currentvertex.tangentOS));
				float3 WorldBitang = cross(worldNormal, worldTang);
				float3 wn = worldTang * tnormal.x + WorldBitang * tnormal.y + worldNormal * tnormal.z;

				if(_UseNormalMap>0){
					worldNormal = wn;
				}
								
				float3 rayOrigin = WorldRayOrigin();
				float3 rayDir = WorldRayDirection();
				// get intersection world position
				float3 worldPos = rayOrigin + RayTCurrent() * rayDir;

				// get random vector
				float3 randomVector = float3(nextRand(rayPayload.randomSeed), nextRand(rayPayload.randomSeed), nextRand(rayPayload.randomSeed)) * 2 - 1;

				// get random scattered ray dir along surface normal				
				float3 scatterRayDir = normalize(worldNormal + randomVector);

				RayDesc rayDesc;
				rayDesc.Origin = worldPos;
				rayDesc.Direction = scatterRayDir;
				rayDesc.TMin = 0.001;
				rayDesc.TMax = 100;

				// Create and init the scattered payload
				RayPayload scatterRayPayload;
				scatterRayPayload.color = float3(0.0, 0.0, 0.0);
				scatterRayPayload.randomSeed = rayPayload.randomSeed;
				scatterRayPayload.depth = rayPayload.depth + 1;				

				// shoot scattered ray
				TraceRay(_RaytracingAccelerationStructure, RAY_FLAG_NONE, RAYTRACING_OPAQUE_FLAG, 0, 1, 0, rayDesc, scatterRayPayload);
				//rayPayload.color = attributeData.barycentrics.xy0;
				float3 test = float3(currentvertex.texCoord0.x, currentvertex.texCoord0.y, 0);

				//int triangleIndex = PrimitiveIndex();
			//	IntersectionVertex v;
				//GetCurrentIntersectionVertex(triangleIndex, out v);
			//	VertexAttributes vertex = GetVertexAttributes(triangleIndex, attributeData.barycentrics);
			//	GetCurrentIntersectionVertex(attributeData, kek);

			//	float3 texCol = _albedoTest.Load(test).rgb;
			//	rayPayload.color = texCol;
			//	float3 a = tex.Sample(TextureSampler, test);
				int2 coord = floor(currentvertex.texCoord0 * _MainTex_TexelSize.w);

				float3 a = _MainTex.Load(int3(coord, 0));
				//float b = _MainTex.Sample(test);
			//	rayPayload.color =_Color.xyz*a*scatterRayPayload.color;

			//	rayPayload.color =a;
				rayPayload.color = _Color*a*scatterRayPayload.color;
				//rayPayload.color = test*scatterRayPayload.color;
				
			//	rayPayload.color = _Color.xyz * scatterRayPayload.color;
			}			
			ENDHLSL
		}
	}
}
