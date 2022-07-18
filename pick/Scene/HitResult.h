//
//  HitResult.h
//  pick
//
//  Created by Paul Nelson on 6/15/22.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

@class Node;
@class Ray;

NS_ASSUME_NONNULL_BEGIN

@interface HitResult : NSObject
@property Node* node;
@property Ray* ray;
@property float parameter;

- (id)initWithNode:(Node*)node ray:(Ray*)ray parameter:(float)parameter;
- (simd_float4)intersectionPoint;
@end

NS_ASSUME_NONNULL_END
