//
//  Renderer.h
//  pick
//
//  Created by Paul Nelson on 6/16/22.
//
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

// Forward Declarations
@class Scene;
@class Node;
@class MTKView;
@class NSMutableArray;

typedef struct {
	simd_float4x4 modelViewProjectionMatrix;
	simd_float4x4 normalMatrix;
	simd_float4 color;
} InstanceConstants;

NS_ASSUME_NONNULL_BEGIN

static const NSUInteger MaxInFlightFrameCount = 3;

@interface Renderer : NSObject
{
	NSMutableArray *constantBuffers;
}
@property MTKView * view;
@property id<MTLDevice> device;
@property id<MTLRenderPipelineState> renderPipelineState;
@property id<MTLDepthStencilState> depthStencilState;
//@property id<MTLBuffer> constantBuffers;
@property NSUInteger frameIndex;

- (id)initWithView:(MTKView *)view vertexDescriptor:(MTLVertexDescriptor*)vetexDescriptor;
- (void)drawWithScene:(Scene *)scene pointOfView:(Node*)pov
	in:(id<MTLRenderCommandEncoder>)renderCommandEncoder;
- (id<MTLDepthStencilState>)makeDepthStencilStateWithDevice:(id<MTLDevice>)device;
- (id<MTLRenderPipelineState>)makeRenderPipelineStateWithView:(MTKView*)view vertexDescriptor:(MTLVertexDescriptor*)vertexDescriptor;
@end

NS_ASSUME_NONNULL_END
