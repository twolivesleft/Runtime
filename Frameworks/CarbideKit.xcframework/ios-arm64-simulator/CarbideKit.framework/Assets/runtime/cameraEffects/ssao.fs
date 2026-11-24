#version 430
#include <codea/common.glsl>

// Adapted from Godot drivers/gles3/shaders/s4ao_inc.glsl, revision
// 4d0d43b77dd2ffbd7dc867c08bcc3dd9962fd7e7.
// S4AO (Stupid Simple Screen Space Ambient Occlusion), Jonathan Dummer (O1S).
// Godot copyright and MIT terms are in S4AO-LICENSE.txt alongside this file.
// Carbide uses forward depth [0,1]; invert it for S4AO's reverse-depth inputs.
in vec2 uv;
out vec4 FragColor;
uniform sampler2D sceneDepth;
uniform vec4 settings; // intensity, radius fraction, pixel width, pixel height

void main()
{
    float depth = 1.0 - textureLod(sceneDepth, uv, 0.0).r;
    if (depth <= 1e-6) { FragColor = vec4(1.0); return; }
    const int sampleWidth = 4;
    const float midpoint = 1.50003;
    float radius = max(1e-4, depth * settings.y);
    float inverseFalloff = 1.0 / max(1e-4, depth * 0.25);
    vec2 noiseUV = settings.zw * 1.087 * vec2((1.0 + sqrt(5.0)) * 0.5, (9.0 + sqrt(221.0)) * 0.1);
    vec2 rcos = (1.7 / midpoint * radius) * vec2(0.5, fract(dot(uv, noiseUV)) - 0.5);
    vec2 rsin = rcos.yx * vec2(-1.0, 1.0);
    vec2 base = -midpoint * rsin;
    float occlusion = 0.0;
    for (int j = sampleWidth - 1; j >= 0; --j)
    {
        int notch = int(j == 0 || j == sampleWidth - 1);
        vec2 offset = (float(notch) - midpoint) * rcos + base;
        for (int i = sampleWidth - notch - notch - 1; i >= 0; --i)
        {
            vec2 sampleUV = uv + offset;
            // Missing offscreen/background geometry contributes no occlusion.
            if (all(greaterThanEqual(sampleUV, vec2(0.0))) && all(lessThanEqual(sampleUV, vec2(1.0))))
            {
                float sampleDepth = 1.0 - textureLod(sceneDepth, sampleUV, 0.0).r;
                if (sampleDepth > 1e-6)
                {
                    float dz = sampleDepth - depth;
                    // Equivalent to Godot's reversed smoothstep edges, without undefined GLSL behavior.
                    float validity = 1.0 - smoothstep(0.0, 1.0, dz * inverseFalloff);
                    occlusion += normalize(vec3(offset, dz)).z * validity;
                }
            }
            offset += rcos;
        }
        base += rsin;
    }
    float visibility = clamp(1.0 - occlusion * settings.x / 12.0, 0.0, 1.0);
    FragColor = vec4(vec3(visibility * visibility), 1.0);
}
