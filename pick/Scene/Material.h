//
//  Material.h
//  pick
//
//  Created by Paul Nelson on 6/15/22.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface Material : NSObject
@property simd_float4 color;
@property BOOL highlighted;

@end

NS_ASSUME_NONNULL_END
