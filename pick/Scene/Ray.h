//
//  Ray.h
//  pick
//
//  Created by Paul Nelson on 6/13/22.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface Ray : NSObject
@property simd_float3 origin;
@property simd_float3 direction;

- (id)initWithOrigin:(simd_float3)origin direction:(simd_float3)direction;
- (simd_float4)extrapolate:(float)parameter;
- (float)interpolate:(simd_float4)point;

+ (id)transform:(simd_float4x4)tM ray:(Ray*)ray;

@end

NS_ASSUME_NONNULL_END
