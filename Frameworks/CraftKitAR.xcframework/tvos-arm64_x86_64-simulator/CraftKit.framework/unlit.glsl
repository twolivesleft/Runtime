struct SurfaceOutput
{
	vec3 diffuse;
	vec3 emission;
	float emissive;
	float opacity;
#ifdef BEHIND
	vec3 behind;
#endif
};
