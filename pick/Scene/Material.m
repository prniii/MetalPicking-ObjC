//
//  Material.m
//  pick
//
//  Created by Paul Nelson on 6/15/22.
//

#import "Material.h"

@implementation Material
@synthesize color;
@synthesize highlighted;

- (id)init
{
	self = [super init];
	if(self) {
		self.color = simd_make_float4(1.f, 1.f, 1.f, 1.f);
		self.highlighted = NO;
	}
	return self;
}

@end
