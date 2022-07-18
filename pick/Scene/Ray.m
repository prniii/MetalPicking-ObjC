//
//  Ray.m
//  pick
//
//  Created by Paul Nelson on 6/13/22.
//

#import "Ray.h"

@implementation Ray

@synthesize origin;
@synthesize direction;

- (id)initWithOrigin:(simd_float3)a_origin direction:(simd_float3)a_direction
{
	self = [super init];
	if (self) {
		self.origin = a_origin;
		self.direction = a_direction;
	}
	return self;
}

// This WAS the func * override!
+ (id)transform:(simd_float4x4)tM ray:(Ray*)ray
{
	simd_float3 originT = simd_mul(tM, simd_make_float4( ray.origin, 1.f)).xyz;
	simd_float3 directionT = simd_mul(tM, simd_make_float4( ray.direction, 0.f)).xyz;
	return [[Ray alloc] initWithOrigin:originT direction:directionT];
}

/// Determine the point along this ray at the given parameter
- (simd_float4)extrapolate:(float)parameter {
	return simd_make_float4(origin + parameter * direction, 1.f);
}

/// Determine the parameter corresponding to the point,
/// assuming it lies on this ray
- (float)interpolate:(simd_float4)point {
	return simd_length(point.xyz - origin) / simd_length(direction);
}
@end
