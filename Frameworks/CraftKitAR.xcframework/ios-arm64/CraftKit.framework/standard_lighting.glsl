struct SurfaceOutput
{
	vec3 diffuse;
	vec3 normal;
	vec3 emission;
	float emissive;
	float roughness;
	float metalness;
	float occlusion;
	float opacity;
#ifdef BEHIND
	vec3 behind;
#endif
#ifdef ANISOTROPIC_SHADING
	float anisotropy;
#endif
};

vec3 BRDF_Specular_GGX(const in IncidentLight incidentLight, const in GeometricContext geometry, const in PhysicalMaterial material)
{
    return BRDF_Specular_GGX(incidentLight.direction, geometry.normal, geometry.viewDir, material.specularColor, material.specularRoughness);
}

vec3 BRDF_Specular_GGX_Environment( const in GeometricContext geometry, const in PhysicalMaterial material )
{
    return BRDF_Specular_GGX_Environment(geometry.normal, geometry.viewDir, material.specularColor, material.specularRoughness);
}

// Originally based on three.js Physical material shader (heavily modified)

bool testLightInRange( const in float lightDistance, const in float cutoffDistance )
{
	return any( bvec2( cutoffDistance == 0.0, lightDistance < cutoffDistance ) );
}

float punctualLightIntensityToIrradianceFactor( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {

		if( decayExponent > 0.0 ) {

#if defined ( PHYSICALLY_CORRECT_LIGHTS )

			// based upon Frostbite 3 Moving to Physically-based Rendering
			// page 32, equation 26: E[window1]
			// http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr_v2.pdf
			// this is intended to be used on spot and point lights who are represented as luminous intensity
			// but who must be converted to luminous irradiance for surface lighting calculation
			float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
			float maxDistanceCutoffFactor = pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
			return distanceFalloff * maxDistanceCutoffFactor;

#else

			return pow( saturate( -lightDistance / cutoffDistance + 1.0 ), decayExponent );

#endif

		}

		return 1.0;
}

uniform vec3 ambientLightColor;

vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor ) {

	vec3 irradiance = ambientLightColor;

	#ifndef PHYSICALLY_CORRECT_LIGHTS
		irradiance *= PI;
	#endif

	return irradiance;
}

#if NUM_DIR_LIGHTS > 0
	struct DirectionalLight {
		vec3 direction;
		vec3 color;

		int shadow;
		float shadowBias;
		float shadowRadius;
		vec2 shadowMapSize;
	};

	uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];

	void getDirectionalDirectLightIrradiance( const in DirectionalLight directionalLight, const in GeometricContext geometry, out IncidentLight directLight ) {

		directLight.color = directionalLight.color;
		directLight.direction = directionalLight.direction;
		directLight.visible = true;
	}
#endif

#if NUM_POINT_LIGHTS > 0
	struct PointLight {
		vec3 position;
		vec3 color;
		float distance;
		float decay;

		int shadow;
		float shadowBias;
		float shadowRadius;
		vec2 shadowMapSize;
	};

	uniform PointLight pointLights[ NUM_POINT_LIGHTS ];

	// directLight is an out parameter as having it as a return value caused compiler errors on some devices
	void getPointDirectLightIrradiance( const in PointLight pointLight, const in GeometricContext geometry, out IncidentLight directLight ) {

		vec3 lVector = pointLight.position - geometry.position;
		directLight.direction = normalize( lVector );

		float lightDistance = length( lVector );

		if ( testLightInRange( lightDistance, pointLight.distance ) ) {
			directLight.color = pointLight.color;
			directLight.color *= punctualLightIntensityToIrradianceFactor( lightDistance, pointLight.distance, pointLight.decay );
			directLight.visible = true;
		} else {

			directLight.color = vec3( 0.0 );
			directLight.visible = false;
		}
	}
#endif


