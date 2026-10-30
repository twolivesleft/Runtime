{
    name = "outlineComposite",

    properties =
    {
        {"scene", "texture"},
        {"sdf", "texture"},
        {"outline", "vec4", {0.95, 0.62, 0.22, 6*6}}
    },

    passes =
    {
        {
            cullFace = "none",
            renderQueue = "overlay",
            depthWrite = false,
            depthTest = "always",

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
                layout (location = TEXCOORD0) in vec2 a_texcoord0;

                layout (location = 0) out vec2 v_texcoord0;

                void main()
                {
                    gl_Position = u_modelViewProj * vec4(a_position, 1.0);
                    v_texcoord0 = a_texcoord0;
                }
            ]],

            fragment =
            [[
                #version 430
                #include <codea/common.glsl>

                layout (location = 0) in vec2 v_texcoord0;

                #if defined(SPIRV)
                layout(std140, binding = 0) uniform FragUniforms {
                    vec4 outline;
                };
                layout(binding = 4) uniform texture2D scene;
                layout(binding = BGFX_SAMPLER_SLOT_4) uniform sampler sceneSampler;
                layout(binding = 5) uniform texture2D sdf;
                layout(binding = BGFX_SAMPLER_SLOT_5) uniform sampler sdfSampler;
                #define SAMPLE_SCENE(uv) texture(sampler2D(scene, sceneSampler), uv)
                #define SAMPLE_SDF(uv) texture(sampler2D(sdf, sdfSampler), uv)
                #define SDF_SIZE() textureSize(sampler2D(sdf, sdfSampler), 0)
                #else
                uniform mediump sampler2D scene;
                uniform mediump sampler2D sdf;
                uniform vec4 outline;
                #define SAMPLE_SCENE(uv) texture(scene, uv)
                #define SAMPLE_SDF(uv) texture(sdf, uv)
                #define SDF_SIZE() textureSize(sdf, 0)
                #endif

                layout (location = 0) out vec4 FragColor;

                void main()
                {
                    mediump vec4 sceneCol = SAMPLE_SCENE(v_texcoord0);
                    mediump vec2 pos = vec2(SAMPLE_SDF(v_texcoord0).xy);
                    if (pos.x == -1)
                    {
                        FragColor = vec4(sceneCol.rgb, 1.0);
                    }
                    else
                    {
                        pos *= SDF_SIZE();
                        vec2 delta = (v_texcoord0 * (SDF_SIZE())) - pos;
                        float d = dot(delta, delta);
                        float afwidth = length(vec2(dFdx(d), dFdy(d))) * 0.70710678118654757;
                        float s1 = smoothstep(1.0 - afwidth, 1.0 + afwidth, d);
                        float s2 = smoothstep(outline.w - afwidth, outline.w + afwidth, d);
                        float o = clamp(s1-s2, 0.0, 1.0);
                        FragColor = vec4(mix(sceneCol.rgb, outline.rgb, o), 1.0);
                    }
                }
            ]],
        }
    }
}
