//
//  MathUtilities.h
//  pick
//
//  Created by Paul Nelson on 6/11/22.
//
#ifndef MathUtilities_h
#define MathUtilities_h

#import <simd/simd.h>

// simd_float4 hsv2rgb(float hue, float saturation, float brightness);  // unused
simd_float4x4 rotateAroundAxis( simd_float3 axis, float angle);
simd_float4x4 translateBy(simd_float3 v);
simd_float4x4 perspectiveProjectionRHFovY( float fovy, float aspectRation, float nearZ, float FarZ);
float radians_from_degrees(float degrees);

#endif /* MathUtilities_h */
