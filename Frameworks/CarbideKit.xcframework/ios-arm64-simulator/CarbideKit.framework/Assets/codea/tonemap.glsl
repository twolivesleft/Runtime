// AgX/allenwp adapted from Godot's drivers/gles3/shaders/tonemap_inc.glsl
// and servers/rendering/storage/environment_storage.cpp at
// 4d0d43b77dd2ffbd7dc867c08bcc3dd9962fd7e7.
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

// SDR AgX with Godot's default contrast (1.25), middle gray (0.18), and a
// fixed scene white of 16.0 to retain four stops above reference white.
// Godot's CPU formulas reduce to these constants for this configuration:
// toeA = (1 / 0.18 - 1) * pow(0.18, 1.25)
// slope = contrast * (1 - 0.18)
// shoulderW = (16 - 0.18)^2 * slope / (1 - 0.18)
// Curve: https://allenwp.com/blog/2025/05/29/allenwp-tonemapping-curve/
vec3 cameraAgXCurve(vec3 x)
{
    const float crossover = 0.18;
    const float contrast = 1.25;
    const float toeA = 0.534111561194757;
    const float slope = 1.025;
    const float shoulderW = 312.8405;

    vec3 s = x - crossover;
    vec3 shoulder = slope * s * (1.0 + s / shoulderW) / (1.0 + slope * s / 0.82) + crossover;
    vec3 toe = pow(x, vec3(contrast));
    toe /= toe + toeA;
    return mix(shoulder, toe, lessThan(x, vec3(crossover)));
}

vec3 cameraTonemapAgX(vec3 rgb)
{
    // Combined Rec. 709 -> Rec. 2020 and AgX inset; GLSL matrices are column-major.
    const mat3 inset = mat3(
        0.544814746488245, 0.140416948464053, 0.0888104196149096,
        0.373787398372697, 0.754137554567394, 0.178871756420858,
        0.0813978551390581, 0.105445496968552, 0.732317823964232);
    const mat3 outset = mat3(
        1.96488741169489, -0.299313364904742, -0.164352742528393,
        -0.855988495690215, 1.32639796461980, -0.238183969428088,
        -0.108898916004672, -0.0270845997150571, 1.40253671195648);

    // The curve maps 16 to 1, then Godot clips at 1 before the outset. Bounding
    // its input is equivalent and avoids overflow for high exposure values.
    vec3 mapped = cameraAgXCurve(min(inset * max(rgb, vec3(0.0)), vec3(16.0)));
    // Clamp gamut excursions before later grading and sRGB encoding.
    return clamp(outset * min(mapped, vec3(1.0)), 0.0, 1.0);
}

vec3 cameraSRGBToLinear(vec3 rgb)
{
    return mix(pow((rgb + 0.055) / 1.055, vec3(2.4)), rgb / 12.92,
               lessThanEqual(rgb, vec3(0.04045)));
}

vec3 cameraLinearToSRGB(vec3 rgb)
{
    return mix(1.055 * pow(rgb, vec3(1.0 / 2.4)) - 0.055, rgb * 12.92,
               lessThanEqual(rgb, vec3(0.0031308)));
}
