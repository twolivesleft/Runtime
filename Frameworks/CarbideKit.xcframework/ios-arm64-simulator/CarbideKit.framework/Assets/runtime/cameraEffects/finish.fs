#version 430
#include <codea/common.glsl>

in vec2 uv;
out vec4 FragColor;

uniform sampler2D source;
uniform sampler2D glow;
uniform sampler2D haze;
// As in tiltShift.fs, the second pass of the blur
uniform vec4 blurStep;
uniform vec4 band;
// Bloom strength (x)
uniform vec4 bloom;
// Saturation (x), vignette (y) and grain (z)
uniform vec4 grade;

// Finishes the tilt shift blur, adds the bloom and grades the picture
void main()
{
    float radius = smoothstep(band.y, band.y + band.z, abs(uv.y - band.x)) * band.w;
    vec4 c = texture(source, uv);
    if (radius > 0.0)
    {
        vec4 sum = vec4(0.0);
        float total = 0.0;
        for (int i = -7; i <= 7; i++)
        {
            float weight = exp(-float(i * i) / 24.0);
            sum += texture(source, uv + blurStep.xy * float(i) * radius / 7.0) * weight;
            total += weight;
        }
        c = sum / total;
    }

    if (bloom.x > 0.0)
    {
        c.rgb += (texture(glow, uv).rgb * 0.8 + texture(haze, uv).rgb * 0.6) * bloom.x;
    }

    float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    c.rgb = mix(vec3(luma), c.rgb, grade.x);

    // Dark corners, and grain that also stops dark gradients banding
    vec2 d = uv - 0.5;
    c.rgb *= max(0.0, 1.0 - dot(d, d) * grade.y);
    float noise = fract(sin(dot(uv * 1000.0 + fract(u_time.x * 0.1) * 100.0, vec2(12.9898, 78.233))) * 43758.5453);
    c.rgb += (noise - 0.5) * grade.z * 0.05;

    FragColor = c;
}
