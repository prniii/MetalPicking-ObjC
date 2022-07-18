//
//  Camera.m
//  pick
//
//  Created by Paul Nelson on 6/15/22.
//

#import "Camera.h"
#import "MathUtilities.h"

@implementation Camera
@synthesize fieldOfView;
@synthesize nearZ;
@synthesize farZ;

- (id)init
{
	self = [super init];
	if (self) {
		// Sample program uses default values for fov, nearZ and farZ so set them here
		fieldOfView = 65.0f;
		nearZ = 0.1f;
		farZ = 100.f;
	}
	return self;
}

- (id)initWithFOV:(float)fov nearZ:(float)near farZ:(float)far
{
	self = [super init];
	if(self) {
		fieldOfView = fov;
		nearZ = near;
		farZ = far;
	}
	return self;
}

- (simd_float4x4)projectionMatrix:(float)aspectRatio
{
	return perspectiveProjectionRHFovY(radians_from_degrees(fieldOfView),
									   aspectRatio,
									   nearZ, farZ);
}
@end
