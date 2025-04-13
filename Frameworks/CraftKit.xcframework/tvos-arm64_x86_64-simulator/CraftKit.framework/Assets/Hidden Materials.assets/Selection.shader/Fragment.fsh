#extension GL_OES_standard_derivatives : enable
precision highp float;

#include <constants>

varying vec2 vUv;

uniform sampler2D screenMap;
uniform vec2 texelSize;
uniform float objectID;

vec4 sample (vec2 uv)
{
	return texture2D(screenMap, clamp(uv, 0.0, 1.0));
}

#ifdef DOWNSAMPLE
#ifdef PREFILTER

bool compareIDs(float a, float b)
{
	return distance(a * 255.0, b * 255.0) < 0.5;
}

vec4 prefilter (vec4 c)
{
	return vec4(compareIDs(c.a, objectID) ? 1.0 : 0.0);
}
#endif

vec4 sampleBox (vec2 uv, float delta)
{
	vec4 o = texelSize.xyxy * vec2(-delta, delta).xxyy;
	vec4 s =
		sample(uv + o.xy) + sample(uv + o.zy) +
		sample(uv + o.xw) + sample(uv + o.zw);
	return s * 0.25;
}

#else

uniform sampler2D sourceMap;
uniform vec3 outlineColor;
uniform float outlineThickness;

float aastep(float threshold, float value)
{
	float afwidth = length(vec2(dFdx(value), dFdy(value))) * 0.70710678118654757;
	return smoothstep(threshold-afwidth, threshold+afwidth, value);
}

vec3 sampleOutline(vec2 uv, float delta)
{
	// TODO
	vec4 col = texture2D(sourceMap, vUv);
	float mask = sample(uv).r;

	float afwidth = length(vec2(dFdx(mask), dFdy(mask))) * 0.70710678118654757;
	float s1 = smoothstep(0.5 - outlineThickness - afwidth, 0.5 - outlineThickness + afwidth, mask);
	float s2 = smoothstep(0.5 + outlineThickness - afwidth, 0.5 + outlineThickness + afwidth, mask);

	return mix(col.rgb, outlineColor, clamp(s1-s2, 0.0, 1.0));
}

#endif

vec2 snapToPixel(vec2 uv)
{
	return ((uv / texelSize) + vec2(0.5)) * texelSize;
}

void main()
{
#ifdef DOWNSAMPLE

#ifdef PREFILTER
	gl_FragColor = vec4(prefilter(sample(snapToPixel(vUv))).xyz, 1.0);
#else
	gl_FragColor = vec4(sampleBox(vUv, 1.0).xyz, 1.0);
#endif

#else
	gl_FragColor = vec4(sampleOutline(vUv, 1.0), 1.0);
#endif
}
