//
//  RenderManager.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 28/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <RuntimeKit/RendererPlatformSupport.h>

#if TARGET_OS_SUPPORTS_GL
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#endif

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include <vector>
#include <string>
#include <map>
#include <set>

#define printOpenGLError() printOglError(__FILE__, __LINE__)

int printOglError(const char *file, int line);

@class Shader;
@class SpriteBatch;
@class TextRenderer;
@class ScreenCapture;
@class CameraTexture;
@class RuntimeViewController;
@class TextureCache;

struct image_type_t;

enum RenderManagerBlendingMode
{
    BLEND_TYPE_NONE,
    BLEND_TYPE_NORMAL,
    BLEND_TYPE_PREMULT
};

struct GraphicsStyle
{
    enum ShapeMode
    {
        SHAPE_MODE_CORNER,
        SHAPE_MODE_CORNERS,  
        SHAPE_MODE_CENTER,
        SHAPE_MODE_RADIUS,
    };
    
    enum BlendMode
    {
        BLEND_MODE_NORMAL,
        BLEND_MODE_ADDITIVE,
        BLEND_MODE_MULTIPLY,
        BLEND_MODE_DISABLED,
    };
    
    enum BlendEquation
    {
#if TARGET_OS_SUPPORTS_GL
        BLEND_EQUATION_ADD = GL_FUNC_ADD,
        BLEND_EQUATION_SUBTRACT = GL_FUNC_SUBTRACT,
        BLEND_EQUATION_REVERSE_SUBTRACT = GL_FUNC_REVERSE_SUBTRACT,
        BLEND_EQUATION_MIN = GL_MIN_EXT,
        BLEND_EQUATION_MAX = GL_MAX_EXT,
#else
        BLEND_EQUATION_ADD,
        BLEND_EQUATION_SUBTRACT,
        BLEND_EQUATION_REVERSE_SUBTRACT,
        BLEND_EQUATION_MIN,
        BLEND_EQUATION_MAX,
#endif
    };
    
    enum AdvancedBlendMode
    {
#if TARGET_OS_SUPPORTS_GL
        ADV_BLEND_NONE = -1,
        ADV_BLEND_ZERO = GL_ZERO,
        ADV_BLEND_ONE = GL_ONE,
        ADV_BLEND_SRC_COLOR = GL_SRC_COLOR,
        ADV_BLEND_ONE_MINUS_SRC_COLOR = GL_ONE_MINUS_SRC_COLOR,
        ADV_BLEND_SRC_ALPHA = GL_SRC_ALPHA,
        ADV_BLEND_ONE_MINUS_SRC_ALPHA = GL_ONE_MINUS_SRC_ALPHA,
        ADV_BLEND_DST_ALPHA = GL_DST_ALPHA,
        ADV_BLEND_ONE_MINUS_DST_ALPHA = GL_ONE_MINUS_DST_ALPHA,
        ADV_BLEND_DST_COLOR = GL_DST_COLOR,
        ADV_BLEND_ONE_MINUS_DST_COLOR = GL_ONE_MINUS_DST_COLOR,
        ADV_BLEND_SRC_ALPHA_SATURATE = GL_SRC_ALPHA_SATURATE,
#else
        ADV_BLEND_NONE,
        ADV_BLEND_ZERO,
        ADV_BLEND_ONE,
        ADV_BLEND_SRC_COLOR,
        ADV_BLEND_ONE_MINUS_SRC_COLOR,
        ADV_BLEND_SRC_ALPHA,
        ADV_BLEND_ONE_MINUS_SRC_ALPHA,
        ADV_BLEND_DST_ALPHA,
        ADV_BLEND_ONE_MINUS_DST_ALPHA,
        ADV_BLEND_DST_COLOR,
        ADV_BLEND_ONE_MINUS_DST_COLOR,
        ADV_BLEND_SRC_ALPHA_SATURATE,
#endif
    };
    
