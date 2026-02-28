vec3 objectToViewSpace(in Input IN, in vec4 v);
vec3 objectToWorldSpace(in Input IN, in vec4 v);
vec3 objectToTangentSpace(in Input IN, in vec4 v);
vec3 objectToClipSpace(in Input IN, in vec4 v);

vec3 worldToObjectSpace(in Input IN, in vec4 v);
vec3 worldToViewSpace(in Input IN, in vec4 v);
vec3 worldToTangentSpace(in Input IN, in vec4 v);

vec3 tangentToViewSpace(in Input IN, in vec4 v);
vec3 tangentToObjectSpace(in Input IN, in vec4 v);
vec3 tangentToWorldSpace(in Input IN, in vec4 v);

vec3 viewToWorldSpace(in Input IN, in vec4 v);
vec3 viewToObjectSpace(in Input IN, in vec4 v);
vec3 viewToTangentSpace(in Input IN, in vec4 v);

// Object space conversions
vec3 objectToViewSpace(in Input IN, in vec4 v)
{
	return (modelViewMatrix * v).xyz;
}

vec3 objectToWorldSpace(in Input IN, in vec4 v)
{
	return (modelMatrix * v).xyz;
}

vec3 objectToTangentSpace(in Input IN, in vec4 v)
{
	// TODO:
	return v.xyz;
}

vec3 objectToClipSpace(in Input IN, in vec4 v)
{
	vec4 res = (projectionMatrix * modelViewMatrix * v);
	return res.xyz / res.w;
}

// World space conversions
vec3 worldToObjectSpace(in Input IN, in vec4 v)
{
	return (inverseModelMatrix * v).xyz;
}

vec3 worldToViewSpace(in Input IN, in vec4 v)
{
	return (viewMatrix * inverseModelMatrix * v).xyz;
}

vec3 worldToTangentSpace(in Input IN, in vec4 v)
{
	// TODO:
	return v.xyz;
}

// Tangent space conversions
vec3 tangentToViewSpace(in Input IN, in vec4 v)
{
	mat3 viewToTangent = mat3(normalize(IN.tangent), normalize(IN.bitangent), normalize(IN.normal));
	return viewToTangent * v.xyz;
}

vec3 tangentToObjectSpace(in Input IN, in vec4 v)
{
	// TODO:
    return v.xyz;
}

vec3 tangentToWorldSpace(in Input IN, in vec4 v)
{
    return v.x * IN.tangent + v.y * IN.bitangent + v.z * IN.normal;
}

// View space conversions
vec3 viewToWorldSpace(in Input IN, in vec4 v)
{
    return (modelMatrix * (inverseViewMatrix * v)).xyz;
}

vec3 viewToObjectSpace(in Input IN, in vec4 v)
{
    return (inverseViewMatrix * v).xyz;
}

vec3 viewToTangentSpace(in Input IN, in vec4 v)
{
	mat3 viewToTangent = mat3(normalize(IN.tangent), normalize(IN.bitangent), normalize(IN.normal));
	return v.xyz * viewToTangent;
}