#if NUM_SPOT_LIGHTS > 0
	struct SpotLight {
		vec3 position;
		vec3 direction;
		vec3 color;
		float distance;
		float decay;
		float coneCos;
		float penumbraCos;

		int shadow;
		float shadowBias;
		float shadowRadius;
		vec2 shadowMapSize;
	};

	uniform SpotLight spotLights[ NUM_SPOT_LIGHTS ];

	// directLight is an out parameter as having it as a return value caused compiler errors on some devices
	void getSpotDirectLightIrradiance( const in SpotLight spotLight, const in GeometricContext geometry, out IncidentLight directLight  ) {

		vec3 lVector = spotLight.position - geometry.position;
		directLight.direction = normalize( lVector );

		float lightDistance = length( lVector );
		float angleCos = dot( directLight.direction, spotLight.direction );

		if ( all( bvec2( angleCos > spotLight.coneCos, testLightInRange( lightDistance, spotLight.distance ) ) ) ) {
			float spotEffect = smoothstep( spotLight.coneCos, spotLight.penumbraCos, angleCos );

			directLight.color = spotLight.color;
			directLight.color *= spotEffect * punctualLightIntensityToIrradianceFactor( lightDistance, spotLight.distance, spotLight.decay );
			directLight.visible = true;
		} else {
			directLight.color = vec3( 0.0 );
			directLight.visible = false;
		}
	}
#endif

#if NUM_HEMI_LIGHTS > 0
	struct HemisphereLight {
		vec3 direction;
		vec3 skyColor;
		vec3 groundColor;
	};

	uniform HemisphereLight hemisphereLights[ NUM_HEMI_LIGHTS ];

	vec3 getHemisphereLightIrradiance( const in HemisphereLight hemiLight, const in GeometricContext geometry ) {

		float dotNL = dot( geometry.normal, hemiLight.direction );
		float hemiDiffuseWeight = 0.5 * dotNL + 0.5;

		vec3 irradiance = mix( hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight );

		#ifndef PHYSICALLY_CORRECT_LIGHTS

			irradiance *= PI;

		#endif

		return irradiance;

	}
#endif

