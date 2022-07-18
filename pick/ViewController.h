//
//  ViewController.h
//  pick
//
//  Created by Paul Nelson on 6/10/22.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>	// Needs MTKViewDelegate


@interface ViewController : NSViewController<MTKViewDelegate>
@property MTKView * mtkView;
@property float aspectRatio;

- (void)handleInteraction:(CGPoint)point;
@end