    enum LineCapMode
    {
        LINE_CAP_ROUND,
        LINE_CAP_SQUARE,
        LINE_CAP_PROJECT, //square, but same size as ROUND
        LINE_CAP_NUM_MODES,
    };
    
    enum TextAlign
    {
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_RIGHT,
        TEXT_ALIGN_CENTER = SHAPE_MODE_CENTER,        
    };
    
    GraphicsStyle() :
        strokeWidth(0.0f), strokeColor(1,1,1,1), fillColor(0.5,0.5,0.5,1), tintColor(1,1,1,1), pointSize(3.0f),
        spriteMode(SHAPE_MODE_CENTER), rectMode(SHAPE_MODE_CORNER),
        ellipseMode(SHAPE_MODE_CENTER), textMode(SHAPE_MODE_CENTER),
        lineCapMode(LINE_CAP_ROUND), smooth(YES),
        blendMode(BLEND_MODE_NORMAL),
        blendSource(ADV_BLEND_NONE), blendDest(ADV_BLEND_NONE),
        blendSourceAlpha(ADV_BLEND_NONE), blendDestAlpha(ADV_BLEND_NONE),
        blendEquation(BLEND_EQUATION_ADD), blendEquationAlpha(BLEND_EQUATION_ADD),
        textAlign(TEXT_ALIGN_LEFT), fontSize(17.0f), textWrapWidth(0), fontName("Helvetica")
    {}
    
    float       strokeWidth;
    glm::vec4   strokeColor;    
    
    glm::vec4   fillColor;    
    float       pointSize;      
    
    glm::vec4   tintColor;
    
    ShapeMode   rectMode;
    ShapeMode   ellipseMode;  
    ShapeMode   spriteMode;
    ShapeMode   textMode;
    LineCapMode lineCapMode;
    
    BOOL        smooth;
    
    BlendMode   blendMode;
    BlendEquation blendEquation;
    BlendEquation blendEquationAlpha;
    AdvancedBlendMode blendSource;
    AdvancedBlendMode blendDest;
    AdvancedBlendMode blendSourceAlpha;
    AdvancedBlendMode blendDestAlpha;
    
    std::string fontName;
    float       fontSize;
    float       textWrapWidth;
    TextAlign   textAlign;                    
};

typedef std::map<GLuint, glm::mat4> XFormCache;
typedef std::map<GLuint, glm::vec4> ColorCache;

@interface RenderManager : NSObject 
{
    std::vector<glm::mat4>      modelMatrixStack;
    std::vector<GraphicsStyle>  styleStack;
    
    glm::mat4 modelViewMatrix;
    glm::mat4 viewMatrix;
    glm::mat4 projectionMatrix;
    glm::mat4 savedProjectionMatrix;
    
    //This matrix is used to invert for video recording
    glm::mat4 fixMatrix;
    
    //GLuint currentTexture;
    
    //Batches and renders sprites
    SpriteBatch *spriteBatch;
    
    //Caches and renders text
    TextRenderer *textRenderer;
    
    RenderManagerBlendingMode currentBlendModeType;
    GraphicsStyle::AdvancedBlendMode currentBlendSource;
    GraphicsStyle::AdvancedBlendMode currentBlendDest;
    GraphicsStyle::AdvancedBlendMode currentBlendSourceAlpha;
    GraphicsStyle::AdvancedBlendMode currentBlendDestAlpha;
    
    //GLenum activeTexture;
    
    struct image_type_t *currentRenderTarget;
    GLuint offscreenFramebuffer;
    
    NSUInteger frameCount;    
    ScreenCapture* __weak capture;
}

@property (nonatomic, assign) NSUInteger frameCount;

#pragma mark - Texture cache
@property (nonatomic, readonly) TextureCache* textureCache;

#pragma mark - Text renderer
@property (nonatomic, readonly) TextRenderer *textRenderer;

#pragma mark - Sprite Batcher
@property (nonatomic, readonly) SpriteBatch *spriteBatch;
@property (nonatomic, assign) BOOL useSpriteBatching;

