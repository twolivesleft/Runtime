precision highp float;

varying highp vec3 eyeDirection;

uniform highp sampler2D equirectMap;

const vec2 invAtan = vec2(0.1591, 0.3183);

vec2 sampleSphericalMap(vec3 v)
{
    vec2 uv = vec2(atan(v.z, v.x), asin(v.y));
    uv *= invAtan;
    uv += 0.5;
    return uv;
}

void main()
{
    vec3 rayDir = normalize(eyeDirection * vec3(1.0, -1.0, -1.0));

    highp vec3 col = texture2D(equirectMap, sampleSphericalMap(rayDir)).rgb;
    gl_FragColor = vec4(col, 1.0);
}
