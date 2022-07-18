//
//  Scene.m
//  pick
//
//  Created by Paul Nelson on 6/16/22.
//

#import "Scene.h"
#import "Node.h"

@implementation Scene
@synthesize rootNode;

- (id)init
{
	self = [super init];
	if(self) {
		rootNode = [[Node alloc] init];
	}
	
	return self;
}
- (HitResult*)hitTest:(Ray*)ray
{
	if(ray)
		return [rootNode hitTest:ray];
	
	return nil;
}
@end