#pragma mark - Render target
@property (nonatomic, readonly) struct image_type_t *currentRenderTarget;

#pragma mark - Vertex Buffer Objects
@property (nonatomic, readonly) GLuint spriteVertexVBO;
@property (nonatomic, readonly) GLuint spriteUVVBO;
@property (nonatomic, readonly) GLuint spriteReversedUVVBO;

#pragma mark - GLM model view matrix
@property (nonatomic, readonly) glm::mat4 glmModelViewMatrix;

#pragma mark - Raw model matrix pointers 
@property (nonatomic, readonly) const float *modelMatrix;
@property (nonatomic, readonly) const float *viewMatrix;
@property (nonatomic, readonly) const float *projectionMatrix;
@property (nonatomic, readonly) const float *modelViewMatrix;

#pragma mark - Fonts
@property (nonatomic, readonly) const char *fontName;
@property (nonatomic, readonly) CGFloat fontSize;
@property (nonatomic, readonly) CGFloat textWrapWidth;
@property (nonatomic, readonly) GraphicsStyle::TextAlign textAlign;

#pragma mark - Raw style pointers
@property (nonatomic, readonly) const float *strokeWidth;
@property (nonatomic, readonly) const float *strokeColor;
@property (nonatomic, readonly) const float *fillColor;
@property (nonatomic, readonly) const float *tintColor;
@property (nonatomic, readonly) const float *pointSize;

#pragma mark - Shape modes
@property (nonatomic, readonly) GraphicsStyle::ShapeMode rectMode;
@property (nonatomic, readonly) GraphicsStyle::ShapeMode spriteMode;
@property (nonatomic, readonly) GraphicsStyle::ShapeMode ellipseMode;
@property (nonatomic, readonly) GraphicsStyle::ShapeMode textMode;
@property (nonatomic, readonly) GraphicsStyle::LineCapMode lineCapMode;

#pragma mark - Graphics modes
@property (nonatomic, readonly) BOOL smooth;
@property (nonatomic, readonly) GraphicsStyle::BlendMode blendMode;
@property (nonatomic, readonly) GraphicsStyle::AdvancedBlendMode blendSource;
@property (nonatomic, readonly) GraphicsStyle::AdvancedBlendMode blendDest;
@property (nonatomic, readonly) GraphicsStyle::AdvancedBlendMode blendSourceAlpha;
@property (nonatomic, readonly) GraphicsStyle::AdvancedBlendMode blendDestAlpha;
@property (nonatomic, readonly) GraphicsStyle::BlendEquation blendEquation;
@property (nonatomic, readonly) GraphicsStyle::BlendEquation blendEquationAlpha;

#pragma mark - Screen capture
@property (nonatomic, weak) ScreenCapture* capture;

@property (nonatomic, strong, readonly) CameraTexture* cameraTexture;
#if !TARGET_OS_TV
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
#endif

- (id) initWithCodeaContext:(id)codeaContext;
- (void) reset;
- (void) setupNextFrameState;
- (void) resetOffscreenFramebuffer;
- (void) deleteOffscreenFramebuffer;
- (void) clearModelMatrixStack;
- (void) saveProjectionMatrix;

- (void) useShader:(Shader*)shader;
- (void) useShader:(Shader*)shader withMatrix:(const float*)matdata;

- (Shader*) shaderNamed:(NSString*)shaderName;
- (Shader*) useInternalShaderNamed:(NSString*)shaderName;
- (void) useInternalShaderCached:(Shader*)shader;

- (void) useTexture:(GLuint)textureName;
- (void) useTexture:(GLuint)textureName withTarget:(GLenum)target;
- (BOOL) useCameraTexture:(BOOL)useDepth; //Returns true if a camera texture is available else false

#pragma mark - Shader upload functions

- (void) uploadMatrix:(glm::mat4*)matrix key:(NSString*)key shader:(__unsafe_unretained Shader*)shader;

#pragma mark - Sprite Caching

