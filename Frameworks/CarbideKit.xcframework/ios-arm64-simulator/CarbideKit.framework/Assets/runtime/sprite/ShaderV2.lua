{
    name = "sprite",

    options =
    {
        TINT_NORMAL = {true},
        TINT_REPLACE = {false},
        TINT_ADD = {false},
        TINT_SCREEN = {false},
        OPACITY_CLIP = {false},
    },

    properties =
    {
        {"tintMode", "uint", 1, onSet = function(shader, v)
            shader:setOption("TINT_NORMAL", v == NORMAL)
            shader:setOption("TINT_REPLACE", v == REPLACE)
            shader:setOption("TINT_ADD", v == ADDITIVE)
            shader:setOption("TINT_SCREEN", v == SCREEN)
        end},
        {"opacityThreshold", "float", 0.0},
        {"opacityClip", "bool", false}
    },

    computedOptions =
    {
        OPACITY_CLIP = function(opacityClip) return opacityClip end,
    },

    passes =
    {
        {
            cullFace = "none",
            renderQueue = "overlay",
            depthWrite = false,
            depthTest = true,
            depthFunc = "less",

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
                    v_color0 = u_tintColor;
                    v_texcoord0 = a_texcoord0;
                }
            ]],

            fragment =
            [[
                #version 430
                #include <codea/common.glsl>

                layout (location = 0) in vec4 v_color0;
                layout (location = 1) in vec2 v_texcoord0;

                #if defined(SPIRV)
                layout(binding = 2) uniform texture2D s_texture;
                layout(binding = BGFX_SAMPLER_SLOT_2) uniform sampler s_textureSampler;
                #define sampleTexture(uv) texture(sampler2D(s_texture, s_textureSampler), uv)
                #else
                #define sampleTexture(uv) texture(s_texture, uv)
                #endif

                layout (location = 0) out vec4 FragColor;

                void applyTint(const vec4 tint, inout vec4 color)
                {
                #if defined(TINT_REPLACE)
                    color.rgb = tint.rgb * color.a;
                    color.a *= tint.a;
                #elif defined(TINT_NORMAL)
                    color *= tint;
                #elif defined(TINT_ADD)
                    color.rgb += tint.rgb;
                    color.a *= tint.a;
                #elif defined(TINT_SCREEN)
                    color.rgb += tint.rgb * (1.0 - color.rgb);
                    color.a *= tint.a;
                #endif
                }

                void main()
                {
                    vec4 color = sampleTexture(v_texcoord0);
                    #ifdef OPACITY_CLIP
                    if (color.a == 0.0) discard;
                    #endif
                    applyTint(v_color0, color);
                    FragColor = color;
                }
            ]],
        }
    }
}
