struct Light
{
	vec4 direction;
	vec3 color;
};

#if NUM_DIR_LIGHTS > 0
	struct DirectionalLight
    {
		vec3 direction;
		vec3 color;

		int shadow;
		float shadowBias;
		float shadowRadius;
		vec2 shadowMapSize;
	};

	uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];
#endif

#if NUM_POINT_LIGHTS > 0
	struct PointLight
    {
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
#endif

#if NUM_SPOT_LIGHTS > 0
	struct SpotLight
    {
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
#endif

// Forward declare custom lighting function
vec3 lighting(in Input IN, in Light light);

vec3 customLighting(const in Input IN, const in SurfaceOutput o)
{
    vec3 position = -IN.viewPosition;
    vec3 outgoingLight = vec3(0.0);

	Light light;

	#if ( NUM_DIR_LIGHTS > 0 )

        for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ )
        {
            DirectionalLight directionalLight = directionalLights[ i ];
			Light light;
			light.color = directionalLight.color;
			light.direction = vec4(directionalLight.direction, 0.0);

            outgoingLight += lighting(IN, light);
        }

    #endif

    #if ( NUM_POINT_LIGHTS > 0 )

        for (int i = 0; i < NUM_POINT_LIGHTS; i++)
        {
            PointLight pointLight = pointLights[i];
			Light light;
			light.color = pointLight.color;

            vec3 lightVec = pointLight.position - position;
            float lightDist = length(lightVec);
            light.direction = vec4(lightVec / lightDist, 1.0);
            light.color *= pow( saturate( -lightDist / pointLight.distance + 1.0 ), pointLight.decay );
            outgoingLight += lighting(IN, light);
        }

    #endif

    #if ( NUM_SPOT_LIGHTS > 0 )

        for (int i = 0; i < NUM_SPOT_LIGHTS; i++)
        {
            SpotLight spotLight = spotLights[i];
			Light light;
			light.color = spotLight.color;

            vec3 lightVec = spotLight.position - position;
            float lightDist = length(lightVec);
    		light.direction = vec4(lightVec / lightDist, 1.0);
    		float angleCos = dot( light.direction.xyz, spotLight.direction );
            light.color *= pow( saturate( -lightDist / spotLight.distance + 1.0 ), spotLight.decay );
            light.color *= smoothstep( spotLight.coneCos, spotLight.penumbraCos, angleCos );

            outgoingLight += lighting(IN, light);
        }

    #endif

    return outgoingLight;
}