#if defined( USE_ENVMAP ) && defined( PHYSICAL )

	vec3 getLightProbeIndirectIrradiance( /*const in SpecularLightProbe specularLightProbe,*/ const in GeometricContext geometry, const in int maxMIPLevel ) {
#ifdef DOUBLE_SIDED
	float flipNormal = -( float( gl_FrontFacing ) * 2.0 - 1.0 );
#else
	float flipNormal = 1.0;
#endif

		vec3 worldNormal = inverseTransformDirection( geometry.normal, viewMatrix );

		#ifdef ENVMAP_TYPE_CUBE

			vec3 queryVec = flipNormal * vec3( worldNormal.x, -worldNormal.y, -worldNormal.z );

			// TODO: replace with properly filtered cubemaps and access the irradiance LOD level, be it the last LOD level
			// of a specular cubemap, or just the default level of a specially created irradiance cubemap.

			#ifdef TEXTURE_LOD_EXT

				vec4 envMapColor = textureLod( envMap, queryVec, float( maxMIPLevel ) );

			#else

				// force the bias high to get the last LOD level as it is the most blurred.
				vec4 envMapColor = texture( envMap, queryVec, float( maxMIPLevel ) );

			#endif

			envMapColor.rgb = envMapTexelToLinear( envMapColor ).rgb;

		#elif defined( ENVMAP_TYPE_CUBE_UV )

			vec3 queryVec = flipNormal * vec3( worldNormal.x, -worldNormal.y, worldNormal.z );
			vec4 envMapColor = textureUV( queryVec, 1.0 );

		#else

			vec4 envMapColor = vec4( 0.0 );

		#endif

		return PI * envMapColor.rgb;

	}

	// taken from here: http://casual-effects.blogspot.ca/2011/08/plausible-environment-lighting-in-two.html
	float getSpecularMIPLevel( const in float blinnShininessExponent, const in int maxMIPLevel ) {

		//float envMapWidth = pow( 2.0, maxMIPLevelScalar );
		//float desiredMIPLevel = log2( envMapWidth * sqrt( 3.0 ) ) - 0.5 * log2( pow2( blinnShininessExponent ) + 1.0 );

		float maxMIPLevelScalar = float( maxMIPLevel );
		float desiredMIPLevel = maxMIPLevelScalar - 0.79248 - 0.5 * log2( pow2( blinnShininessExponent ) + 1.0 );

		// clamp to allowable LOD ranges.
		return clamp( desiredMIPLevel, 0.0, maxMIPLevelScalar );
	}

	vec3 getLightProbeIndirectRadiance( const in GeometricContext geometry, const in PhysicalMaterial material, const in float blinnShininessExponent, const in int maxMIPLevel ) {

		vec3 normal = geometry.normal;

		#ifdef ANISOTROPIC_SHADING
			vec3 anisotropicDirection = material.anisotropy >= 0.0 ? geometry.bitangent : geometry.tangent;
			vec3 anisotropicTangent = cross(anisotropicDirection, geometry.viewDir);
			vec3 anisotropicNormal = cross(anisotropicTangent, anisotropicDirection);
			normal = normalize(mix(normal, anisotropicNormal, abs(material.anisotropy)));
		#endif

		#ifdef ENVMAP_MODE_REFLECTION

			vec3 reflectVec = reflect( -geometry.viewDir, normal );

		#else

			vec3 reflectVec = refract( -geometry.viewDir, normal, refractionRatio );

		#endif

#ifdef DOUBLE_SIDED
	float flipNormal = -( float( gl_FrontFacing ) * 2.0 - 1.0 );
#else
	float flipNormal = 1.0;
#endif

		reflectVec = inverseTransformDirection( reflectVec, viewMatrix );

		float specularMIPLevel = getSpecularMIPLevel( blinnShininessExponent, maxMIPLevel );

		#ifdef ENVMAP_TYPE_CUBE

			vec3 queryReflectVec = flipNormal * vec3( reflectVec.x, -reflectVec.y, -reflectVec.z );

			#ifdef TEXTURE_LOD_EXT

				vec4 envMapColor = textureLod( envMap, queryReflectVec, specularMIPLevel );

			#else

				vec4 envMapColor = texture( envMap, queryReflectVec, specularMIPLevel );

			#endif

			envMapColor.rgb = envMapTexelToLinear( envMapColor ).rgb;

		#elif defined( ENVMAP_TYPE_CUBE_UV )

			vec3 queryReflectVec = flipNormal * vec3( reflectVec.x, -reflectVec.y, reflectVec.z );
			vec4 envMapColor = textureUV(queryReflectVec, BlinnExponentToGGXRoughness(blinnShininessExponent));

		#elif defined( ENVMAP_TYPE_EQUIREC )

			vec2 sampleUV;
			sampleUV.y = saturate( flipNormal * reflectVec.y * 0.5 + 0.5 );
			sampleUV.x = atan( flipNormal * reflectVec.z, flipNormal * reflectVec.x ) * RECIPROCAL_PI2 + 0.5;

			#ifdef TEXTURE_LOD_EXT
				vec4 envMapColor = textureLod( envMap, sampleUV, specularMIPLevel );
			#else
				vec4 envMapColor = texture( envMap, sampleUV, specularMIPLevel );
			#endif

			envMapColor.rgb = envMapTexelToLinear( envMapColor ).rgb;

		#elif defined( ENVMAP_TYPE_SPHERE )

			vec3 reflectView = flipNormal * normalize( ( viewMatrix * vec4( reflectVec, 0.0 ) ).xyz + vec3( 0.0,0.0,1.0 ) );

			#ifdef TEXTURE_LOD_EXT

				vec4 envMapColor = textureLod( envMap, reflectView.xy * 0.5 + 0.5, specularMIPLevel );

			#else

				vec4 envMapColor = texture( envMap, reflectView.xy * 0.5 + 0.5, specularMIPLevel );

			#endif

			envMapColor.rgb = envMapTexelToLinear( envMapColor ).rgb;

		#endif

		return envMapColor.rgb;

	}

#endif

#define MAXIMUM_SPECULAR_COEFFICIENT 0.16
#define DEFAULT_SPECULAR_COEFFICIENT 0.04

// Clear coat directional hemishperical reflectance (this approximation should be improved)
float clearCoatDHRApprox( const in float roughness, const in float dotNL )
{
	return DEFAULT_SPECULAR_COEFFICIENT + ( 1.0 - DEFAULT_SPECULAR_COEFFICIENT ) * ( pow( 1.0 - dotNL, 5.0 ) * pow( 1.0 - roughness, 2.0 ) );
}