- (void) flushSpriteBatch;
- (void) flushSpriteBatchAndEndFrame;

#pragma mark - Framebuffer

- (void) setFramebuffer:(struct image_type_t*)image useDepth:(BOOL)depth;
- (BOOL) flushCurrentRenderTarget;

#pragma mark - View

- (void) orthoLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top;
- (void) orthoLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top zNear:(float)near zFar:(float)far;
- (void) perspectiveFOV:(float)fovy aspect:(float)aspect zNear:(float)near zFar:(float)far;

- (void) scissorTestX:(float)x y:(float)y width:(float)w height:(float)h;
- (void) noScissorTest;

#pragma mark - Attributes

- (void) setAttributeNamed:(NSString*)name withPointer:(const GLvoid*)ptr size:(GLint)size andType:(GLenum)type;
- (void) setBufferedAttributeNamed:(NSString*)name size:(GLint)size andType:(GLenum)type;
- (void) disableAttributeNamed:(NSString*)name;

#pragma mark - Transform

- (void) rotateModel:(float)angle x:(float)x y:(float)y z:(float)z;
- (void) scaleModel:(float)x y:(float)y z:(float)z;
- (void) translateModel:(float)x y:(float)y z:(float)z;

- (void) pushMatrix;
- (void) popMatrix;
- (void) resetMatrix;
- (void) multMatrix:(const glm::mat4&)matrix;
- (void) setMatrix:(const glm::mat4&)matrix;
- (void) setViewMatrix:(const glm::mat4&)matrix;
- (void) setProjectionMatrix:(const glm::mat4&)matrix;
- (void) setFixMatrix:(const glm::mat4&)matrix;

#pragma mark - Style

- (BOOL) useStroke;

- (void) setStyleFontName:(const char*)name;
- (void) setStyleFontSize:(CGFloat)size;
- (void) setStyleTextWrapWidth:(CGFloat)wrap;
- (void) setStyleTextAlign:(GraphicsStyle::TextAlign)align;

- (void) setStyleTintColor:(glm::vec4)tint;
- (void) setStyleFillColor:(glm::vec4)fill;
- (void) setStyleStrokeColor:(glm::vec4)stroke;
- (void) setStyleStrokeWidth:(float)width;
- (void) setStylePointSize:(float)size;

- (void) setStyleSpriteMode:(GraphicsStyle::ShapeMode)mode;
- (void) setStyleRectMode:(GraphicsStyle::ShapeMode)mode;
- (void) setStyleEllipseMode:(GraphicsStyle::ShapeMode)mode;
- (void) setStyleTextMode:(GraphicsStyle::ShapeMode)mode;
- (void) setStyleLineCapMode:(GraphicsStyle::LineCapMode)mode;
- (void) setStyleSmooth:(BOOL)smooth;
- (void) setStyleBlendMode:(GraphicsStyle::BlendMode)mode;
- (void) setStyleBlendModeSource:(GraphicsStyle::AdvancedBlendMode)source
                            dest:(GraphicsStyle::AdvancedBlendMode)dest;
- (void) setStyleBlendModeSource:(GraphicsStyle::AdvancedBlendMode)source
                            dest:(GraphicsStyle::AdvancedBlendMode)dest
                     alphaSource:(GraphicsStyle::AdvancedBlendMode)alphaSrc
                       alphaDest:(GraphicsStyle::AdvancedBlendMode)alphaDest;
- (void) setStyleBlendEquation:(GraphicsStyle::BlendEquation)eq;
- (void) setStyleBlendEquation:(GraphicsStyle::BlendEquation)eq alphaEquation:(GraphicsStyle::BlendEquation)alphaEq;


- (void) pushStyle;
- (void) popStyle;
- (void) resetStyle;

#pragma mark - Blending
- (void) setBlendModeType:(RenderManagerBlendingMode)blendMode;
- (void) applyCurrentBlendMode;

#pragma mark - Active texture
- (void) setActiveTexture:(GLenum)activeTexture;

@end
