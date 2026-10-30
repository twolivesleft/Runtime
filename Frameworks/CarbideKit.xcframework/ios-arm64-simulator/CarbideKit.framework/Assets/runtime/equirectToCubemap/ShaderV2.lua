{
    name = "Equirect to Cubemap",

    properties =
    {
        {"equirectMap", "texture"},
    },

    pass =
    {
        renderQueue = "background",
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
            layout(binding = 4) uniform texture2D equirectMap;
            layout(binding = BGFX_SAMPLER_SLOT_4) uniform sampler equirectMapSampler;
            #define SAMPLE_EQUIRECT(uv, lod) textureLod(sampler2D(equirectMap, equirectMapSampler), uv, lod)
            #else
            uniform sampler2D equirectMap;
            #define SAMPLE_EQUIRECT(uv, lod) textureLod(equirectMap, uv, lod)
            #endif

            layout (location = 0) out vec4 fragColor;

            const vec2 invAtan = vec2(0.1591, 0.3183);
            #define PI 3.1415926538

            vec2 sampleSphericalMap(vec3 v)
            {
                float lon = atan(v.z, v.x);
                float lat = acos(v.y);
                vec2 sphereCoords = vec2(lon, lat) * (1.0 / PI);
                vec2 uv = vec2(sphereCoords.x * 0.5 + 0.5, (1 - sphereCoords.y));

                return uv;
            }

            void main()
            {
                vec3 rayDir = normalize(v_eyeDirection);
                vec3 col = SAMPLE_EQUIRECT(sampleSphericalMap(rayDir), 0.0).rgb;

                fragColor = vec4(col, 1.0);
            }
        ]],
    }
}
