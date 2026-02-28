precision mediump float;

varying highp vec2 texCoordVarying;

uniform float lumaThreshold;
uniform float chromaThreshold;
uniform sampler2D SamplerY;
uniform sampler2D SamplerUV;
uniform mat3 colorConversionMatrix;

void main()
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    // Subtract constants to map the video range start at 0
    yuv.x = (texture2D(SamplerY, texCoordVarying).r - (16.0/255.0)) * lumaThreshold;

//#if (__VERSION__ > 100) // OpenGL ES 3.0
    yuv.yz = (texture2D(SamplerUV, texCoordVarying).ra - vec2(0.5, 0.5)) * chromaThreshold;
//#else // OpenGL ES 3.0
    //yuv.yz = (texture2D(SamplerUV, texCoordVarying).rg - vec2(0.5, 0.5)) * chromaThreshold;
//#endif
    
    rgb = colorConversionMatrix * yuv;

    gl_FragColor = vec4(rgb,1);
}