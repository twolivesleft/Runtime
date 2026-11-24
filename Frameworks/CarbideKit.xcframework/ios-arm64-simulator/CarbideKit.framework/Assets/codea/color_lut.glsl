// Color correction adapted from Godot's drivers/gles3/shaders/effects/post.glsl
// at 4d0d43b77dd2ffbd7dc867c08bcc3dd9962fd7e7.
//
// Copyright (c) 2014-present Godot Engine contributors (see https://godotengine.org).
// Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Godot applies LUTs in perceptual sRGB space. Use exact transfer functions
// for Carbide's linear pipeline, then return to its incoming color space.
vec3 cameraLutDecode(vec3 rgb)
{
    return mix(pow((max(rgb, vec3(0.0)) + 0.055) / 1.055, vec3(2.4)), rgb / 12.92,
               lessThanEqual(rgb, vec3(0.04045)));
}

vec3 cameraLutEncode(vec3 rgb)
{
    return mix(1.055 * pow(max(rgb, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, rgb * 12.92,
               lessThanEqual(rgb, vec3(0.0031308)));
}

// A horizontal strip of N blue slices, each N x N (red x green). Address
// texel centers so interpolation cannot bleed into the adjacent blue slice.
// Two bilinear samples plus interpolation in blue implement trilinear lookup.
vec3 cameraColorLut(vec3 rgb, sampler2D lut, vec4 settings)
{
    if (settings.x < 2.0 || settings.y <= 0.0) return rgb;
    vec3 coordinate = settings.z > 0.0 ? rgb : cameraLutEncode(rgb);
    coordinate = clamp(coordinate, 0.0, 1.0) * (settings.x - 1.0);
    float slice = floor(coordinate.b);
    vec2 size = vec2(settings.x * settings.x, settings.x);
    vec2 uv0 = (vec2(slice * settings.x, 0.0) + coordinate.rg + 0.5) / size;
    vec2 uv1 = (vec2(min(slice + 1.0, settings.x - 1.0) * settings.x, 0.0) + coordinate.rg + 0.5) / size;
    // Image rows are stored top-down; Codea's setValue coordinates grow upward.
    uv0.y = 1.0 - uv0.y;
    uv1.y = 1.0 - uv1.y;
    vec3 mapped = mix(textureLod(lut, uv0, 0.0).rgb, textureLod(lut, uv1, 0.0).rgb, fract(coordinate.b));
    if (settings.z <= 0.0) mapped = cameraLutDecode(mapped);
    return mix(rgb, mapped, settings.y);
}
