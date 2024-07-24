//
//  image.h
//  Codea
//
//  Created by Dylan Sale on 19/11/11.
//  Copyright (c) 2011 Developer. All rights reserved.
//

#ifndef Codify_image_h
#define Codify_image_h

#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif

#import <LuaKit/lua.h>

#import <RuntimeKit/GLFilteredTexture.h>
#import <RuntimeKit/RendererPlatformSupport.h>

#define CODEA_IMAGELIBNAME "image"

typedef void(^CreateImageCompletion)(UIImage *);

typedef enum CodeaImageAlpha
{
    CodeaImageAlphaPremultiply,
    CodeaImageAlphaNoPremultiply,
} CodeaImageAlpha;

typedef enum CodeaImageFormat
{
#if TARGET_OS_SUPPORTS_GL
    CodeaImageFormatNONE = GL_NONE,
    CodeaImageFormatLUMINANCE = GL_R8,
    CodeaImageFormatR8 = GL_R8,
    CodeaImageFormatR16F = GL_R16F,
    CodeaImageFormatR32F = GL_R32F,
    CodeaImageFormatRGB = GL_RGB,
    CodeaImageFormatRGB16F = GL_RGB16F,
    CodeaImageFormatRGB32F = GL_RGB32F,
    CodeaImageFormatRGBA = GL_RGBA,    
    CodeaImageFormatRGBA16F = GL_RGBA16F,
    CodeaImageFormatRGBA32F = GL_RGBA32F,
    CodeaImageFormatDEPTH16 = GL_DEPTH_COMPONENT16,
    CodeaImageFormatDEPTH24 = GL_DEPTH_COMPONENT24,
    CodeaImageFormatDEPTH32F = GL_DEPTH_COMPONENT32F
#else
    CodeaImageFormatNONE,
    CodeaImageFormatLUMINANCE,
    CodeaImageFormatR8,
    CodeaImageFormatR16F,
    CodeaImageFormatR32F,
    CodeaImageFormatRGB,
    CodeaImageFormatRGB16F,
    CodeaImageFormatRGB32F,
    CodeaImageFormatRGBA,
    CodeaImageFormatRGBA16F,
    CodeaImageFormatRGBA32F,
    CodeaImageFormatDEPTH16,
    CodeaImageFormatDEPTH24,
    CodeaImageFormatDEPTH32F
#endif
} CodeaImageFormat;

typedef struct image_format_info_t
{
    uint8_t bytesPerChannel, channels;
    bool floatingPointPixels;
} image_format_info;

typedef unsigned char image_color_element;
typedef struct image_type_data_t {
    image_color_element r,g,b,a;
} image_type_data;

typedef struct image_type_t
{
    lua_Integer scaledWidth, scaledHeight; //Scaled by 1/contentScaleFactor (user facing)
    lua_Integer rawWidth, rawHeight; //The raw size (renderer facing)
    NSUInteger scaleFactor;
    uint8_t* data;
    BOOL dataChanged;
    BOOL needsFlush;
    __unsafe_unretained NSObject<GLFilteredTexture>* texture;
    boolean_t premultiplied;
    CodeaImageFormat imageFormat;
    image_format_info imageFormatInfo;
    
    boolean_t hasFramebuffer;
    GLuint framebufferHandle;
    GLuint depthRenderBuffer;
} image_type;
    
    LUALIB_API int (luaopen_image) (lua_State *L);
    image_type *checkimage(lua_State *L, int i);
    image_type *getimage(lua_State *L, int i);
    image_type *pushimage(lua_State *L, size_t width, size_t height, boolean_t premultipliedAlpha, float scale);
    
    //Create an image_type on the lua stack and draw the UIImage into it as premultiplied RGBA
    image_type* pushUIImage(lua_State* L, UIImage* image);
    
    BOOL canUseImageAsRenderTarget(image_type* image);
    size_t imageDataSize(image_type *image);
    void deleteImage(image_type *image);
    void flushImageIfRequired(image_type* image);
    void updateImageTextureIfRequired(image_type* image);
    void deleteRenderToTextureFBO(image_type* image);
    void createRenderToTextureFBO(image_type* image, BOOL useDepth);
    UIImage* createUIImageFromImage(image_type* image, CodeaImageAlpha alphaOption);
    
#ifdef __cplusplus
}
#endif 

#endif
