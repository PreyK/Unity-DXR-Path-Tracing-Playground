Shader "RayTracing/DXR_AIO_WIP"
{
	Properties
	{
		_Color ("Color", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "white" {}
		_Normal ("Normal Map", 2D) = "bump" {}
		_NormalScale ("Normal Scale", Range(0, 1)) = 1
		_RoughnessMap ("Roughness Map", 2D) = "white" {}
		_Roughness ("Roughness", Range(0, 10)) = 0.5
		_EmissionMap ("EmissionMap", 2D) = "black" {}
		_EmissionScale ("Emission Scale", Range(0, 100)) = 1
		_UseNormalMap("use normal map", Float) = 0
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
			
			float _UseNormalMap;
			float4 _Color;
			float _Roughness;
			float _NormalScale;
			float _EmissionScale;
			Texture2D<float4> _MainTex;
			Texture2D<float4> _Normal;
			Texture2D<float4> _RoughnessMap;
			Texture2D<float4> _EmissionMap;
			uniform float4 _RoughnessMap_TexelSize;
			uniform float4 _MainTex_TexelSize;
			uniform float4 _Normal_TexelSize;
			uniform float4 _EmissionMap_TexelSize;


			
			//sampler2D _MainTex;

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
				
				//float3 bitangent = normalize(cross(worldNormal, currentvertex.tangentOS));

				//float3x3 tbn = float3x3(currentvertex.tangentOS, bitangent, worldNormal);

				int2 normalCord = floor(currentvertex.texCoord0 * _Normal_TexelSize.w);
				float4 normalTex = _Normal.Load(int3(normalCord, 0));
				float3 tnormal = UnpackNormal(normalTex);

				




				float3 worldTang = normalize(mul(objectToWorld, currentvertex.tangentOS));
				float3 WorldBitang = cross(worldNormal, worldTang);
				//float3 ts_normal = tnormal;

				float3 wn = worldTang * tnormal.x + WorldBitang * tnormal.y + worldNormal * tnormal.z;
				//rayPayload.color = wn;
				//rayPayload.color = worldNormal;

				if(_UseNormalMap>0){
					worldNormal= lerp(worldNormal,wn, _NormalScale);
				}
				


				//float3 ws_normal = worldTang * ts_normal.x + binormal * ts_normal.y + normal * ts_normal.z;



				//float3 worldNormal = normalize(mul(objectToWorld, currentvertex.normalOS));
								
				float3 rayOrigin = WorldRayOrigin();
				float3 rayDir = WorldRayDirection();
				// get intersection world position
				float3 worldPos = rayOrigin + RayTCurrent() * rayDir;

				// get random vector
				float3 randomVector = float3(nextRand(rayPayload.randomSeed), nextRand(rayPayload.randomSeed), nextRand(rayPayload.randomSeed)) * 2 - 1;

				// get random scattered ray dir along surface normal
				int2 roughtCord = floor(currentvertex.texCoord0 * _RoughnessMap_TexelSize.w);
				float4 roughTex = _RoughnessMap.Load(int3(normalCord, 0));
					

				float roughnessVal = roughTex.r*_Roughness;

				float3 scatterRayDir = normalize(worldNormal + randomVector*roughnessVal);

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
				
				int2 coord = floor(currentvertex.texCoord0 * _MainTex_TexelSize.w);
				float3 a = _MainTex.Load(int3(coord, 0));

				int2 emCoord = floor(currentvertex.texCoord0 * _EmissionMap_TexelSize.w);
				float3 emiss = _EmissionMap.Load(int3(emCoord, 0));

				float3 col = _Color*a*scatterRayPayload.color;

				
				rayPayload.color = col+(emiss*_EmissionScale);

			//	float3 specular = float3(0.6f, 0.6f, 0.6f);

				//rayPayload.energy*=specular; 
			//	rayPayload.color +=(emiss*_EmissionScale);
			//	rayPayload.color = scatterRayPayload.color;
				
			}			

			ENDHLSL
		}
	}
}
