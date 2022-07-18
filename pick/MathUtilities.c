//
//  MathUtilities.c
//  pick
//
//  Created by Paul Nelson on 6/11/22.
//  Unlike swift, simd functions do not rside within a class they are C functions
//  so we will not be extending as a category on a simd class
//
#include "MathUtilities.h"
#include <math.h>

/* Unused - use of NSColor instead
simd_float4 hsv2rgb(float hue, float saturation, float brightness)
{
	float c = brightness * saturation;
	float x = c * (1.f - fabsf(fmodf(hue * 6.f, 2.f) - 1.f));
	float m = brightness - saturation;
	
	float r = 0.f;
	float g = 0.f;
	float b = 0.f;
	
	// don't have the Swift case statement so do equivalent in C
	if ( hue < 0.16667 ) {
		r = c; g = x; b = 0.f;
	} else if ( hue < 0.33333 ) {
		r = x; g = c; b = 0.f;
	} else if ( hue < 0.5 ) {
		r = 0.f; g = c; b = x;
	} else if ( hue < 0.66667) {
		r = 0.f; g = x; b = c;
	} else if ( hue < 0.83333 ) {
		r = x; g = 0.f; b = c;
	} else if ( hue <= 1.f ) {
		r = c; g = 0.f; b = x;
	}
	
	r += m; g += m; b += m;
	return simd_make_float4(r, g, b, 1.f);
}
*/

simd_float4x4 rotateAroundAxis( simd_float3 axis, float angle)
{
	simd_float3 unitAxis = simd_normalize(axis);
	float ct = cosf(angle);
	float st = sinf(angle);
	float ci = 1.f - ct;
	float x = unitAxis.x, y = unitAxis.y, z = unitAxis.z;
	return simd_matrix(simd_make_float4(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0.f),
					   simd_make_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0.f),
					   simd_make_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0.f),
					   simd_make_float4(                0.f,                 0.f,                 0.f, 1.f)
					   );
}

simd_float4x4 translateBy(simd_float3 v)
{
	return simd_matrix(simd_make_float4(1.f, 0.f, 0.f, 0.f),
					   simd_make_float4(0.f, 1.f, 0.f, 0.f),
					   simd_make_float4(0.f, 0.f, 1.f, 0.f),
					   simd_make_float4(v.x, v.y, v.z, 1.f));
}

simd_float4x4 perspectiveProjectionRHFovY( float fovy, float aspectRatio, float nearZ, float farZ)
{
	float ys = 1.f / tanf(fovy * 0.5);
	float xs = ys / aspectRatio;
	float zs = farZ / (nearZ - farZ);
	return simd_matrix(simd_make_float4(  xs, 0.f, 0.f,  0.f),
					   simd_make_float4( 0.f,  ys, 0.f,  0.f),
					   simd_make_float4( 0.f, 0.f,  zs, -1.f),
					   simd_make_float4( 0.f,  0.f, zs * nearZ, 0.f));
}

float radians_from_degrees(float degrees)
{
	return M_PI * (degrees / 180.);
}

