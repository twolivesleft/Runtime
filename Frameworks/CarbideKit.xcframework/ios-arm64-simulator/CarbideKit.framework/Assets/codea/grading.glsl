// Brightness/contrast adapted from Godot's drivers/gles3/shaders/effects/post.glsl
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

// Extend the linear toe below zero, preserving negative and HDR values for
// float targets and later compositing. Neutral settings avoid any conversion.
vec3 cameraGradeDecode(vec3 rgb)
{
    return mix(pow((max(rgb, vec3(0.0)) + 0.055) / 1.055, vec3(2.4)), rgb / 12.92,
               lessThanEqual(rgb, vec3(0.04045)));
}

vec3 cameraGradeEncode(vec3 rgb)
{
    return mix(1.055 * pow(max(rgb, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, rgb * 12.92,
               lessThanEqual(rgb, vec3(0.0031308)));
}

vec3 cameraBrightnessContrast(vec3 rgb, vec4 settings)
{
    if (settings.x == 1.0 && settings.y == 1.0) return rgb;
    bool gamma = settings.z > 0.0;
    if (settings.x != 1.0)
    {
        if (gamma) rgb = cameraGradeDecode(rgb);
        rgb *= settings.x;
        if (gamma) rgb = cameraGradeEncode(rgb);
    }
    if (settings.y != 1.0)
    {
        if (!gamma) rgb = cameraGradeEncode(rgb);
        rgb = mix(vec3(0.5), rgb, settings.y);
        if (!gamma) rgb = cameraGradeDecode(rgb);
    }
    return rgb;
}
