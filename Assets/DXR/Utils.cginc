//uint initRand(uint seed)
//{
//	seed = (seed ^ 61) ^ (seed >> 16);
//	seed *= 9;
//	seed = seed ^ (seed >> 4);
//	seed *= 0x27d4eb2d;
//	seed = seed ^ (seed >> 15);
//
//	return seed;
//}
//
//// compute random seed from two inputs
//// https://github.com/nvpro-samples/optix_prime_baking/blob/master/random.h
//uint initRand(uint seed1, uint seed2)
//{
//	uint seed = 0;
//
//	[unroll]
//	for(uint i = 0; i < 16; i++)
//	{
//		seed += 0x9e3779b9;
//		seed1 += ((seed2 << 4) + 0xa341316c) ^ (seed2 + seed) ^ ((seed2 >> 5) + 0xc8013ea4);
//		seed2 += ((seed1 << 4) + 0xad90777d) ^ (seed1 + seed) ^ ((seed1 >> 5) + 0x7e95761e);
//	}
//	
//	return seed1;
//}
//
//// next random number
//// http://reedbeta.com/blog/quick-and-easy-gpu-random-numbers-in-d3d11/
//float nextRand(inout uint seed)
//{
//	seed = 1664525u * seed + 1013904223u;
//	return float(seed & 0x00FFFFFF) / float(0x01000000);
//}