// ref: http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr_v2.pdf
float computeSpecularOcclusion(const in float dotNV, const in float ambientOcclusion, const in float roughness)
{
	return saturate( pow( dotNV + ambientOcclusion, exp2( - 16.0 * roughness - 1.0 ) ) - 1.0 + ambientOcclusion );
}

// taken from here: http://casual-effects.blogspot.ca/2011/08/plausible-environment-lighting-in-two.html
float getSpecularMIPLevel(const in float blinnShininessExponent, const in int maxMIPLevel)
{
    float maxMIPLevelScalar = float( maxMIPLevel );
    float desiredMIPLevel = maxMIPLevelScalar - 0.79248 - 0.5 * log2( pow2( blinnShininessExponent ) + 1.0 );

    // clamp to allowable LOD ranges.
    return clamp( desiredMIPLevel, 0.0, maxMIPLevelScalar );
}

void physicalIndirectLighting(in GeometricContext geometry, in SurfaceOutput o)
{
    // TODO: potentially refactor geometry, material and reflectedLight structs

    irradiance = ambientLightColor;

    #ifdef DOUBLE_SIDED
    	float flipNormal = -( float( gl_FrontFacing ) * 2.0 - 1.0 );
    #else
    	float flipNormal = 1.0;
    #endif

    int maxMIPLevel = 5; // TODO: replace with actual mip level

    vec3 worldNormal = inverseTransformDirection( geometry.normal, viewMatrix );

    #ifdef defined( USE_ENVMAP ) && defined(ENVMAP_TYPE_CUBE)
        vec3 queryVec = flipNormal * vec3( worldNormal.x, -worldNormal.y, -worldNormal.z );
        vec4 envMapColor = textureLod( envMap, queryVec, float( maxMIPLevel ) );
        irradiance += envMapTexelToLinear( envMapColor ).rgb;

        vec3 reflectVec = reflect( -geometry.viewDir, geometry.normal );
        reflectVec = inverseTransformDirection( reflectVec, viewMatrix );
        float specularMIPLevel = getSpecularMIPLevel( blinnShininessExponent, maxMIPLevel );
        vec3 queryReflectVec = flipNormal * vec3( reflectVec.x, -reflectVec.y, -reflectVec.z );
        envMapColor = textureLod( envMap, queryReflectVec, specularMIPLevel );

        vec3 radiance = envMapTexelToLinear( envMapColor ).rgb;
        light.indirectSpecular = radiance * BRDF_Specular_GGX_Environment( geometry, material);
    #endif

    vec4 diffuseColor = vec4( o.diffuse, o.opacity );
    diffuseColor = mapTexelToLinear(diffuseColor);
    diffuseColor.rgb = diffuseColor.rgb * ( 1.0 - o.metalness );

    light.indirectDiffuse = irradiance * BRDF_Diffuse_Lambert( diffuseColor );
    light.indirectDiffuse *= material.ambientOcclusion;

    float specularRoughness = clamp( o.roughness, 0.04, 1.0 );

    float dotNV = saturate( dot( geometry.normal, geometry.viewDir ) );
    light.indirectSpecular *= computeSpecularOcclusion( dotNV, o.occlusion, specularRoughness );
}
