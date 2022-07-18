//
//  ViewController.m
//  pick
//
//  Created by Paul Nelson on 6/10/22.
//  This is a port from swift to ObjC of the metal-picking sample from metal-by-example
//  By Warren Moore
//  The sample code license is licensed under the MIT License
// 		https://github.com/metal-by-example/metal-picking
//
//  For ease of comparison between this and the original, I have tried to keep
//  variable names and structure as identical as possible.
//
#import "ViewController.h"

#import <AppKit/AppKit.h>	// NSColor
#import <ModelIO/ModelIO.h>

#import "BoundingSphere.h"
#import "Camera.h"
#import "HitResult.h"
#import "Material.h"
#import "MathUtilities.h"
#import "Node.h"
#import "Ray.h"
#import "Renderer.h"
#import "Scene.h"

static const NSInteger GridSideCount = 5;

@implementation ViewController
{
	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	dispatch_semaphore_t frameSemaphore;

	Renderer * renderer;
	Scene * scene;
	Node * pointOfView;
	float cameraAngle;
	MTLVertexDescriptor * vertexDescriptor;
}
@synthesize mtkView;
@synthesize aspectRatio;
/*
/// additional methods added to ViewController
 // Something wrong with this vertex descriptor, got lots of jaggie triangles instead
 // of the sphere so there is some alignment issue going on that makes the info below wrong
 // Used instead, layouts step function, and step rate.
- (MDLVertexDescriptor *) vertexDescriptor
{
	MDLVertexDescriptor * vertexDescriptor = [[MDLVertexDescriptor alloc] init];
	vertexDescriptor.attributes[0].name = MDLVertexAttributePosition;
	vertexDescriptor.attributes[0].format = MDLVertexFormatFloat3;
	vertexDescriptor.attributes[0].offset = 0;
	vertexDescriptor.attributes[0].bufferIndex = 0;
	vertexDescriptor.attributes[1].name = MDLVertexAttributeNormal;
	vertexDescriptor.attributes[1].format = MDLVertexFormatFloat3;
	vertexDescriptor.attributes[1].offset = 3 * sizeof(float);
	vertexDescriptor.attributes[1].bufferIndex = 0;
	vertexDescriptor.layouts[0].stride = 6 * sizeof(float);
	
	return vertexDescriptor;
}
*/
- (void)makeScene
{
	cameraAngle = 0.f;
	float sphereRadius = 1.f;
	float spherePadding = 1.f;
	MTKMeshBufferAllocator * meshAllocator
		= [[MTKMeshBufferAllocator alloc] initWithDevice:device];

	/* either works fine, both give the same thing.
	 MDLMesh * mdlMesh =
		[MDLMesh newEllipsoidWithRadii:simd_make_float3(sphereRadius, sphereRadius, sphereRadius)
						radialSegments:20
					  verticalSegments:20
						  geometryType:MDLGeometryTypeTriangles
						 inwardNormals:NO
							hemisphere:NO
							 allocator:meshAllocator];
		
	*/
	MDLMesh * mdlMesh =
	[[MDLMesh alloc] initSphereWithExtent:simd_make_float3(sphereRadius, sphereRadius, sphereRadius)
								 segments:simd_make_uint2(20,20)
							inwardNormals:NO
							 geometryType:MDLGeometryTypeTriangles
								allocator:meshAllocator];
	/*
	 // instead use largest box inside sphere radius. Better is for each node to have one
	 // bounding volume function.
	 // FIXME: The render structure of this program is set up for a grid of identical objects.
	 // It does not support not a grid of individual objects.
	float sidelen = 2*sphereRadius / sqrt(3.f);  // max sized cube inside sphereRadius
	MDLMesh *mdlMesh = [MDLMesh newBoxWithDimensions:(vector_float3){sidelen,sidelen,sidelen} segments:(vector_uint3){1,1,1}
									geometryType:MDLGeometryTypeTriangles
								   inwardNormals:NO
									   allocator:meshAllocator];
	*/
	/// ! Vertex descriptor is tied to Mesh! so you can't render different object types...the way this program works....
	/// each needs a different render pass descriptor...
	vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor);
	vertexDescriptor.layouts[0].stepRate = 1;
	vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

	
	NSError * err = nil;
	MTKMesh * sphereMesh = [[MTKMesh alloc] initWithMesh:mdlMesh device:device error:&err];
	if(err) {
		NSLog(@"Could not create MetalKit mesh from ModelIO mesh");
		return;
	}
	float gridSideLength = (sphereRadius * 2.f * (float)GridSideCount) + (spherePadding * (float)(GridSideCount -1) );

	for( NSInteger j = 0; j < GridSideCount; j++) {
		for (NSInteger i = 0; i < GridSideCount; i++) {
			Node * node = [[Node alloc] init];
			node.mesh = sphereMesh;
			//node.material.color = simd_make_float4(drand48(), 1.f, 1.f, 1.f);
			// Swift version used HSB, so to create similarly
			NSColor * color = [NSColor colorWithColorSpace:[NSColorSpace sRGBColorSpace]
													   hue:drand48()
												saturation:1.f
												brightness:1.f
													 alpha:1.f];

			CGFloat red, green, blue, alpha;
			[color getRed:&red green:&green blue:&blue alpha:&alpha];
			node.material.color = simd_make_float4(red,green,blue,alpha);
			
			simd_float3 position = simd_make_float3(
				sphereRadius + (float)i * (2.f * sphereRadius + spherePadding) - (float)(gridSideLength/2.f),
				sphereRadius + (float)j * (2.f * sphereRadius + spherePadding) - (float)(gridSideLength/2.f),
				0.f);
			node.transform = translateBy(position);
			node.boundingSphere.radius = sphereRadius;
			node.name = [NSString stringWithFormat:@"Node: %ld, %ld", (long)i, (long)j];
			[scene.rootNode addChildNode:node];
		}
	}
	Node * cameraNode = [[Node alloc] init];
	cameraNode.transform = translateBy(simd_make_float3(0.f, 0.f, 15.f));
	cameraNode.camera = [[Camera alloc] init];
	pointOfView = cameraNode;
	[scene.rootNode addChildNode:cameraNode];
}

