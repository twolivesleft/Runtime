#version 300 es
#extension GL_OES_standard_derivatives : enable
#extension GL_EXT_shader_texture_lod: enable

precision highp float;
precision highp int;

#define TEXTURE_LOD_EXT
#define USE_TANGENTS

uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;
uniform mat4 inverseModelMatrix;
uniform mat4 inverseViewMatrix;
uniform vec3 cameraPosition;

#include <constants>
#include <utilities>

#include <input_struct>
in Input inputData;

#ifdef USE_ENVMAP
	#ifdef ENVMAP_TYPE_CUBE
		uniform highp samplerCube envMap;
	#else
		uniform highp sampler2D envMap;
	#endif

	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( PHYSICAL )
		uniform float refractionRatio;
	#else
		in vec3 vReflect;
	#endif
#endif

#ifdef USE_LOGDEPTHBUF
    in float vFragDepth;
	uniform float logDepthBufFC;
#endif

#include <fog>

#if defined(USE_LIGHTING) && !defined(USE_CUSTOM_LIGHTING)
#include <lighting_structs>
#include <brdfs>
#include <standard_lighting>
#elif defined(USE_LIGHTING) && defined(USE_CUSTOM_LIGHTING) // USE_CUSTOM_LIGHTING
#include <unlit>
#include <custom_lighting>
#else
#include <unlit>
#endif

#include <conversion_frag>

vec3 perturbNormal2Arb( vec3 eye_pos, vec3 surf_norm, vec3 mapN )
{
#ifdef USE_TANGENTS
	return normalize(mapN.x * inputData.tangent + mapN.y * inputData.bitangent + mapN.z * inputData.normal);
#else
	// Per-Pixel Tangent Space Normal Mapping
	// http://hacksoflife.blogspot.ch/2009/11/per-pixel-tangent-space-normal-mapping.html

	vec3 q0 = dFdx( eye_pos.xyz );
	vec3 q1 = dFdy( eye_pos.xyz );
	vec2 st0 = dFdx( inputData.uv.st );
	vec2 st1 = dFdy( inputData.uv.st );

	vec3 S = normalize( q0 * st1.t - q1 * st0.t );
	vec3 T = normalize( -q0 * st1.s + q1 * st0.s );
	vec3 N = normalize( surf_norm );

	mat3 tsn = mat3( S, T, N );
	return normalize( tsn * mapN );
#endif
}

// The fragment processing function for this surface shader
void surface(in Input IN, inout SurfaceOutput o) {}

#if defined(USE_CUSTOM_LIGHTING)
// Custom shading model processing function for this surface shader (OPTIONAL)
/***CUSTOM_LIGHT_ENTRY_POINT***/
#endif

#ifdef SELECTION_MODE
uniform float objectID;
layout(location = 0) out vec4 fragmentColor;
layout(location = 1) out vec4 fragmentID;
#else
out vec4 fragmentColor;
#endif

void main()
{
#ifdef SELECTION_MODE
	fragmentID = vec4(objectID);
#endif

#ifdef DOUBLE_SIDED
	float flipNormal = -( float( gl_FrontFacing ) * 2.0 - 1.0 );
#else
	float flipNormal = 1.0;
#endif

#ifdef FLAT_SHADED
	vec3 fdx = dFdx( inputData.viewPosition );
	vec3 fdy = dFdy( inputData.viewPosition );
	vec3 normal = normalize( cross( fdx, fdy ) );
#else
	vec3 normal = normalize( inputData.normal ) * flipNormal;
#endif

#ifdef USE_LOGDEPTHBUF
	gl_FragDepth = log2(vFragDepth) * (0.5 * logDepthBufFC);
#endif

	SurfaceOutput o;

#if defined(USE_LIGHTING) && !defined(USE_CUSTOM_LIGHTING)
	// Set default values for surface o
	o.diffuse = vec3(1.0, 1.0, 1.0);
	o.normal = normal;
	o.emissive = 0.0;
	o.emission = vec3(0.0);
	o.roughness = 0.0;
	o.metalness = 0.0;
	o.opacity = 1.0;
	o.occlusion = 1.0;
	#ifdef ANISOTROPIC_SHADING
	o.anisotropy = 0.0;
	#endif
#else
	o.diffuse = vec3(1.0, 1.0, 1.0);
	o.emissive = 0.0;
	o.emission = vec3(0.0);
	o.opacity = 1.0;
#endif

#ifdef ALPHATEST
	if ( o.opacity < ALPHATEST ) discard;
#endif

	surface(inputData, o);

#ifdef PREMULTIPLIED_ALPHA
    o.diffuse.rgb *= o.opacity;
#endif

// #ifdef USE_COLOR
// 	diffuseColor.rgb *= inputData.color;
// #endif

#if defined(USE_LIGHTING) && !defined(USE_CUSTOM_LIGHTING)
	fragmentColor = vec4(standardLighting(inputData, o), o.opacity);
#elif defined(USE_LIGHTING) && defined(USE_CUSTOM_LIGHTING) // USE_CUSTOM_LIGHTING
	fragmentColor = vec4(customLighting(inputData, o) + o.emissive * o.emission, o.opacity);
#else // UNLIT
	fragmentColor = vec4(o.diffuse.rgb + o.emissive * o.emission, o.opacity);
#endif

#if defined( BEHIND )
	#if defined(PREMULTIPLIED_ALPHA)
		fragmentColor = vec4( fragmentColor.rgb + o.behind * (1.0 - fragmentColor.a), 1.0 );
	#else
    	fragmentColor = vec4( mix(o.behind, fragmentColor.rgb, fragmentColor.a), 1.0 );
	#endif
#endif

#if defined( TONE_MAPPING )
  	fragmentColor.rgb = toneMapping( fragmentColor.rgb );
#endif

	// Clamp negative colors (but not positive, in case of HDR values)
	fragmentColor.rgb = max(fragmentColor.rgb, 0.0);

#ifdef USE_FOG
	applyFog(fragmentColor);
#endif
}
