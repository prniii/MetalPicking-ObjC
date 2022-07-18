//
//  HitResult.m
//  pick
//
//  Created by Paul Nelson on 6/15/22.
//

#import "HitResult.h"
#import "Node.h"
#import "Ray.h"

@implementation HitResult
@synthesize node;
@synthesize ray;
@synthesize parameter;

- (id)initWithNode:(Node*)a_node ray:(Ray*)a_ray parameter:(float)a_parameter
{
	self = [super init];
	if(self) {
		node = a_node;
		ray = a_ray;
		parameter = a_parameter;
	}
	return self;
}

- (simd_float4)intersectionPoint {
	return simd_make_float4(ray.origin + parameter * ray.direction, 1.f);
}

@end
