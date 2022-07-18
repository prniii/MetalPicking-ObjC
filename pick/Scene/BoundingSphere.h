//
//  BoundingSphere.h
//  pick
//
//  Created by Paul Nelson on 6/13/22.
//
#import <Foundation/Foundation.h>
#import <simd/simd.h>

typedef struct _float4_return {
	BOOL success;
	simd_float4 value;
} float4_return;

NS_ASSUME_NONNULL_BEGIN

@class Ray;

@interface BoundingSphere : NSObject
@property simd_float3 center;
@property float radius;
@property simd_float4 intersection;

- (id)initWithCenter: (simd_float3) a_Center radius:(float)a_radius;
- (float4_return)intersectWithRay: (Ray *) ray;

@end
NS_ASSUME_NONNULL_END
