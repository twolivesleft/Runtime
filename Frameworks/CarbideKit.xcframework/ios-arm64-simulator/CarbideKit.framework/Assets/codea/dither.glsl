// RGB dither adapted from Godot's renderer_rd/shaders/effects/tonemap.glsl
// at 4d0d43b77dd2ffbd7dc867c08bcc3dd9962fd7e7 (Iestyn's RGB dither).
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

// Work in the space the destination quantizes: sRGB for an sRGB target,
// otherwise the incoming space. The transfer functions are independent of
// camera tone mapping, so debanding can be used with any tone curve.
vec4 cameraDither(vec4 color, vec2 pixel, vec4 settings)
{
    if (settings.x <= 0.0) return color;

    vec3 rgb = color.rgb;
    if (settings.y > 0.0)
    {
        vec3 high = 1.055 * pow(max(rgb, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055;
        rgb = mix(high, rgb * 12.92, lessThanEqual(rgb, vec3(0.0031308)));
    }

    // A stable per-pixel pattern, centered on zero, spanning one output code.
    vec3 noise = fract(vec3(dot(vec2(171.0, 231.0), pixel)) / vec3(103.0, 71.0, 97.0)) - 0.5;
    rgb += noise * settings.x;

    // Hardware will encode again on write; avoid double-encoding the result.
    // Keep out-of-range values: translucent cameras may blend them back into
    // range. Clamping here would change their brightness before compositing.
    if (settings.y > 0.0)
    {
        vec3 high = pow((max(rgb, vec3(0.0)) + 0.055) / 1.055, vec3(2.4));
        rgb = mix(high, rgb / 12.92, lessThanEqual(rgb, vec3(0.04045)));
    }
    return vec4(rgb, color.a);
}
