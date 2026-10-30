#version 430
#include <codea/common.glsl>

in vec2 uv;
out vec4 FragColor;

uniform sampler2D source;
// One source pixel (xy) and the threshold (z)
uniform vec4 settings;

// Keeps only what's brighter than the threshold, averaging four pixels as it shrinks
void main()
{
    vec2 o = settings.xy;
    vec3 c = texture(source, uv + vec2(-o.x, -o.y)).rgb + texture(source, uv + vec2(o.x, -o.y)).rgb +
             texture(source, uv + vec2(-o.x, o.y)).rgb + texture(source, uv + vec2(o.x, o.y)).rgb;
    c *= 0.25;
    float brightest = max(c.r, max(c.g, c.b));
    float keep = smoothstep(settings.z, settings.z + 0.35, brightest);
    FragColor = vec4(c * keep, 1.0);
}
