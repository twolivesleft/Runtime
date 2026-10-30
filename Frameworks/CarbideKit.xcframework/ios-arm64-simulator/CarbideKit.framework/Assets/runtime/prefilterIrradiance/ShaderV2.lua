{
	name = "Prefilter Irradiance",

	options =
	{
	},

	properties =
	{
		{"environmentMap", "texture"},
		{"roughness", "float", 0.0},
		{"samples", "float", 512},
	},

	pass =
	{
        renderQueue = "background",
		depthWrite = false,
        cullFace = "none",
        depthWrite = false,
        depthTest = "always",
        blendMode = "disabled",

        vertex =
        [[
            #version 430
            #include <codea/common.glsl>

            #if defined(SPIRV)
            layout(std140, binding = 0) uniform VertexUniforms {
                mat4 u_invProj;
                mat4 u_invView;
            };
            #endif

            layout (location = POSITION) in vec3 a_position;

            layout (location = 0) out vec3 v_eyeDirection;

            void main()
            {
                vec3 unprojected = (u_invProj * vec4(a_position, 1)).xyz;
                v_eyeDirection = mat3(u_invView) * unprojected;

                gl_Position = vec4(a_position.xy, 1, 1);
            }
        ]],

        fragment =
        [[
            #version 430
            #include <codea/common.glsl>

            layout (location = 0) in vec3 v_eyeDirection;

            #if defined(SPIRV)
            layout(std140, binding = 0) uniform FragUniforms {
                float roughness;
                float samples;
            };
            layout(binding = 4) uniform textureCube environmentMap;
            layout(binding = BGFX_SAMPLER_SLOT_4) uniform sampler environmentMapSampler;
            #define SAMPLE_ENV(dir, lod) textureLod(samplerCube(environmentMap, environmentMapSampler), dir, lod)
            #define ENV_SIZE(lod) textureSize(samplerCube(environmentMap, environmentMapSampler), lod)
            #else
            uniform samplerCube environmentMap;
            uniform float roughness;
            uniform float samples;
            #define SAMPLE_ENV(dir, lod) textureLod(environmentMap, dir, lod)
            #define ENV_SIZE(lod) textureSize(environmentMap, lod)
            #endif

            layout (location = 0) out vec4 fragColor;

            const float PI = 3.14159265359;

            float RadicalInverse_VdC(uint bits)
            {
                bits = (bits << 16u) | (bits >> 16u);
                bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
                bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
                bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
                bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
                return float(bits) * 2.3283064365386963e-10; // / 0x100000000
            }
            // ----------------------------------------------------------------------------
            vec2 Hammersley(uint i, uint N)
            {
                return vec2(float(i)/float(N), RadicalInverse_VdC(i));
            }

            vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness)
            {
                float a = roughness*roughness;

                float phi = 2.0 * PI * Xi.x;
                float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
                float sinTheta = sqrt(1.0 - cosTheta*cosTheta);

                // from spherical coordinates to cartesian coordinates
                vec3 H;
                H.x = cos(phi) * sinTheta;
                H.y = sin(phi) * sinTheta;
                H.z = cosTheta;

                // from tangent-space vector to world-space sample vector
                vec3 up        = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
                vec3 tangent   = normalize(cross(up, N));
                vec3 bitangent = cross(N, tangent);

                vec3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
                return normalize(sampleVec);
            }

            float DistributionGGX(float NdotH, float roughness)
            {
                float a = roughness*roughness;
                float a2 = a*a;
                float nom = a2;
                float denom = (NdotH*NdotH * (a2 - 1.0) + 1.0);
                denom = PI * denom * denom;

                return nom / denom;
            }

            void main()
            {
                vec3 N = normalize(vec3(v_eyeDirection.x, -v_eyeDirection.y, v_eyeDirection.z));
                vec3 R = N;
                vec3 V = R;

                uint SAMPLE_COUNT = uint(samples);
                float totalWeight = 0.0;
                vec3 prefilteredColor = vec3(0.0);

                float resolution = float(ENV_SIZE(0).x);

                for (uint i = 0u; i < SAMPLE_COUNT; ++i)
                {
                    vec2 Xi = Hammersley(i, SAMPLE_COUNT);
                    vec3 H  = ImportanceSampleGGX(Xi, N, roughness);
                    vec3 L  = normalize(2.0 * dot(V, H) * H - V);

                    float NdotL = max(dot(N, L), 0.0);
                    if (NdotL > 0.0)
                    {
                        float NdotH = dot(N, H);
                        float HdotV = dot(H, V);

                        float D   = DistributionGGX(NdotH, roughness);
                        float pdf = (D * NdotH / (4.0 * HdotV)) + 0.0001;

                        float saTexel  = 4.0 * PI / (6.0 * resolution * resolution);
                        float saSample = 1.0 / (float(SAMPLE_COUNT) * pdf + 0.0001);

                        float mipLevel = roughness == 0.0 ? 0.0 : 0.5 * log2(saSample / saTexel);

                        prefilteredColor += SAMPLE_ENV(L, mipLevel).rgb * NdotL;
                        totalWeight      += NdotL;
                    }
                }
                prefilteredColor = prefilteredColor / totalWeight;

                fragColor = vec4(prefilteredColor, 1.0);
            }
        ]]
	}
}