/// View methods
- (void)viewDidLoad {
	[super viewDidLoad];

    aspectRatio = (float)self.view.bounds.size.width / (float)self.view.bounds.size.height;
    
	// Do any additional setup after loading the view.
	frameSemaphore = dispatch_semaphore_create(MaxInFlightFrameCount);
	device = MTLCreateSystemDefaultDevice();
	commandQueue = [device newCommandQueue];
	
	mtkView = (MTKView*)self.view;
	mtkView.device = device;
	mtkView.sampleCount = 4;
	mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
	mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
	mtkView.delegate = self;
	
	scene = [[Scene alloc] init];
	[self makeScene]; // Make Scene creates the vertexDescriptor based on ModelIO descriptor
	
	// FIXME: the renderer taking the vertex descriptor means the objects rendered all have to be the SAME.
	// For example you can't make the object in the center a cube, since it's vertex descriptor
	// does not contain the same data as a sphere primitive.  Instead it needs to be paired with the
	// object Node.
	renderer = [[Renderer alloc] initWithView:mtkView vertexDescriptor:vertexDescriptor];
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint location =  [mtkView convertPoint:event.locationInWindow fromView:nil];
	location.y = mtkView.bounds.size.height - location.y; // Flip from AppKit default window coordinates to Metal viewport coordinates
	[self handleInteraction: location];
}

- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

/// MTKViewDelegate Methods

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
	aspectRatio = (float)view.bounds.size.width / (float)view.bounds.size.height;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
	@autoreleasepool {
		dispatch_semaphore_wait(frameSemaphore, DISPATCH_TIME_FOREVER);
		
		cameraAngle += 0.01;
		id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
		if(commandBuffer == nil) return;
		
		MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
		if(renderPassDescriptor == nil) return;
		
		id <MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
		if(renderCommandEncoder == nil) return;
		
		pointOfView.transform = simd_mul(rotateAroundAxis(simd_make_float3(0.f, 1.f, 0.f), cameraAngle), translateBy(simd_make_float3(0.f, 0.f, 15.f)) );
		
		[renderer drawWithScene:scene pointOfView:pointOfView in:renderCommandEncoder];
		
		[renderCommandEncoder endEncoding];
		
		id<CAMetalDrawable> drawable = view.currentDrawable;
		[commandBuffer presentDrawable:drawable];
		[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
			dispatch_semaphore_signal(self->frameSemaphore);
			if(buffer.status == MTLCommandBufferStatusError) {
				if (buffer.error) {
					NSLog(@"Command Buffer Status error: %@", buffer.error.localizedDescription);
				} else {
					NSLog(@"Command Buffer error, nil message");
				}
			}
		}];
		[commandBuffer commit];	}
}

- (void)handleInteraction:(CGPoint)point
{
	if(pointOfView == nil) return;
	Camera * camera = pointOfView.camera;
	if(camera == nil) return;
	
	CGRect viewport = mtkView.bounds;

	simd_float4x4 projectionMatrix = [camera projectionMatrix:aspectRatio];
	simd_float4x4 invProjectionMatrix = simd_inverse(projectionMatrix);
	simd_float4x4 invViewMatrix = pointOfView.worldTransform;
	
	float clipX = -1 + (2.f * point.x) / viewport.size.width;
	float clipY = 1.f - (2.f * point.y) / viewport.size.height;
	
	// Assume clip space is hemicube, -Z into the  screen
	simd_float4 clipCoords = simd_make_float4(clipX, clipY, 0.f, 1.f);
	simd_float4 eyeRayDir = matrix_multiply(invProjectionMatrix, clipCoords);
	eyeRayDir.z = -1.f;
	eyeRayDir.w = 0;
	
	simd_float3 worldRayDir = simd_normalize( matrix_multiply(invViewMatrix, eyeRayDir).xyz );	
	simd_float4 eyeRayOrigin = simd_make_float4(0.f, 0.f, 0.f, 1.f);
	simd_float3 worldRayOrigin = matrix_multiply(invViewMatrix, eyeRayOrigin).xyz;
	
	Ray * ray = [[Ray alloc] initWithOrigin:worldRayOrigin direction:worldRayDir];
	HitResult * hit = [scene hitTest:ray];
	if (hit != nil) {
		hit.node.material.highlighted = !hit.node.material.highlighted;
		simd_float4 intersect = [hit intersectionPoint];
		NSLog(@"hit %@ at %f,%f,%f", hit.node.name, intersect.x, intersect.y, intersect.z);
	}
}
@end
