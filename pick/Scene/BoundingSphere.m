//
//  BoundingSphere.m
//  pick
//
//  Created by Paul Nelson on 6/13/22.
//
#import "BoundingSphere.h"
#import "Ray.h"

#define SWAP(a, b) do { typeof(a) temp = a; a = b; b = temp; } while (0)

@implementation BoundingSphere
@synthesize center;
@synthesize radius;
@synthesize intersection;

- (id)initWithCenter: (simd_float3) a_center radius:(float)a_radius {
	self = [super init];
	
	self.center = a_center;
	self.radius = a_radius;
	
	return self;
}

// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection
// Since we are dealing with the need to return success and a value, use a struct to
// enapsulate both pieces if info.
// In the swift code, Float4 is an object an failure can be represented as nil
- (float4_return) intersectWithRay: (Ray *) ray
{
	const float epsilon = 0.000001;  // error term for comparing floats for equality rather than ==
	float t0, t1;
	float radius2 = radius * radius;
	float4_return retVal;
	retVal.success = NO;
	
	// Comparing float for equality is BAD, this should be < a delta not a float equality test.
	//	if( radius2 == 0.f) return retVal;
	if( radius2 < epsilon && radius2 > -epsilon) return retVal;	 // delta comparison not equality
	
	simd_float3 L = center - ray.origin;
	float tca = simd_dot(L, ray.direction);
	
	float d2 = simd_dot(L, L) - tca * tca;
	if (d2 > radius2) return retVal;
	
	float thc = sqrt(radius2 - d2);
	t0 = tca - thc;
	t1 = tca + thc;
	
	if (t0 > t1) { SWAP(t0, t1); }
	
	if (t0 < 0.f) {
		t0 = t1;
		if (t0 < 0.f) return retVal;
	}
	
	retVal.success = YES;
	retVal.value = simd_make_float4(ray.origin + ray.direction * t0, 1.f);
	return retVal;
}

@end


