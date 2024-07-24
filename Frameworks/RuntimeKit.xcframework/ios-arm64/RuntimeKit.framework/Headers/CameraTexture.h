//
//  CameraTexture.h
//  Codea
//
//  Created by Dylan Sale on 1/09/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

// Largely taken and modified from the Rosy Writer Example code by Apple

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMBufferQueue.h>

#import "RendererPlatformSupport.h"
#import <RuntimeKit/GLFilteredTexture.h>
#import <RuntimeKit/Renderer.h>

extern NSString * const CameraTextureErrorNotification;
extern NSString * const CameraTextureErrorKey;

typedef void(^CameraDataBlock)(uint8_t* data, size_t width, size_t height, size_t bytesPerRow);

#if TARGET_OS_SUPPORTS_CAPTURE

//Captures and stores images from a camera in an OpenGL Texture for later use in rendering.
@interface CameraTexture : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDataOutputSynchronizerDelegate, GLFilteredTexture>
{
    //Video capture data
    CMVideoDimensions videoDimensions;
	CMVideoCodecType videoType;
    
	AVCaptureSession *captureSession;
    AVCaptureDataOutputSynchronizer *outputSynchronizer;
	CMBufferQueueRef previewBufferQueue;

	AVCaptureVideoOrientation referenceOrientation;
	AVCaptureVideoOrientation videoOrientation;
    
    //OpenGL data
    int renderBufferWidth;
	int renderBufferHeight;
    
#if TARGET_OS_SUPPORTS_GL
	CVOpenGLESTextureCacheRef videoTextureCache;
    CVOpenGLESTextureRef texture;
    CVOpenGLESTextureRef depthTexture;
#endif
    
    CVImageBufferRef lastFrame;
    
    dispatch_queue_t videoCaptureQueue;
}

@property (readonly) CMVideoDimensions videoDimensions;
@property (readonly) CMVideoCodecType videoType;

@property (readwrite) AVCaptureVideoOrientation referenceOrientation;
@property (nonatomic, readonly) AVCaptureVideoOrientation videoOrientation;

@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition; //Can only be set when there is no active capture session.

//- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation;

- (id) initWithRenderer:(Renderer*)renderer;

+ (BOOL) cameraTextureAvailable;

- (void) showError:(NSError*)error;

#if TARGET_OS_SUPPORTS_GL
- (void) setupCaptureSessionWithContext:(EAGLContext*)context;
#endif

- (void) stopAndTearDownCaptureSession;

- (void) pauseCaptureSession;
- (void) resumeCaptureSession;

- (void) releaseFrame;
- (GLuint) textureName;
- (GLenum) textureTarget;
- (BOOL) hasTexture;

- (GLuint) depthTextureName;
- (GLenum) depthTextureTarget;
- (BOOL) hasDepthTexture;

- (BOOL) lastFrameTexture:(CameraDataBlock) cameraDataBlock; //Returns whether the frame is available

- (void) setOrientation:(UIDeviceOrientation)deviceOrientation;
- (void) setInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;


# pragma mark - GLFilteredTexture

- (void) setAntiAliasTexParameters;
- (void) setAliasTexParameters;

- (BOOL) bindTexture;
- (BOOL) bindDepthTexture;

/** texture name */
@property(nonatomic,readonly) GLuint name;

/** width in pixels */
@property(nonatomic,readonly) NSUInteger pixelsWide;
/** hight in pixels */
@property(nonatomic,readonly) NSUInteger pixelsHigh;

/** scale factor (for retina, this should be 2.0 if the image is @2x) */
@property(nonatomic,assign) CGFloat scale;


@end

#endif
