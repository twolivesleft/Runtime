#version 300 es
#extension GL_EXT_separate_shader_objects: enable

precision highp float;
precision highp int;

#include <constants>

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;
uniform mat4 inverseViewMatrix;
uniform mat4 inverseModelMatrix;
uniform vec3 cameraPosition;

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 uv;

#ifdef USE_UV2
layout(location = 5) in vec2 uv2;
#endif

#ifdef USE_COLOR
layout(location = 3) in vec4 color;
#endif

#define USE_TANGENTS

#ifdef USE_TANGENTS
layout(location = 4) in vec4 tangent;
#endif

#ifdef USE_SKINNING

layout(location = 6) in vec4 skinIndex;
layout(location = 7) in vec4 skinWeight;

#endif

#ifdef USE_MORPHTARGETS
#ifndef USE_MORPHNORMALS

uniform float morphTargetInfluences[ 8 ];

#else

uniform float morphTargetInfluences[ 4 ];

#endif
#endif

#ifdef USE_SKINNING

uniform mat4 bindMatrix;
uniform mat4 bindMatrixInverse;

#ifdef BONE_TEXTURE

uniform sampler2D boneTexture;
uniform int boneTextureWidth;
uniform int boneTextureHeight;

mat4 getBoneMatrix( const in float i )
{
	float j = i * 4.0;
	float x = mod( j, float( boneTextureWidth ) );
	float y = floor( j / float( boneTextureWidth ) );

	float dx = 1.0 / float( boneTextureWidth );
	float dy = 1.0 / float( boneTextureHeight );

	y = dy * ( y + 0.5 );

	vec4 v1 = texture( boneTexture, vec2( dx * ( x + 0.5 ), y ) );
	vec4 v2 = texture( boneTexture, vec2( dx * ( x + 1.5 ), y ) );
	vec4 v3 = texture( boneTexture, vec2( dx * ( x + 2.5 ), y ) );
	vec4 v4 = texture( boneTexture, vec2( dx * ( x + 3.5 ), y ) );

	mat4 bone = mat4( v1, v2, v3, v4 );

	return bone;
}

#else

uniform mat4 boneMatrices[ MAX_BONES ];

mat4 getBoneMatrix( const in float i )
{
	mat4 bone = boneMatrices[ int(i) ];
	return bone;
}

#endif

#endif

#ifdef USE_LOGDEPTHBUF
	out float vFragDepth;
	uniform float logDepthBufFC;
#endif

vec3 objectSpaceViewDir (vec3 v)
{
    vec3 objSpaceCameraPos = (inverseModelMatrix * vec4(cameraPosition.xyz, 1.0)).xyz;
    return objSpaceCameraPos - v.xyz;
}

#include <conversion_vert>

#include <vertex_struct>
#include <input_struct>

out Input inputData;

// The vertex processing function for this surface shader
void vertex(inout Vertex v, out Input o) {}

void main()
{
	Vertex v;
	v.position = position;
	v.normal = normal;
#ifdef USE_TANGENTS
	v.tangent = tangent;
#endif	
	v.uv = uv;
#ifdef USE_UV2
	v.uv2 = uv2;
#endif
#ifdef USE_COLOR
	v.color = color;
#endif

	// Apply user-defined vertex modifications
	vertex(v, inputData);

	inputData.uv = v.uv;
#ifdef USE_UV2
	inputData.uv2 = v.uv2;
#endif

#ifdef USE_COLOR
	inputData.color = v.color;
#endif

vec3 objectNormal = vec3( v.normal );

#ifdef USE_MORPHNORMALS
	objectNormal += ( morphNormal0 - normal ) * morphTargetInfluences[ 0 ];
	objectNormal += ( morphNormal1 - normal ) * morphTargetInfluences[ 1 ];
	objectNormal += ( morphNormal2 - normal ) * morphTargetInfluences[ 2 ];
	objectNormal += ( morphNormal3 - normal ) * morphTargetInfluences[ 3 ];
#endif

#ifdef USE_SKINNING
	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );
#endif

#ifdef USE_SKINNING
	mat4 skinMatrix = mat4( 0.0 );
	skinMatrix += skinWeight.x * boneMatX;
	skinMatrix += skinWeight.y * boneMatY;
	skinMatrix += skinWeight.z * boneMatZ;
	skinMatrix += skinWeight.w * boneMatW;
	skinMatrix  = bindMatrixInverse * skinMatrix * bindMatrix;

	objectNormal = vec4( skinMatrix * vec4( objectNormal, 0.0 ) ).xyz;
#endif

#ifdef FLIP_SIDED
	objectNormal = -objectNormal;
#endif

	vec3 transformedNormal = normalMatrix * objectNormal;

	inputData.worldNormal = normalize( modelMatrix * vec4(objectNormal, 0.0) ).xyz;
	inputData.normal = normalize( transformedNormal );
#ifdef USE_TANGENTS
	inputData.tangent = normalize( normalMatrix * v.tangent.xyz );
	inputData.bitangent = cross(inputData.normal, inputData.tangent) * v.tangent.w;
#endif

    vec3 transformed = vec3( v.position );

#ifdef USE_MORPHTARGETS

	transformed += ( morphTarget0 - position ) * morphTargetInfluences[ 0 ];
	transformed += ( morphTarget1 - position ) * morphTargetInfluences[ 1 ];
	transformed += ( morphTarget2 - position ) * morphTargetInfluences[ 2 ];
	transformed += ( morphTarget3 - position ) * morphTargetInfluences[ 3 ];

	#ifndef USE_MORPHNORMALS

	transformed += ( morphTarget4 - position ) * morphTargetInfluences[ 4 ];
	transformed += ( morphTarget5 - position ) * morphTargetInfluences[ 5 ];
	transformed += ( morphTarget6 - position ) * morphTargetInfluences[ 6 ];
	transformed += ( morphTarget7 - position ) * morphTargetInfluences[ 7 ];

	#endif

#endif

#ifdef USE_SKINNING
	vec4 skinVertex = bindMatrix * vec4( transformed, 1.0 );

	vec4 skinned = vec4( 0.0 );
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;
	skinned  = bindMatrixInverse * skinned;
#endif

#ifdef USE_SKINNING
	vec4 mvPosition = modelViewMatrix * skinned;
#else
	vec4 mvPosition = modelViewMatrix * vec4( transformed, 1.0 );
#endif

	gl_Position = projectionMatrix * mvPosition;

#ifdef USE_LOGDEPTHBUF
	gl_Position.z = log2(max(0.01, 1.0 + gl_Position.w)) * logDepthBufFC - 1.0;
	vFragDepth = 1.0 + gl_Position.w;
#endif

	inputData.viewPosition = -mvPosition.xyz;

	#ifdef USE_SKINNING
		vec4 worldPosition = modelMatrix * skinned;
	#else
		vec4 worldPosition = modelMatrix * vec4( transformed, 1.0 );
	#endif

	inputData.worldPosition = worldPosition.xyz;

	#ifdef USE_TANGENT_VIEW_DIR
		vec3 T = normalize( modelMatrix * vec4(tangent.xyz, 0.0) ).xyz;
		vec3 N = normalize( modelMatrix * vec4(normal, 0.0) ).xyz;
		vec3 B = cross(N, T) * tangent.w;
		mat3 worldToTangent = mat3(T, B, N);
		inputData.tangentViewDir = normalize(cameraPosition - inputData.worldPosition) * worldToTangent;
	#endif

}
