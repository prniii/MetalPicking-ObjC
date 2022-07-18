//
//  Scene.h
//  pick
//
//  Created by Paul Nelson on 6/16/22.
//

#import <Foundation/Foundation.h>

@class HitResult;
@class Node;
@class Ray;


NS_ASSUME_NONNULL_BEGIN

@interface Scene : NSObject
@property Node* rootNode;

- (HitResult*)hitTest:(Ray*)ray;

@end

NS_ASSUME_NONNULL_END
