//
//  Node.h
//  pick
//
//  Created by Paul Nelson on 6/15/22.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

@class BoundingSphere;
@class Camera;
@class HitResult;
@class Material;
@class Ray;
@class MTKMesh;

NS_ASSUME_NONNULL_BEGIN

@interface Node : NSObject
@property NSUUID * identifier;
@property NSString * name;
@property (weak) Node * parent;
@property NSMutableArray * children;
@property Camera * camera;
@property MTKMesh * mesh;
@property Material * material;
@property simd_float4x4 transform;
@property BoundingSphere* boundingSphere;

- (simd_float4x4)worldTransform;

- (void)addChildNode:(Node*)node;
- (void)removeChildNode:(Node*)node;
- (void)removeFromParent;
- (HitResult*)hitTest:(Ray*)ray;


@end

NS_ASSUME_NONNULL_END
