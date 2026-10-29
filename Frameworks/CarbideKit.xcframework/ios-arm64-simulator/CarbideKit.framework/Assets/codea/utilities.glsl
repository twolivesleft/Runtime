//#define PI 3.141592653589793
//#define PI2 6.283185307179586
//#define PI_HALF 1.5707963267948966
#define RECIPROCAL_PI 0.3183098861837907
#define RECIPROCAL_PI2 0.15915494309189535
//#define EPSILON 1e-6

//vec4 posterize(vec4 _rgba, float _numColors)
//{
//    return vec4(posterize(_rgba.xyz, _numColors), _rgba.w);
//}

//vec3 sepia(vec3 _rgb)
//{
//    vec3 color;
//    color.x = dot(_rgb, vec3(0.393, 0.769, 0.189) );
//    color.y = dot(_rgb, vec3(0.349, 0.686, 0.168) );
//    color.z = dot(_rgb, vec3(0.272, 0.534, 0.131) );
//    return color;
//}

//vec3 adjustHue(vec3 _rgb, float _hue)
//{
//    vec3 yiq = convertRGB2YIQ(_rgb);
//    float angle = _hue + atan2(yiq.z, yiq.y);
//    float len = length(yiq.yz);
//    return convertYIQ2RGB(vec3(yiq.x, len*cos(angle), len*sin(angle) ) );
//}

vec3 encodeNormal(vec3 _normal)
{
    return _normal * 0.5 + 0.5;
}

vec3 decodeNormal(vec3 _encodedNormal)
{
    return _encodedNormal * 2.0 - 1.0;
}

vec3 sampleNormal(sampler2D _sampler, vec2 _uv)
{
    return decodeNormal(texture(_sampler, _uv).rgb);
}

vec2 equirectUv( in vec3 dir )
{
    // dir is assumed to be unit length
    float u = atan( dir.z, dir.x ) * RECIPROCAL_PI2 + 0.5;
    float v = asin( clamp( dir.y, - 1.0, 1.0 ) ) * RECIPROCAL_PI + 0.5;
    return vec2( u, v );
}

vec3 sphericalToCartesian(in vec3 p)
{
    return vec3(p.x * cos(p.z) * sin(p.y),
                p.x * sin(p.z) * sin(p.y),
                p.x * cos(p.y));
}
