struct Input
{
	vec3 worldPosition;
	vec3 worldNormal;
	vec3 viewPosition;
	vec3 normal;
	vec2 uv;
#ifdef USE_UV2
	vec2 uv2;
#endif
#ifdef USE_COLOR
	vec4 color;
#endif
#ifdef USE_TANGENTS
	vec3 tangent;
	vec3 bitangent;
#endif
#ifdef USE_TANGENT_VIEW_DIR
	vec3 tangentViewDir;
#endif
};
