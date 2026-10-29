{
    options =
    {
        INIT = {false, multicompile = true},
    },

    properties =
    {
        {"mask", "image2D"},
        {"imageIn", "image2D"},
        {"imageOut", "image2D"},
        {"steps", "float", 1}
    },

    pass =
    {
        compute = [[
            #version 430
            #include <codea/common.glsl>

            layout(r8) uniform image2D mask;
            layout(rg16_snorm) uniform image2D imageIn;
            layout(rg16_snorm) uniform image2D imageOut;

            #if defined(SPIRV)
            layout(std140, binding = 0) uniform ComputeUniforms {
                float steps;
            };
            #else
            uniform float steps;
            #endif

            #ifdef INIT

            // Initialise imageOut with mask input
            NUM_THREADS(32, 16, 1)
            void main()
            {
                uvec2 size = imageSize(imageOut);
                ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);

                if (any(greaterThanEqual(pixel.xy, size))) return;

                float maskValue = imageLoad(mask, pixel).r;
                vec4 value = vec4(vec2(pixel) / vec2(size), 0.0, 0.0);

                if (maskValue < 0.5) value = vec4(-1.0, -1.0, 0.0, 0.0);
                imageStore(imageOut, pixel, value);
            }

            #else

            vec2 sampleImage(ivec2 pos)
            {
                return imageLoad(imageIn, pos).rg;
            }

            // Jump Point Search Iteration
            NUM_THREADS(32, 16, 1)
            void main()
            {
                uvec2 size = imageSize(imageIn);
                ivec2 id = ivec2(gl_GlobalInvocationID.xy);

                if (any(greaterThanEqual(id.xy, size))) return;

                vec3 d = ivec3(1, -1, 0);
                vec2 offset[9] =
                {
                    vec2(id),
                    vec2(id) - d.xx * steps, // -1,-1
                    vec2(id) - d.zx * steps, // 0, -1
                    vec2(id) - d.yx * steps, // +1, -1
                    vec2(id) - d.xz * steps, // -1, 0
                    vec2(id) + d.xz * steps, // +1, 0
                    vec2(id) + d.yx * steps, // -1, +1
                    vec2(id) + d.zx * steps, // 0, +1
                    vec2(id) + d.xx * steps, // +1, +1
                };

                vec2 minPos = vec2(-1, -1);
                float minDist = -1;
                for (int i = 0; i < 9; i++)
                {
                    vec2 o = offset[i];
                    if (all(greaterThan(o.xy, vec2(0,0))) && all(lessThan(o.xy, vec2(size))))
                    {
                        vec2 n = sampleImage(ivec2(o)) * vec2(size);
                        vec2 delta = n - vec2(id);
                        float dist = dot(delta, delta);

                        if (n.x != -1 && (minDist == -1 || dist < minDist))
                        {
                            minDist = dist;
                            minPos = n;
                        }
                    }
                }
                imageStore(imageOut, id, vec4(minPos / vec2(size), 0.0, 0.0));
            }
            #endif

        ]]
    }
}
