{
    name = "depth",

    options =
    {
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
                };
                #endif

                layout (location = POSITION) in vec3 a_position;

                void main()
                {
                    gl_Position = u_modelViewProj * vec4(a_position, 1.0);
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
