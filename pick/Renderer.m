//
//  Renderer.m
//  pick
//
//  Created by Paul Nelson on 6/16/22.
//
#import "Renderer.h"

#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>

#import "Camera.h"
#import "Node.h"
#import "Material.h"
#import "Scene.h"


const size_t ConstantBufferLength = 65536;
const size_t ConstantAlignment = 256;

@implementation Renderer
@synthesize view;
@synthesize device;
@synthesize renderPipelineState;
@synthesize depthStencilState;
//@synthesize constantBuffers;
@synthesize frameIndex;

- (id)initWithView:(MTKView*)view
  vertexDescriptor:(MTLVertexDescriptor*)vetexDescriptor
{
	self = [super init];
	if(self) {
		self.view = view;
		self.device = (view.device) ? view.device : MTLCreateSystemDefaultDevice();
		self.frameIndex = 0;
	}
	
	depthStencilState = [self makeDepthStencilStateWithDevice:device];
	
	constantBuffers = [[NSMutableArray alloc] init];
	for (int i = 0; i < MaxInFlightFrameCount; i++) {
		[constantBuffers addObject:[device newBufferWithLength:ConstantBufferLength options:MTLResourceStorageModeShared] ];
	}
	renderPipelineState = [self makeRenderPipelineStateWithView:(MTKView*)view vertexDescriptor:vetexDescriptor];
	
	return self;
}

- (id<MTLDepthStencilState>)makeDepthStencilStateWithDevice:(id<MTLDevice>)device
{
	MTLDepthStencilDescriptor *depthStateDescriptor = [[MTLDepthStencilDescriptor alloc] init];
	depthStateDescriptor.depthCompareFunction = MTLCompareFunctionLess;
	depthStateDescriptor.depthWriteEnabled = YES;
	return [device newDepthStencilStateWithDescriptor:depthStateDescriptor];
}

- (id<MTLRenderPipelineState>)makeRenderPipelineStateWithView:(MTKView*)view vertexDescriptor:(MTLVertexDescriptor*)vertexDescriptor
{
	// swift code throws, so additional error checking necessary
	if(view == nil)  {
		NSLog(@"view cannot be nil");
		return nil;
	} else if(view.device == nil) {
		NSLog(@"device cannot be nil");
		   return nil;
   }
		
	id<MTLLibrary>library = [device newDefaultLibrary];
	if(library == nil) {
		NSLog(@"failed to create default metal library");
		return nil;
	}
	
	id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
	id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
	
//	MTLVertexDescriptor * mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor);
	MTLRenderPipelineDescriptor * pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
	pipelineDescriptor.vertexFunction = vertexFunction;
	pipelineDescriptor.fragmentFunction = fragmentFunction;
//	pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor;
	pipelineDescriptor.vertexDescriptor = vertexDescriptor;
	pipelineDescriptor.sampleCount = view.sampleCount;
	pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
	pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
	
	return [view.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
}


- (void)drawWithNode:(Node*)node
	  worldTransform:(simd_float4x4)worldTransform
		  viewMatrix:(simd_float4x4)viewMatrix
	projectionMatrix:(simd_float4x4)projectionMatrix
	  constantOffset:(int*)constantOffset
	in:(id<MTLRenderCommandEncoder>)renderCommandEncoder
{
	simd_float4x4 worldMatrix = simd_mul(worldTransform, node.transform);
	InstanceConstants constants;
	constants.modelViewProjectionMatrix = simd_mul(projectionMatrix, simd_mul( viewMatrix, worldMatrix));
	constants.normalMatrix = simd_mul( viewMatrix, worldMatrix );
	constants.color = node.material.color;
	
	id<MTLBuffer> constantBuffer = constantBuffers[frameIndex];
	void* ptr = [constantBuffer contents];
	ptr += *constantOffset;
	memcpy(ptr, &constants, sizeof(InstanceConstants));
	
	[renderCommandEncoder setVertexBufferOffset:*constantOffset atIndex:1];
	
	MTKMesh * mesh = node.mesh;
	
	if (mesh != nil) {
		[mesh.vertexBuffers enumerateObjectsUsingBlock:^(MTKMeshBuffer * _Nonnull vertexBuffer, NSUInteger index, BOOL * _Nonnull stop) {
			[renderCommandEncoder setVertexBuffer:vertexBuffer.buffer offset:vertexBuffer.offset atIndex:index];
		}];
		
		for (MTKSubmesh * submesh in mesh.submeshes) {
			MTLTriangleFillMode fillMode = node.material.highlighted ? MTLTriangleFillModeLines : MTLTriangleFillModeFill;
			[renderCommandEncoder setTriangleFillMode:fillMode];
			[renderCommandEncoder drawIndexedPrimitives:submesh.primitiveType
											 indexCount:submesh.indexCount
											  indexType:submesh.indexType
											indexBuffer:submesh.indexBuffer.buffer
									  indexBufferOffset:submesh.indexBuffer.offset];
		}
	}
	
	*constantOffset += ConstantAlignment;
	
	for (Node* child in node.children) {
		[self drawWithNode:child
			 worldTransform: worldTransform
				 viewMatrix: viewMatrix
		   projectionMatrix: projectionMatrix
			 constantOffset: constantOffset
						 in: renderCommandEncoder];
	}
}

- (void)drawWithScene:(Scene *)scene pointOfView:(Node*)pov in:(id<MTLRenderCommandEncoder>)renderCommandEncoder
{
	Node * cameraNode = pov;
	if( cameraNode == nil) { NSLog(@"Nil camera node"); return; }
	Camera * camera = cameraNode.camera;
	if( camera == nil) { NSLog(@"Nil camera"); return; }
	
	frameIndex = (frameIndex + 1) % MaxInFlightFrameCount;
	
	[renderCommandEncoder setRenderPipelineState:renderPipelineState];
	[renderCommandEncoder setDepthStencilState:depthStencilState];
	
	simd_float4x4 viewMatrix = simd_inverse(cameraNode.worldTransform);
	CGRect viewport = view.bounds;
	float aspectRatio = viewport.size.width / viewport.size.height;
	
	simd_float4x4 projectionMatrix = [camera projectionMatrix:aspectRatio];
	
	simd_float4x4 worldMatrix = matrix_identity_float4x4;
	
	id<MTLBuffer> constantbuffer = constantBuffers[frameIndex];
	[renderCommandEncoder setVertexBuffer:constantbuffer offset:0 atIndex:1];
	
	int constantOffset = 0;
	[self drawWithNode:scene.rootNode
		worldTransform:worldMatrix
			viewMatrix:viewMatrix
	  projectionMatrix:projectionMatrix
		constantOffset:&constantOffset
					in:renderCommandEncoder];
}


@end