void RE_Direct_Physical( const in IncidentLight directLight, const in GeometricContext geometry, const in PhysicalMaterial material, inout ReflectedLight reflectedLight )
{
	float dotNL = saturate( dot( geometry.normal, directLight.direction ) );

	vec3 irradiance = dotNL * directLight.color;

	#ifndef PHYSICALLY_CORRECT_LIGHTS

		irradiance *= PI; // punctual light

	#endif

	#ifndef STANDARD
		float clearCoatDHR = material.clearCoat * clearCoatDHRApprox( material.clearCoatRoughness, dotNL );
	#else
		float clearCoatDHR = 0.0;
	#endif

	reflectedLight.directSpecular += ( 1.0 - clearCoatDHR ) * irradiance * BRDF_Specular_GGX( directLight, geometry, material );
	reflectedLight.directDiffuse += ( 1.0 - clearCoatDHR ) * irradiance * BRDF_Diffuse_Lambert( material.diffuseColor );

	#ifndef STANDARD

		reflectedLight.directSpecular += irradiance * material.clearCoat * BRDF_Specular_GGX( directLight, geometry, vec3( DEFAULT_SPECULAR_COEFFICIENT ), material.clearCoatRoughness );

	#endif
}

void RE_IndirectDiffuse_Physical( const in vec3 irradiance, const in GeometricContext geometry, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Diffuse_Lambert( material.diffuseColor );
}

