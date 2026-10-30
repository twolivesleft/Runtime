#version 430
#include <codea/common.glsl>

in vec2 uv;
out vec4 FragColor;

uniform sampler2D source;
// One pixel in the direction being blurred (xy)
uniform vec4 blurStep;
// The middle of the sharp band (x), how far it reaches (y), its falloff (z) and the most blur in pixels (w)
uniform vec4 band;

// The tilt shift blur along one direction, more blurred further from the band
void main()
{
    float radius = smoothstep(band.y, band.y + band.z, abs(uv.y - band.x)) * band.w;
    if (radius <= 0.0)
    {
        FragColor = texture(source, uv);
        return;
    }
    vec4 sum = vec4(0.0);
    float total = 0.0;
    for (int i = -7; i <= 7; i++)
    {
        float weight = exp(-float(i * i) / 24.0);
        sum += texture(source, uv + blurStep.xy * float(i) * radius / 7.0) * weight;
        total += weight;
    }
    FragColor = sum / total;
}
