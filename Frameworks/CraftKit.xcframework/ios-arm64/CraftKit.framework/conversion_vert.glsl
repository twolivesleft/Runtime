// Object space conversions
vec3 objectToViewSpace(in vec4 v)
{
	return (modelViewMatrix * v).xyz;
}

vec3 objectToWorldSpace(in vec4 v)
{
	return (modelMatrix * v).xyz;
}

vec3 objectToTangentSpace(in vec4 v)
{
	// TODO:
	return v.xyz;
}

vec3 objectToClipSpace(in vec4 v)
{
	vec4 res = (projectionMatrix * modelViewMatrix * v);
	return res.xyz / res.w;
}

// World space conversions
vec3 worldToObjectSpace(in vec4 v)
{
	return (inverseModelMatrix * v).xyz;
}

vec3 worldToViewSpace(in vec4 v)
{
	return (viewMatrix * inverseModelMatrix * v).xyz;
}

vec3 worldToTangentSpace(in vec4 v)
{
	// TODO:
	return v.xyz;
}

// Tangent space conversions
vec3 tangentToViewSpace(in vec4 v)
{
	return v.xyz;
	//vec3 bitangent = (cross(normal, tangent.xyz) * tangent.w);
	//return normalize(v.x * tangent.xyz + v.y * bitangent + v.z * normal) - -(modelViewMatrix * position).xyz * v.w;
}

vec3 tangentToObjectSpace(in vec4 v)
{
	vec3 bitangent = (cross(normal, tangent.xyz) * tangent.w);
	return v.x * tangent.xyz + v.y * bitangent + v.z * normal;
}

vec3 tangentToWorldSpace(in vec4 v)
{
	return v.xyz;
}

// View space conversions
vec3 viewToWorldSpace(in vec4 v)
{
    return (modelMatrix * (inverseViewMatrix * v)).xyz;
}

vec3 viewToObjectSpace(in vec4 v)
{
    return (inverseViewMatrix * v).xyz;
}

vec3 viewToTangentSpace(in vec4 v)
{
	// TODO
    return v.xyz;
}
