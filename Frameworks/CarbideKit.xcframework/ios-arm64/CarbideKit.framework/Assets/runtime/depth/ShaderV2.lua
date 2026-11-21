{
    name = "depth",

    options =
    {
        HAS_SKINNING_OR_MORPHING = {false},
    },

    properties =
    {
        -- Pushes depths back by their slope (x) and a number of the smallest depth steps (y)
        {"polygonOffset", "vec4", {2.0, 0.5, 0.0, 0.0}}
    },

    passes =
    {
        {
            cullFace = "back",
            renderQueue = "shadow",
            depthWrite = true,
            depthFunc = "less",

            vertex =
            [[
                #version 430
                #include <codea/common.glsl>

                #if defined(SPIRV)
                layout(std140, binding = 0) uniform VertexUniforms {
                    mat4 u_modelViewProj;
                    #if defined(HAS_SKINNING_OR_MORPHING)
                    mat4 u_model[BGFX_CONFIG_MAX_BONES];
                    #endif
                };
                #endif

                layout (location = POSITION) in vec3 a_position;
                #if defined(HAS_SKINNING_OR_MORPHING)
                layout (location = INDICES) in uvec4 a_indices;
                layout (location = WEIGHT) in vec4 a_weight;
                #endif

                void main()
                {
                    vec3 position = a_position;
                    #if defined(HAS_SKINNING_OR_MORPHING)
                    // Match surface/getters.vs: slot zero is the model transform,
                    // and each bone's world * inverse-bind matrix starts at one.
                    vec4 vertex = vec4(position, 1.0);
                    position = (u_model[a_indices.x + 1u] * vertex).xyz * a_weight.x
                             + (u_model[a_indices.y + 1u] * vertex).xyz * a_weight.y
                             + (u_model[a_indices.z + 1u] * vertex).xyz * a_weight.z
                             + (u_model[a_indices.w + 1u] * vertex).xyz * a_weight.w;
                    #endif
                    gl_Position = u_modelViewProj * vec4(position, 1.0);
                }
            ]],

            fragment =
            [[
                #version 430
                #include <codea/common.glsl>

                #if defined(SPIRV)
                layout(std140, binding = 0) uniform FragUniforms {
                    vec4 polygonOffset;
                };
                #else
                uniform vec4 polygonOffset;
                #endif

                layout (location = 0) out vec4 FragColor;

                // Stands in for a depth bias, which bgfx doesn't have, so that surfaces don't
                // shadow themselves where they slope away from the light
                void main()
                {
                    float depth = gl_FragCoord.z;
                    float slope = max(abs(dFdx(depth)), abs(dFdy(depth)));
                    gl_FragDepth = depth + slope * polygonOffset.x + polygonOffset.y / 16777216.0;
                }
            ]],
        }
    }
}
