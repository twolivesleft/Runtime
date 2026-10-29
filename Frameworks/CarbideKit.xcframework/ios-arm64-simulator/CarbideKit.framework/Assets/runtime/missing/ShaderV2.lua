{
    name = "Missing",

    options =
    {
        USE_TEXTURE = {false, multicompile = true}
    },

    passes =
    {
        {
            cullFace = "none",

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

                layout (location = 0) out vec4 FragColor;

                void main()
                {
                    FragColor = vec4(1.0, 0.0, 1.0, 1.0);
                }
            ]],
        }
    }
}
