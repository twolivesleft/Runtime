{
    name = "mesh",

    options =
    {
        USE_TEXTURE = {false, multicompile = true}
    },

    passes =
    {
        {
            cullFace = "none",
            blendMode = "normal",

            vertex =
            [[
                #version 430
                #include <codea/common.glsl>

                #if defined(SPIRV)
                layout(std140, binding = 0) uniform VertexUniforms {
                    mat4 u_modelViewProj;
                    vec4 u_tintColor;
                };
                #endif

                layout (location = POSITION) in vec3 a_position;
                layout (location = COLOR0) in vec4 a_color0;
                layout (location = TEXCOORD0) in vec2 a_texcoord0;

                layout (location = 0) out vec4 v_color0;
                layout (location = 1) out vec2 v_texcoord0;

                void main()
                {
                    gl_Position = u_modelViewProj * vec4(a_position, 1.0);
                    v_color0 = a_color0 * u_tintColor;
                    v_texcoord0 = a_texcoord0;
                }
            ]],

            fragment =
            [[
                #version 430
                #include <codea/common.glsl>
                #include <codea/colorspace.glsl>

                layout (location = 0) in vec4 v_color0;
                layout (location = 1) in vec2 v_texcoord0;

                #if defined(SPIRV)
                layout(binding = 2) uniform texture2D s_texture;
                layout(binding = BGFX_SAMPLER_SLOT_2) uniform sampler s_textureSampler;
                #endif

                layout (location = 0) out vec4 FragColor;

                void main()
                {
                #ifdef USE_TEXTURE
                    #if defined(SPIRV)
                    FragColor = texture(sampler2D(s_texture, s_textureSampler), v_texcoord0) * toLinear(v_color0);
                    #else
                    FragColor = texture(s_texture, v_texcoord0) * toLinear(v_color0);
                    #endif
                #else
                    FragColor = toLinear(v_color0);
                #endif
                }
            ]],
        }
    }
}
