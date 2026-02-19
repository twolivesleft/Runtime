#extension GL_EXT_separate_shader_objects: enable

precision highp float;

layout(location = 0) attribute vec4 position;
layout(location = 1) attribute vec4 offset;
layout(location = 2) attribute vec4 color;
layout(location = 3) attribute vec4 texOffsetCoord;

varying mediump vec2 uvOffset;
varying mediump vec2 uvCoord;
varying lowp vec3 diffuse;
varying lowp vec4 baseColor;
varying lowp float aoFactor;

#ifdef USE_FOG
varying highp vec3 viewPosition;
#endif

uniform highp mat4 mvpMatrix;
uniform highp mat4 modelViewMatrix;
uniform highp mat4 modelMatrix;
uniform highp mat4 viewMatrix;
uniform highp mat4 projectionMatrix;
uniform highp mat3 normalMatrix;
uniform highp vec3 cameraPos;

// Texture Uniforms
uniform lowp vec3 normalLookup[6];

//const lowp vec3 normalLookup[6] (vec3(1.0, 0.0, 0.0),
//                                 vec3(0.0, 0.0, 1.0),
//                                 vec3(-1.0, 0.0, 0.0),
//                                 vec3(0.0, 0.0, -1.0),
//                                 vec3(0.0, 1.0, 0.0),
//                                 vec3(0.0, -1.0, 0.0));

#if NUM_DIR_LIGHTS > 0

struct DirectionalLight
{
    vec3 direction;
    vec3 color;
    
    int shadow;
    float shadowBias;
    float shadowRadius;
    vec2 shadowMapSize;
};

uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];

#endif


void main()
{
    baseColor = color;
    uvOffset = texOffsetCoord.xy;
    uvCoord = texOffsetCoord.zw / 128.0; // TODO: Pass in tile size as uniform!
    
    int normalIndex = int(position.w)   ; // int(floor(position.w / 16.0)); // Unpack normal index
    aoFactor = 0.25 + offset.w / 3.0 * 0.75; //(fract(position.w / 16.0) * 16.0 / 15.0) * 0.75; // Unpack Ambient Occlusion
    
    highp vec3 pos = (modelMatrix * vec4((position.xyz / vec3(255,255,255)) + offset.xyz, 1.0)).xyz;
    gl_Position =  (projectionMatrix * viewMatrix) * vec4(pos, 1.0);
    
#ifdef USE_FOG
    viewPosition = -(viewMatrix * vec4(pos.xyz, 1.0)).xyz;
#endif
    
    
#if ( NUM_DIR_LIGHTS > 0 )
    lowp vec3 normal = normalize(normalMatrix * normalLookup[normalIndex]);
    float diffuseCoefficient = max(dot(normal, directionalLights[0].direction), 0.0);
    diffuse = vec3(diffuseCoefficient * directionalLights[0].color);
#else
    diffuse = vec3(1.0, 1.0, 1.0);
#endif
}