void RE_IndirectSpecular_Physical( const in vec3 radiance, const in vec3 clearCoatRadiance, const in GeometricContext geometry, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {

	#ifndef STANDARD
		float dotNV = saturate( dot( geometry.normal, geometry.viewDir ) );
		float dotNL = dotNV;
		float clearCoatDHR = material.clearCoat * clearCoatDHRApprox( material.clearCoatRoughness, dotNL );
	#else
		float clearCoatDHR = 0.0;
	#endif

		reflectedLight.indirectSpecular += ( 1.0 - clearCoatDHR ) * radiance * BRDF_Specular_GGX_Environment( geometry, material);

	#ifndef STANDARD

		reflectedLight.indirectSpecular += clearCoatRadiance * material.clearCoat * BRDF_Specular_GGX_Environment( geometry, vec3( DEFAULT_SPECULAR_COEFFICIENT ), material.clearCoatRoughness );

	#endif
}

#define RE_Direct				RE_Direct_Physical
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Physical
#define RE_IndirectSpecular		RE_IndirectSpecular_Physical

#define Material_BlinnShininessExponent( material )   GGXRoughnessToBlinnExponent( material.specularRoughness )
#define Material_ClearCoat_BlinnShininessExponent( material )   GGXRoughnessToBlinnExponent( material.clearCoatRoughness )

// ref: http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr_v2.pdf
float computeSpecularOcclusion( const in float dotNV, const in float ambientOcclusion, const in float roughness )
{
	return saturate( pow( dotNV + ambientOcclusion, exp2( - 16.0 * roughness - 1.0 ) ) - 1.0 + ambientOcclusion );
}

vec3 standardLighting( const in Input IN, const in SurfaceOutput o)
{
	vec4 diffuseColor = vec4( o.diffuse, o.opacity );
    diffuseColor = mapTexelToLinear(diffuseColor);

	float roughnessFactor = o.roughness;
	float metalnessFactor = o.metalness;

	// accumulation
	PhysicalMaterial material;
	material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );
	material.specularRoughness = clamp( roughnessFactor, 0.04, 1.0 );
	material.ambientOcclusion = o.occlusion;
	material.emission = vec3(o.emissive) * o.emission;
	#ifdef ANISOTROPIC_SHADING
	material.anisotropy = o.anisotropy;
	#endif

#ifdef STANDARD
	material.specularColor = mix( vec3( DEFAULT_SPECULAR_COEFFICIENT ), diffuseColor.rgb, metalnessFactor );
#else
	material.specularColor = mix( vec3( MAXIMUM_SPECULAR_COEFFICIENT * pow2( reflectivity ) ), diffuseColor.rgb, metalnessFactor );
	material.clearCoat = saturate( clearCoat ); // Burley clearcoat model
	material.clearCoatRoughness = clamp( clearCoatRoughness, 0.04, 1.0 );
#endif

	GeometricContext geometry;

	geometry.position = -IN.viewPosition;
	geometry.normal = o.normal;
	#ifdef ANISOTROPIC_SHADING
	geometry.tangent = normalize(IN.tangent);
	geometry.bitangent = normalize(IN.bitangent);
	#endif
	geometry.viewDir = normalize( IN.viewPosition );

	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	IncidentLight directLight;

	#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )
		PointLight pointLight;
		for (int i = 0; i < NUM_POINT_LIGHTS; i ++)
		{
			pointLight = pointLights[i];

			getPointDirectLightIrradiance( pointLight, geometry, directLight );

			#ifdef USE_SHADOWMAP
			directLight.color *= all( bvec2( pointLight.shadow, directLight.visible ) ) ? getPointShadow( pointShadowMap[ i ], pointLight.shadowMapSize, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[ i ] ) : 1.0;
			#endif

			RE_Direct( directLight, geometry, material, reflectedLight );
		}
	#endif

	#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )
		SpotLight spotLight;
		for (int i = 0; i < NUM_SPOT_LIGHTS; i++)
		{
			spotLight = spotLights[ i ];

			getSpotDirectLightIrradiance( spotLight, geometry, directLight );

			#ifdef USE_SHADOWMAP
			directLight.color *= all( bvec2( spotLight.shadow, directLight.visible ) ) ? getShadow( spotShadowMap[ i ], spotLight.shadowMapSize, spotLight.shadowBias, spotLight.shadowRadius, vSpotShadowCoord[ i ] ) : 1.0;
			#endif

			RE_Direct( directLight, geometry, material, reflectedLight );
		}
	#endif

	#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )
		DirectionalLight directionalLight;
		for (int i = 0; i < NUM_DIR_LIGHTS; i++)
		{
			directionalLight = directionalLights[i];

			getDirectionalDirectLightIrradiance( directionalLight, geometry, directLight );

			#ifdef USE_SHADOWMAP
			directLight.color *= all( bvec2( directionalLight.shadow, directLight.visible ) ) ? getShadow( directionalShadowMap[ i ], directionalLight.shadowMapSize, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
			#endif

			RE_Direct( directLight, geometry, material, reflectedLight );
		}
	#endif

	#if defined( RE_IndirectDiffuse )
		vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );

		#if defined( USE_ENVMAP ) && defined( PHYSICAL ) //&& defined( ENVMAP_TYPE_CUBE_UV )
			// TODO, replace 8 with the real maxMIPLevel
		 	irradiance += getLightProbeIndirectIrradiance( /*lightProbe,*/ geometry, 5 );
		#endif

		RE_IndirectDiffuse( irradiance, geometry, material, reflectedLight );
	#endif

	#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )

		// TODO, replace 8 with the real maxMIPLevel
		vec3 radiance = getLightProbeIndirectRadiance( geometry, material, Material_BlinnShininessExponent( material ), 5 );

		#ifndef STANDARD
			vec3 clearCoatRadiance = getLightProbeIndirectRadiance( geometry, material, Material_ClearCoat_BlinnShininessExponent( material ), 5 );
		#else
			vec3 clearCoatRadiance = vec3( 0.0 );
		#endif

		RE_IndirectSpecular( radiance, clearCoatRadiance, geometry, material, reflectedLight );

	#endif

	reflectedLight.indirectDiffuse *= material.ambientOcclusion;

	#if defined( USE_ENVMAP ) && defined( PHYSICAL )
		float dotNV = saturate( dot( geometry.normal, geometry.viewDir ) );
		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, material.ambientOcclusion, material.specularRoughness );
	#endif

	vec3 outgoingLight =
		reflectedLight.directDiffuse +
		reflectedLight.indirectDiffuse +
		reflectedLight.directSpecular +
		reflectedLight.indirectSpecular +
		material.emission;

#ifdef GAMMA_CORRECTION
    outgoingLight = pow(outgoingLight, vec3(1.0/gamma));
#endif

	return outgoingLight;
}
