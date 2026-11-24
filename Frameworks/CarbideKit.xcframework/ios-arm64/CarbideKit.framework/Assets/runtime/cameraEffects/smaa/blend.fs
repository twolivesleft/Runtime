// Adapted from Godot smaa_blending.glsl at 4d0d43b77dd2ffbd7dc867c08bcc3dd9962fd7e7.
/**
 * Copyright (C) 2013 Jorge Jimenez (jorge@iryoku.com)
 * Copyright (C) 2013 Jose I. Echevarria (joseignacioechevarria@gmail.com)
 * Copyright (C) 2013 Belen Masia (bmasia@unizar.es)
 * Copyright (C) 2013 Fernando Navarro (fernandn@microsoft.com)
 * Copyright (C) 2013 Diego Gutierrez (diegog@unizar.es)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to
 * do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software. As clarification, there
 * is no requirement that the copyright notice and permission be included in
 * binary distributions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */


#version 430
#include <codea/common.glsl>
#include <codea/dither.glsl>
uniform vec4 outputDither;
in vec2 uv;
uniform vec4 settings;
#define tex_coord uv




uniform sampler2D color_tex;
uniform sampler2D blend_tex;

out vec4 out_color;

vec3 smaaDecode(vec3 rgb)
{
    return mix(pow((max(rgb, vec3(0.0)) + 0.055) / 1.055, vec3(2.4)), rgb / 12.92,
               lessThanEqual(rgb, vec3(0.04045)));
}

vec3 smaaEncode(vec3 rgb)
{
    return mix(1.055 * pow(max(rgb, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, rgb * 12.92,
               lessThanEqual(rgb, vec3(0.0031308)));
}

vec3 smaaLinearSample(vec2 coordinate) {
    vec3 color=textureLod(color_tex,coordinate,0.0).rgb;
    return settings.z > 0.0 ? smaaDecode(color) : color;
}
void SMAAMovc(bvec2 cond, inout vec2 variable, vec2 value) {
	if (cond.x) {
		variable.x = value.x;
	}
	if (cond.y) {
		variable.y = value.y;
	}
}

void SMAAMovc(bvec4 cond, inout vec4 variable, vec4 value) {
	SMAAMovc(cond.xy, variable.xy, value.xy);
	SMAAMovc(cond.zw, variable.zw, value.zw);
}

void main() {
    vec4 offset=fma(settings.xyxy,vec4(1.0,0.0,0.0,1.0),uv.xyxy);
	vec4 a;
	a.x = texture(blend_tex, offset.xy).a;
	a.y = texture(blend_tex, offset.zw).g;
	a.wz = texture(blend_tex, tex_coord).xz;

	if (dot(a, vec4(1.0, 1.0, 1.0, 1.0)) < 1e-5) {
		out_color = textureLod(color_tex, tex_coord, 0.0);
	} else {
		bool h = max(a.x, a.z) > max(a.y, a.w);

		vec4 blending_offset = vec4(0.0, a.y, 0.0, a.w);
		vec2 blending_weight = a.yw;

		SMAAMovc(bvec4(h, h, h, h), blending_offset, vec4(a.x, 0.0, a.z, 0.0));
		SMAAMovc(bvec2(h, h), blending_weight, a.xz);
		blending_weight /= dot(blending_weight, vec2(1.0, 1.0));

		vec4 blending_coord = fma(blending_offset, vec4(settings.xy.xy, -settings.xy.xy), tex_coord.xyxy);

		out_color.rgb = blending_weight.x * smaaLinearSample(blending_coord.xy);
		out_color.rgb += blending_weight.y * smaaLinearSample(blending_coord.zw);
		if (settings.z > 0.0) out_color.rgb = smaaEncode(out_color.rgb);
		out_color.a = texture(color_tex, tex_coord).a;
	}
    out_color = cameraDither(out_color, gl_FragCoord.xy, outputDither);
}
