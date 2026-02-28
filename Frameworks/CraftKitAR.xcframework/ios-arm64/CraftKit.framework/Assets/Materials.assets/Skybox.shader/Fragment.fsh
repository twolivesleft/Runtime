#extension GL_EXT_shader_texture_lod: enable

precision mediump float;

varying highp vec3 eyeDirection;

uniform lowp vec3 sky;
uniform lowp vec3 horizon;
uniform lowp vec3 ground;

#if defined(USE_ENVMAP)
uniform highp samplerCube envMap;
uniform float bias;
#elif defined(USE_ENVMAP_HDR)
uniform highp sampler2D envMapHDR;

const vec2 invAtan = vec2(0.1591, 0.3183);
vec2 sampleSphericalMap(vec3 v)
{
    vec2 uv = vec2(atan(v.z, v.x), asin(v.y));
    uv *= invAtan;
    uv += 0.5;
    return uv;
}

#endif

#define M_PI 3.1415926535897932384626433832795

void main()
{
    vec3 rayDir = normalize(eyeDirection);

#if defined(USE_ENVMAP)
    rayDir.y *= -1.0;
    lowp vec3 col = textureCubeLod(envMap, rayDir, bias).rgb;
#elif defined(USE_ENVMAP_HDR)
    highp vec3 col = texture2D(envMapHDR, sampleSphericalMap(rayDir)).rgb;
#else
    // Dynamic skybox
    float t1 = max(-rayDir.y, 0.0);
    float t2 = max(rayDir.y, 0.0);

    lowp vec3 col = mix(mix(horizon, sky, t1), ground, t2);
#endif

    gl_FragColor = vec4(col, 1.0);
}
