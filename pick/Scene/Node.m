//
//  Node.m
//  pick
//
//  Created by Paul Nelson on 6/15/22.
//

#import "Node.h"

#import <MetalKit/MetalKit.h>

#import "BoundingSphere.h"
#import "HitResult.h"
#import "Material.h"
#import "Ray.h"


@implementation Node

@synthesize identifier;
@synthesize name;
@synthesize parent;
@synthesize children;
@synthesize camera;
@synthesize mesh;
@synthesize material;
@synthesize transform;
@synthesize boundingSphere;

- (id)init
{
	self = [super init];
	if(self) {
		self.material = [[Material alloc] init];
		self.children = [[NSMutableArray alloc] init];
		self.boundingSphere = [[BoundingSphere alloc] initWithCenter:simd_make_float3(0.f, 0.f, 0.f)
															  radius:0.f];
		self.transform = matrix_identity_float4x4;
	}
	return self;
}

/// compare UUID object identifiers
// Swift has protocols for Equatable, and CustomDebugStringConvertible
// Equatable means == works for this object type
// NSObjects implement/use isEqual: on NSObject  default isEqual is simply == on the reference
// which turns out to be is this exactly the same object not equal values of object. Hence
// the need to overload isEqual:
- (BOOL)isEqual:(id)object
{
	return [identifier isEqual:object];
}

- (simd_float4x4)worldTransform {
	if(parent) {
		return simd_mul(parent.worldTransform, self.transform);
	}
	return self.transform;
}

- (void)addChildNode:(Node*)node {
	if(node.parent) {
		[node removeFromParent];
	}
	[children addObject:node];
}

- (void)removeChildNode:(Node*)node {
	[children removeObject:node];
}

- (void)removeFromParent {
	[parent removeChildNode:self];
}

- (HitResult*)hitTest:(Ray*)ray {

	simd_float4x4 modelToWorld = [self worldTransform];
	//  let localRay = modelToWorld.inverse * ray        // Swift overrode the * operator
	Ray * localRay = [Ray transform: simd_inverse(modelToWorld) ray:ray];
	
	HitResult * nearest = nil;
	float4_return intersectReturn = [boundingSphere intersectWithRay:localRay];
	if(intersectReturn.success) {
		simd_float4 modelPoint = intersectReturn.value;
		simd_float4 worldPoint = simd_mul(modelToWorld, modelPoint);
		float worldParameter = [ray interpolate:worldPoint];
		nearest = [[HitResult alloc] initWithNode:self ray:ray parameter:worldParameter];
	}
	
	HitResult * nearestChildHit = nil;
	for(Node* child in children ) {
		HitResult * childHit =[child hitTest:ray];
		if(childHit) {
			HitResult *nearestActualChildHit = nearestChildHit;
			if(nearestActualChildHit) {
				if(childHit.parameter < nearestActualChildHit.parameter) {
					nearestChildHit = childHit;
				}
			} else {
				nearestChildHit = childHit;
			}
		}
	}
	
	HitResult * nearestActualChildHit = nearestChildHit;
	if(nearestActualChildHit) {
		HitResult * nearestActual = nearest;
		if( nearestActual ) {
			if( nearestActualChildHit.parameter < nearestActual.parameter) {
				return nearestActualChildHit;
			}
		} else {
			return nearestActualChildHit;
		}
	}
	
	return nearest;
}
@end
