{
    name = "mesh",

    options =
    {

    },

    properties =
    {
        {"thickness", "float", 1.0},
        {"miter", "int", 1},
    },

    passes =
    {
        {
            renderQueue = "transparent",
            cullFace = "none",
            depthWrite = false,

            vertex =
            [[
                #version 430
                #include <codea/common.glsl>

                #if defined(SPIRV)
                layout(std140, binding = 0) uniform VertexUniforms {
                    mat4 u_modelViewProj;
                    vec4 u_viewRect;
                    float thickness;
                    int miter;
                };
                #else
                uniform float thickness;
                uniform int miter;
                #endif

                layout (location = POSITION) in vec4 a_position;
                layout (location = TEXCOORD0) in vec3 a_texcoord0;
                layout (location = TEXCOORD1) in vec3 a_texcoord1;
                layout (location = COLOR0) in vec4 a_color0;

                layout (location = 0) noperspective out vec4 v_color0;
                layout (location = 1) noperspective out float v_edge;

                void main()
                {
                    vec3 prev = a_texcoord0;
                    vec3 next = a_texcoord1;

                    vec2 aspectVec = vec2(u_viewRect.z / u_viewRect.w, 1.0);
                    vec4 previousProjected = u_modelViewProj * vec4(prev, 1.0);
                    vec4 currentProjected = u_modelViewProj * vec4(a_position.xyz, 1.0);
                    vec4 nextProjected = u_modelViewProj * vec4(next, 1.0);

                    //get 2D screen space with W divide and aspect correction
                    vec2 currentScreen = currentProjected.xy / currentProjected.w * aspectVec;
                    vec2 previousScreen = previousProjected.xy / previousProjected.w * aspectVec;
                    vec2 nextScreen = nextProjected.xy / nextProjected.w * aspectVec;

                    float thicknessNorm = 2.0 * thickness / u_viewRect.w;
                    float len = thicknessNorm;
                    float orientation = a_position.w;

                    v_edge = orientation;

                    //starting point uses (next - current)
                    vec2 dir = vec2(0.0);
                    if (currentScreen == previousScreen)
                    {
                        dir = normalize(nextScreen - currentScreen);
                    }
                    //ending point uses (current - previous)
                    else if (currentScreen == nextScreen)
                    {
                        dir = normalize(currentScreen - previousScreen);
                    }
                    //somewhere in middle, needs a join
                    else
                    {
                        //get directions from (C - B) and (B - A)
                        vec2 dirA = normalize((currentScreen - previousScreen));
                        if (miter == 1)
                        {
                            vec2 dirB = normalize((nextScreen - currentScreen));
                            //now compute the miter join normal and length
                            vec2 tangent = normalize(dirA + dirB);
                            vec2 perp = vec2(-dirA.y, dirA.x);
                            vec2 miter = vec2(-tangent.y, tangent.x);
                            dir = tangent;
                            len = thicknessNorm / dot(miter, perp);
                        }
                        else
                        {
                            dir = dirA;
                        }
                    }
                    vec2 normal = vec2(-dir.y, dir.x);
                    normal *= len/2.0;

                    vec2 offset = vec2(normal * orientation);

                    gl_Position = vec4((currentScreen + offset) / aspectVec * currentProjected.w, currentProjected.z, currentProjected.w);

                    v_color0 = a_color0;
                }
            ]],

            fragment =
            [[
                #version 430
                #include <codea/common.glsl>

                #if defined(SPIRV)
                layout(std140, binding = 0) uniform FragUniforms {
                    float thickness;
                };
                #else
                uniform float thickness;
                #endif

                layout (location = 0) noperspective in vec4 v_color0;
                layout (location = 1) noperspective in float v_edge;

                layout (location = 0) out vec4 FragColor;

                float aastep(float threshold, float value)
                {
                    float afwidth = length(vec2(dFdx(value), dFdy(value))) * 0.70710678118654757;
                    return smoothstep(threshold-afwidth, threshold+afwidth, value);
                }

                void main()
                {
                    float feather = 1.0 - aastep(0.95, abs(v_edge));
                    FragColor = vec4(v_color0.rgb, v_color0.a * feather);
                }
            ]],
        }
    }
}
