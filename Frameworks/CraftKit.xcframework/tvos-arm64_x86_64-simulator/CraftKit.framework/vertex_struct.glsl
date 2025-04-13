struct Vertex
{
	vec3 position;
	vec3 normal;
#ifdef USE_TANGENTS
    vec4 tangent;
#endif
	vec2 uv;
#ifdef USE_UV2
	vec2 uv2;
#endif
#ifdef USE_COLOR
	vec4 color;
#endif
};
