precision mediump float;

varying vec2 vUv;

uniform mediump sampler2D screenMap;
uniform vec2 texelSize;

vec3 sample (vec2 uv)
{
	return texture2D(screenMap, clamp(uv, 0.0, 1.0)).rgb;
}

vec3 sampleBox (vec2 uv, float delta)
{
	vec4 o = texelSize.xyxy * vec2(-delta, delta).xxyy;
	vec3 s =
		sample(uv + o.xy) + sample(uv + o.zy) +
		sample(uv + o.xw) + sample(uv + o.zw);
	return s * 0.25;
}

void main()
{
	gl_FragColor = vec4(sampleBox(vUv, 0.5), 1.0);
}
