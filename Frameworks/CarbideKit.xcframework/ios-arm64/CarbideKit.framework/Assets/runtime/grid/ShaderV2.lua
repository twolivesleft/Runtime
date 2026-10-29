{
    name = "Grid",

    properties =
    {
        {"axisColorX", "vec4", {1.0, 1.0, 1.0, 0.8}, color = true},
        {"axisColorZ", "vec4", {1.0, 1.0, 1.0, 0.8}, color = true},
        {"lineColor", "vec4", {0.735, 0.735, 0.735, 0.8}, color = true},
        {"params", "vec4", {1.0, 1.0, 0.0, 0.0}}
    },

    pass =
    {
        renderQueue = "transparent",
        cullFace = "none",
        depthWrite = false,
        blendMode = "normal",

        vertex =
        [[
            #version 430
            #include <codea/common.glsl>

            #if defined(SPIRV)
            layout(std140, binding = 0) uniform VertexUniforms {
                mat4 u_invViewProj;
            };
            #endif

            layout(location = 1) out vec3 nearPoint;
            layout(location = 2) out vec3 farPoint;

            vec3 gridPlane[6] = vec3[] (
                vec3(1, 1, 0), vec3(-1, -1, 0), vec3(-1, 1, 0),
                vec3(-1, -1, 0), vec3(1, 1, 0), vec3(1, -1, 0)
            );

            vec3 unprojectPoint(float x, float y, float z)
            {
                vec4 unprojectedPoint =  u_invViewProj * vec4(x, y, z, 1.0);
                return unprojectedPoint.xyz / unprojectedPoint.w;
            }

            void main()
            {
                vec3 p = gridPlane[gl_VertexID].xyz;
                nearPoint = unprojectPoint(p.x, p.y, 0.0).xyz; // unprojecting on the near plane
                farPoint = unprojectPoint(p.x, p.y, 1.0).xyz; // unprojecting on the far plane
                gl_Position = vec4(p, 1);
            }
        ]],

        fragment =
        [[
            #version 430
            #include <codea/common.glsl>

            #if defined(SPIRV)
            layout(std140, binding = 0) uniform FragUniforms {
                mat4 u_viewProj;
                mat4 u_proj;
                vec4 axisColorX;
                vec4 axisColorZ;
                vec4 lineColor;
                vec4 params;
            };
            #else
            uniform vec4 axisColorX;
            uniform vec4 axisColorZ;
            uniform vec4 lineColor;
            uniform vec4 params;
            #endif

            layout(location = 1) in vec3 nearPoint; // nearPoint calculated in vertex shader
            layout(location = 2) in vec3 farPoint; // farPoint calculated in vertex shader

            layout (location = 0) out vec4 fragColor;

            float aastep(float threshold, float value)
            {
                float afwidth = length(vec2(dFdx(value), dFdy(value))) * 0.70710678118654757;
                return smoothstep(threshold-afwidth, threshold+afwidth, value);
            }

            vec4 grid(vec3 fragPos3D, float scale, float thickness)
            {
                vec2 coord = fragPos3D.xz * scale;
                vec2 derivative = fwidth(coord) * 1.0f;
                vec2 grid = abs(fract(coord - 0.5) - 0.5) / derivative;
                vec2 line = vec2(aastep(thickness, grid.x), aastep(thickness, grid.y));

                vec4 color = lineColor;

                vec2 index = ceil(coord.yx - 0.5);

                // x axis
                if(index.x == 0.0)
                    color = mix(color, axisColorX, 1.0 - line.y);
                // z axis
                if(index.y == 0.0)
                    color = mix(color, axisColorZ, 1.0 - line.x);

                color.a *= 1.0 - min(line.x, line.y);

                return color;
            }

            float computeDepth(vec3 pos)
            {
                vec4 clip_space_pos = u_viewProj * vec4(pos.xyz, 1.0);
                return (clip_space_pos.z / clip_space_pos.w);
            }

            float computeLinearDepth(vec3 pos)
            {
                vec4 camera_space_pos = u_viewProj * vec4(pos.xyz, 1.0);
                float z = (camera_space_pos.z / camera_space_pos.w);
                return - (z * u_proj[3][3] - u_proj[3][2]) / (z * u_proj[2][3] - u_proj[2][2]);
            }

            void main()
            {
                float t = -nearPoint.y / (farPoint.y - nearPoint.y);
                vec3 fragPos3D = nearPoint + t * (farPoint - nearPoint);

                float linearDepth = clamp(computeLinearDepth(fragPos3D), 0, 200);
                float fading = max(0.0, smoothstep(linearDepth, 200, 150));

                gl_FragDepth = computeDepth(fragPos3D);
                fragColor = grid(fragPos3D, params.x, params.y) * float(t > 0) * fading;
            }
        ]],
    }
}
