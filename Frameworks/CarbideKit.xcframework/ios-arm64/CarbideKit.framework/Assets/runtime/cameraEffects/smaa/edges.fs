// Adapted from Godot smaa_edge_detection.glsl at 4d0d43b77dd2ffbd7dc867c08bcc3dd9962fd7e7.
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
in vec2 uv;
uniform vec4 settings;
#define tex_coord uv





uniform sampler2D color_tex;

out vec2 edges;



#define SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR 2.0

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


vec3 edgeColor(vec2 coordinate) {
    vec3 color=texture(color_tex,coordinate).rgb;
    return settings.z > 0.0 ? color : smaaEncode(color);
}
void main() {
    vec4 offset[3];
    offset[0]=fma(settings.xyxy,vec4(-1.0,0.0,0.0,-1.0),uv.xyxy);
    offset[1]=fma(settings.xyxy,vec4(1.0,0.0,0.0,1.0),uv.xyxy);
    offset[2]=fma(settings.xyxy,vec4(-2.0,0.0,0.0,-2.0),uv.xyxy);

	vec2 threshold = vec2(settings.w);

	vec4 delta;
	vec3 C = edgeColor(tex_coord);

	vec3 Cleft = edgeColor(offset[0].xy);
	vec3 t = abs(C - Cleft);
	delta.x = max(max(t.r, t.g), t.b);

	vec3 Ctop = edgeColor(offset[0].zw);
	t = abs(C - Ctop);
	delta.y = max(max(t.r, t.g), t.b);

	edges = step(threshold, delta.xy);

	if (dot(edges, vec2(1.0, 1.0)) == 0.0) {
		return;
	}

	vec3 Cright = edgeColor(offset[1].xy);
	t = abs(C - Cright);
	delta.z = max(max(t.r, t.g), t.b);

	vec3 Cbottom = edgeColor(offset[1].zw);
	t = abs(C - Cbottom);
	delta.w = max(max(t.r, t.g), t.b);

	vec2 max_delta = max(delta.xy, delta.zw);

	vec3 Cleftleft = edgeColor(offset[2].xy);
	t = abs(Cleft - Cleftleft);
	delta.z = max(max(t.r, t.g), t.b);

	vec3 Ctoptop = edgeColor(offset[2].zw);
	t = abs(Ctop - Ctoptop);
	delta.w = max(max(t.r, t.g), t.b);

	max_delta = max(max_delta.xy, delta.zw);
	float final_delta = max(max_delta.x, max_delta.y);

	edges.xy *= step(final_delta, SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR * delta.xy);
}
