#version 430
#include <codea/common.glsl>

in vec2 uv;
out vec4 FragColor;

uniform sampler2D source;
// The distance between the samples
uniform vec4 blurStep;

// A gaussian blur along one direction
void main()
{
    vec3 sum = vec3(0.0);
    float total = 0.0;
    for (int i = -6; i <= 6; i++)
    {
        float weight = exp(-float(i * i) / 16.0);
        sum += texture(source, uv + blurStep.xy * float(i)).rgb * weight;
        total += weight;
    }
    FragColor = vec4(sum / total, 1.0);
}
