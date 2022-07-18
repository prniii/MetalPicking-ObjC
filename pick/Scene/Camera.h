//
//  Camera.h
//  pick
//
//  Created by Paul Nelson on 6/15/22.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>


NS_ASSUME_NONNULL_BEGIN

@interface Camera : NSObject
@property float fieldOfView;
@property float nearZ;
@property float farZ;

- (id)initWithFOV:(float)fov nearZ:(float)near farZ:(float)far;
- (simd_float4x4)projectionMatrix:(float)aspectRatio;

@end

NS_ASSUME_NONNULL_END
