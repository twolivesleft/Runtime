vec3 toLinear(vec3 _rgb)
{
    return pow(abs(_rgb), vec3(2.2) );
}

vec4 toLinear(vec4 _rgba)
{
    return vec4(toLinear(_rgba.xyz), _rgba.w);
}

vec3 toLinearAccurate(vec3 _rgb)
{
    vec3 lo = _rgb / 12.92;
    vec3 hi = pow( (_rgb + 0.055) / 1.055, vec3(2.4) );
    vec3 rgb = mix(hi, lo, vec3(lessThanEqual(_rgb, vec3(0.04045) ) ) );
    return rgb;
}

vec4 toLinearAccurate(vec4 _rgba)
{
    return vec4(toLinearAccurate(_rgba.xyz), _rgba.w);
}

float toGamma(float _r)
{
    return pow(abs(_r), 1.0/2.2);
}

vec3 toGamma(vec3 _rgb)
{
    return pow(abs(_rgb), vec3(1.0/2.2) );
}

vec4 toGamma(vec4 _rgba)
{
    return vec4(toGamma(_rgba.xyz), _rgba.w);
}

vec3 toGammaAccurate(vec3 _rgb)
{
    vec3 lo  = _rgb * 12.92;
    vec3 hi  = pow(abs(_rgb), vec3(1.0/2.4) ) * 1.055 - 0.055;
    vec3 rgb = mix(hi, lo, vec3(lessThanEqual(_rgb, vec3(0.0031308) ) ) );
    return rgb;
}

vec4 toGammaAccurate(vec4 _rgba)
{
    return vec4(toGammaAccurate(_rgba.xyz), _rgba.w);
}

vec3 toReinhard(vec3 _rgb)
{
    return toGamma(_rgb/(_rgb+vec3(1.0) ) );
}

vec4 toReinhard(vec4 _rgba)
{
    return vec4(toReinhard(_rgba.xyz), _rgba.w);
}

vec3 toFilmic(vec3 _rgb)
{
    _rgb = max(vec3(0.0), _rgb - 0.004);
    _rgb = (_rgb*(6.2*_rgb + 0.5) ) / (_rgb*(6.2*_rgb + 1.7) + 0.06);
    return _rgb;
}

vec4 toFilmic(vec4 _rgba)
{
    return vec4(toFilmic(_rgba.xyz), _rgba.w);
}

vec3 toAcesFilmic(vec3 _rgb)
{
    // Reference(s):
    // - ACES Filmic Tone Mapping Curve
    //   https://web.archive.org/web/20191027010704/https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
    float aa = 2.51f;
    float bb = 0.03f;
    float cc = 2.43f;
    float dd = 0.59f;
    float ee = 0.14f;
    return saturate( (_rgb*(aa*_rgb + bb) )/(_rgb*(cc*_rgb + dd) + ee) );
}

vec4 toAcesFilmic(vec4 _rgba)
{
    return vec4(toAcesFilmic(_rgba.xyz), _rgba.w);
}

vec3 luma(vec3 _rgb)
{
    float yy = dot(vec3(0.2126729, 0.7151522, 0.0721750), _rgb);
    return vec3(yy);
}

vec4 luma(vec4 _rgba)
{
    return vec4(luma(_rgba.xyz), _rgba.w);
}
