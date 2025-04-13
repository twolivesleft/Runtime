#define saturate(a) clamp( a, 0.0, 1.0 )
#define whiteCompliment(a) ( 1.0 - saturate( a ) )

float pow2( const in float x ) { return x*x; }
float pow3( const in float x ) { return x*x*x; }
float pow4( const in float x ) { float x2 = x*x; return x2*x2; }
float average( const in vec3 color ) { return dot( color, vec3( 0.3333 ) ); }

vec3 transformDirection( in vec3 dir, in mat4 matrix )
{
	return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );
}

// http://en.wikibooks.org/wiki/GLSL_Programming/Applying_Matrix_Transformations
vec3 inverseTransformDirection( in vec3 dir, in mat4 matrix )
{
	return normalize( ( vec4( dir, 0.0 ) * matrix ).xyz );
}

vec3 projectOnPlane(in vec3 point, in vec3 pointOnPlane, in vec3 planeNormal )
{
	float distance = dot( planeNormal, point - pointOnPlane );

	return - distance * planeNormal + point;
}

float sideOfPlane( in vec3 point, in vec3 pointOnPlane, in vec3 planeNormal )
{
	return sign( dot( point - pointOnPlane, planeNormal ) );
}

vec3 linePlaneIntersect( in vec3 pointOnLine, in vec3 lineDirection, in vec3 pointOnPlane, in vec3 planeNormal )
{
	return lineDirection * ( dot( planeNormal, pointOnPlane - pointOnLine ) / dot( planeNormal, lineDirection ) ) + pointOnLine;
}
vec3 packNormalToRGB( const in vec3 normal )
{
	return normalize( normal ) * 0.5 + 0.5;
}

vec3 unpackRGBToNormal( const in vec3 rgb )
{
	return 1.0 - 2.0 * rgb.xyz;
}

const float PackUpscale = 256. / 255.; // fraction -> 0..1 (including 1)
const float UnpackDownscale = 255. / 256.; // 0..1 -> fraction (excluding 1)

const vec3 PackFactors = vec3( 256. * 256. * 256., 256. * 256.,  256. );
const vec4 UnpackFactors = UnpackDownscale / vec4( PackFactors, 1. );

const float ShiftRight8 = 1. / 256.;

vec4 packDepthToRGBA( const in float v )
{
	vec4 r = vec4( fract( v * PackFactors ), v );
	r.yzw -= r.xyz * ShiftRight8; // tidy overflow
	return r * PackUpscale;
}

float unpackRGBAToDepth( const in vec4 v )
{
	return dot( v, UnpackFactors );
}

// NOTE: viewZ/eyeZ is < 0 when in front of the camera per OpenGL conventions

float viewZToOrthographicDepth( const in float viewZ, const in float near, const in float far )
{
	return ( viewZ + near ) / ( near - far );
}

float orthographicDepthToViewZ( const in float linearClipZ, const in float near, const in float far )
{
	return linearClipZ * ( near - far ) - near;
}

float viewZToPerspectiveDepth( const in float viewZ, const in float near, const in float far )
{
	return (( near + viewZ ) * far ) / (( far - near ) * viewZ );
}

float perspectiveDepthToViewZ( const in float invClipZ, const in float near, const in float far )
{
	return ( near * far ) / ( ( far - near ) * invClipZ - far );
}

#ifdef GAMMA_CORRECTION
const float gamma = 2.2;

vec4 mapTexelToLinear( vec4 value )
{
    return vec4(pow(value.rgb, vec3(gamma)), value.a);
}

vec4 envMapTexelToLinear( vec4 value )
{
    return value; //vec4(pow(value.rgb, vec3(gamma)), value.a);
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
