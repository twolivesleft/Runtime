#extension GL_OES_standard_derivatives : enable
#extension GL_EXT_shader_texture_lod: enable

precision highp float;

varying highp vec2 uvOffset;
varying highp vec2 uvCoord;
varying lowp vec3 diffuse;
varying lowp vec4 baseColor;
varying lowp float aoFactor;

#ifdef USE_MAP
uniform sampler2D map;
#endif

#ifdef USE_OUTLINE
uniform mediump float outlineWidth;
uniform lowp vec3 outlineColor;
#endif

uniform vec3 ambientLightColor;

#ifdef USE_FOG

varying highp vec3 viewPosition;

uniform vec3 fogColor;

#ifdef FOG_EXP2

uniform float fogDensity;

#else

uniform float fogNear;
uniform float fogFar;
#endif

#endif

float mipmapLevel(vec2 uv, vec2 textureSize)
{
    vec2 dx = dFdx(uv * textureSize.x);
    vec2 dy = dFdy(uv * textureSize.y);
    float d = max(dot(dx, dx), dot(dy, dy));
    return 0.5 * log2(d);
}

/// This function samples a texture with tiling and mipmapping from within a texture pack of the given
/// attributes
/// - tex is the texture pack from which to sample a tile
/// - uv are the texture coordinates of the pixel *inside the tile*
/// - tile are the coordinates of the tile within the pack (ex.: 2, 1)
/// - packTexFactors are some constants to perform the mipmapping and tiling
/// Texture pack factors:
/// - inverse of the number of horizontal tiles (ex.: 4 tiles -> 0.25)
/// - inverse of the number of vertical tiles (ex.: 2 tiles -> 0.5)
/// - size of a tile in pixels (ex.: 1024)
/// - amount of bits representing the power-of-2 of the size of a tile (ex.: a 1024 tile is 10 bits).
vec4 sampleTexturePackMipWrapped(const in sampler2D tex, in vec2 uv, const in vec2 tile,
                                 const in vec4 packTexFactors)
{
    /// estimate mipmap/LOD level
    float lod = mipmapLevel(uv, vec2(packTexFactors.z));
    lod = clamp(lod, 0.0, packTexFactors.w);
    
    /// get width/height of the whole pack texture for the current lod level
    float size = pow(2.0, packTexFactors.w - lod);
    float sizex = size / packTexFactors.x; // width in pixels
    float sizey = size / packTexFactors.y; // height in pixels
    
    uv = fract(uv);
    
    /// tweak pixels for correct bilinear filtering, and add offset for the wanted tile
    uv.x = uv.x * ((sizex * packTexFactors.x - 1.0) / sizex) + 0.5 / sizex + packTexFactors.x * tile.x;
    uv.y = uv.y * ((sizey * packTexFactors.y - 1.0) / sizey) + 0.5 / sizey + packTexFactors.y * tile.y;
    
    return texture2DLodEXT(tex, vec2(uv.x, 1.0 - uv.y), lod);
}

#ifdef GAMMA_CORRECTION
const float gamma = 2.2;

vec4 mapTexelToLinear( vec4 value )
{
    return vec4(pow(value.rgb, vec3(gamma)), value.a);
}

vec4 envMapTexelToLinear( vec4 value )
{
    return value;
}

#else

vec4 mapTexelToLinear( vec4 value )
{
    return value;
}

vec4 envMapTexelToLinear( vec4 value )
{
    return value;
}
#endif

void main()
{
    
#ifdef USE_MAP
    vec4 packTexFactors = vec4(1.0 / 16.0, 1.0 / 16.0, 128.0, 7.0);
    lowp vec4 albedo = sampleTexturePackMipWrapped(map, uvCoord, uvOffset, packTexFactors);
#else
    lowp vec4 albedo = vec4(1.0, 1.0, 1.0, 1.0);
#endif
        
    lowp vec3 color = baseColor.rgb * albedo.rgb;

#ifdef USE_OUTLINE
    mediump vec2 xyInset = vec2( uvCoord.x * 128.0, uvCoord.y * 128.0 );
    mediump float closestDist = min( min( xyInset.x, 128.0 - xyInset.x ), min( xyInset.y, 128.0 - xyInset.y ) );
    
    color = mix( outlineColor, color, smoothstep( outlineWidth-2.5, outlineWidth, closestDist ) );
#endif
    
    color = mapTexelToLinear(vec4(color, 0.0)).rgb;
    
    gl_FragColor = vec4(aoFactor * (ambientLightColor * color + diffuse * color), baseColor.a * albedo.a);

#ifdef GAMMA_CORRECTION
    gl_FragColor.rgb = pow(gl_FragColor.rgb, vec3(1.0/gamma));
#endif
    
#ifdef USE_FOG
    float depth = length(viewPosition);
    
#ifdef FOG_EXP2
    float fogFactor = whiteCompliment( exp2( - fogDensity * fogDensity * depth * depth * LOG2 ) );
#else
    float fogFactor = smoothstep( fogNear, fogFar, depth );
#endif
    
    gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
#endif
    
}
