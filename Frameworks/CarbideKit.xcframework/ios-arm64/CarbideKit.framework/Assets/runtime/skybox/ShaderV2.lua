{
    name = "Skybox",

    properties =
    {
    },

    pass =
    {
        cullFace = "none",
        depthWrite = false,
        depthFunc = "always",
        blendMode = "disabled",
        renderQueue = "background",

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
                float mipLevel;
                float exposure;
            };
            layout(binding = 4) uniform textureCube environment;
            layout(binding = BGFX_SAMPLER_SLOT_4) uniform sampler environmentSampler;
            #define SAMPLE_ENV(dir, lod) texture(samplerCube(environment, environmentSampler), dir, lod)
            #else
            uniform samplerCube environment;
            uniform float mipLevel;
            uniform float exposure;
            #define SAMPLE_ENV(dir, lod) texture(environment, dir, lod)
            #endif

            layout (location = 0) out vec4 fragColor;

            void main()
            {
                vec3 rayDir = normalize(v_eyeDirection);
                rayDir = vec3(rayDir.x, rayDir.y, rayDir.z);
                vec3 col = SAMPLE_ENV(rayDir, mipLevel).rgb;
                col *= pow(2, exposure);
                fragColor = vec4(col, 1.0);
            }
        ]],
    }
}
