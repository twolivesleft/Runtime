{
    name = "Surface",

    options =
    {
        HAS_DIRECTIONAL_LIGHTING = {false},
        HAS_SHADOWING = {false},

        SHADING_MODEL_STANDARD = {false},
        SHADING_MODEL_UNLIT = {false},
        SHADING_MODEL_CLOTH = {false},
        SHADING_MODEL_SUBSURFACE = {false},
        
        MATERIAL_NEEDS_TBN = {false},
        MATERIAL_HAS_CUSTOM_SURFACE_SHADING = {false},
        MATERIAL_HAS_NORMAL = {false},
        MATERIAL_HAS_ANISOTROPY = {false},
        MATERIAL_HAS_AMBIENT_OCCLUSION = {false},
        MATERIAL_HAS_EMISSIVE = {true},
        MATERIAL_HAS_CLEAR_COAT = {false},
        MATERIAL_HAS_CLEAR_COAT_NORMAL = {false},
        MATERIAL_HAS_ABSORBTION = {false},
        MATERIAL_HAS_TRANSMISSION = {false},
        MATERIAL_HAS_MICRO_THICKNESS = {false},
        MATERIAL_HAS_IOR = {false},
        MATERIAL_HAS_DOUBLE_SIDED_CAPABILITY = {false},
        HAS_REFRACTION = {false},
        MATERIAL_HAS_POST_LIGHTING_COLOR = {false},
        POST_LIGHTING_BLEND_MODE_OPAQUE = {false},
        POST_LIGHTING_BLEND_MODE_TRANSPARENT = {false},
        POST_LIGHTING_BLEND_MODE_ADD = {false},
        POST_LIGHTING_BLEND_MODE_MULTIPLY = {false},
        POST_LIGHTING_BLEND_MODE_SCREEN = {false},

        BLEND_MODE_OPAQUE = {false},
        BLEND_MODE_TRANSPARENT = {false},
        BLEND_MODE_ADD = {false},
        BLEND_MODE_MASKED = {false},
        BLEND_MODE_MULTIPLY = {false},
        BLEND_MODE_SCREEN = {false},

        USE_REFRACTION_TYPE_SOLID = {false},
        USE_REFRACTION_TYPE_THIN = {false},
        USE_REFRACTION_MODE_CUBEMAP = {false},
        
        HAS_SKINNING_OR_MORPHING = {false},

        -- Set for voxel meshes, see voxel_getters.fs
        HAS_VOXELS = {false},
        VOXEL_CUTOUT = {false},
    },

    properties =
    {
    },

    includes =
    {
        filament_compat =
        [[
            #define TARGET_MOBILE
            #define VERTEX_DOMAIN_OBJECT
            #define HAS_ATTRIBUTE_TANGENTS
            #define HAS_ATTRIBUTE_UV0
            #define HAS_ATTRIBUTE_UV1

            #define SHADING_INTERPOLATION
            #define LOCATION_POSITION POSITION
            #define LOCATION_NORMAL NORMAL
            #define LOCATION_TANGENTS TANGENT
            #define LOCATION_UV0 TEXCOORD0
            #define LOCATION_UV1 TEXCOORD1

            #define mesh_position a_position
            #define mesh_tangents a_tangent
            #define mesh_normal a_normal
            #define mesh_uv0 a_texcoord0
            #define mesh_uv1 a_texcoord1

            #if defined(HAS_VOXELS)
            #define HAS_ATTRIBUTE_CUSTOM0
            #define LOCATION_CUSTOM0 TEXCOORD2
            #define mesh_custom0 a_texcoord2
            #endif

            #if defined(HAS_ATTRIBUTE_COLOR) || defined(HAS_VOXELS)
            #define LOCATION_COLOR COLOR0
            #define mesh_color a_color0
            #endif

            #if defined(HAS_SKINNING_OR_MORPHING)
            #define HAS_ATTRIBUTE_BONE_INDICES
            #define HAS_ATTRIBUTE_BONE_WEIGHTS
            #define LOCATION_BONE_INDICES INDICES
            #define LOCATION_BONE_WEIGHTS WEIGHT
            #define mesh_bone_indices a_indices
            #define mesh_bone_weights a_weight
            #endif
            
            #undef saturate

            #define frameUniforms_cameraPosition u_cameraPosition
            #define frameUniforms_viewFromWorldMatrix u_view
            #define frameUniforms_worldFromViewMatrix u_invView
            #define frameUniforms_time u_time.x
            #define frameUniforms_userTime u_time
            #define frameUniforms_resolution vec4(u_viewRect.wz, u_viewTexel.xy)
            
            uniform vec4 u_filamentParams[15];
            #define frameUniforms_sun u_filamentParams[3]
            #define frameUniforms_lightDirection u_filamentParams[4].xyz
            #define frameUniforms_shadowBias u_filamentParams[5].xyz
            #define frameUniforms_iblRoughnessOneLevel u_filamentParams[9].x
            #define frameUniforms_lightColorIntensity u_filamentParams[2]
            #define frameUniforms_iblLuminance u_filamentParams[8].y
            #define frameUniforms_directionalShadows floatBitsToUint(u_filamentParams[9].w)
            #define frameUniforms_cascades floatBitsToUint(u_filamentParams[13].w)
            #define frameUniforms_cascadeSplits u_filamentParams[14]
            
            uniform mat4 u_lightFromWorldMatrix[MAX_SHADOW_CASCADES];
            #define frameUniforms_lightFromWorldMatrix u_lightFromWorldMatrix
            
            #define REFRACTION_TYPE_SOLID 1
            #define REFRACTION_TYPE_THIN 2
            #define REFRACTION_MODE_CUBEMAP 1

            #if defined(HAS_REFRACTION)

            #if defined(USE_REFRACTION_TYPE_SOLID)
            #define REFRACTION_TYPE 1
            #elif defined(REFRACTION_TYPE_THIN)
            #define REFRACTION_TYPE 2
            #endif

            #if defined(USE_REFRACTION_MODE_CUBEMAP)
            #define REFRACTION_MODE 1
            #endif
            
            #endif
        ]],

        common =
        [[
            #define MAX_LIGHT_COUNT 8
            #define MAX_SHADOW_CASTING_SPOTS 2
            #define MAX_SHADOW_CASCADES 5

            struct FrameUniforms
            {
                vec4 resolution;
                // directional light
                vec4 lightColorIntensity;
                uint fParamsX;
                
                // shadow
                float oneOverFroxelDimensionY;
                                
                // bit 0: directional (sun) shadow enabled
                // bit 1: directional (sun) screen-space contact shadow enabled
                // bit 8-15: screen-space contact shadows ray casting steps
                uint directionalShadows;
                uint cascades;
                
                // TODO:
                // froxels
                // TODO
                // froxels (again)
                // ibl
                float iblLuminance;
                vec3 iblSH[9];
                // camera
                float exposure;
                float ev100;
                // ibl max mip level
                // view
                vec3 worldOffset;
                float ssContactShadowDistance;
                // fog
                // more camera stuff
                // CSM
            };

            struct ObjectUniforms
            {
                int skinningEnabled; // 0=disabled, 1=enabled, ignored unless variant & SKINNING_OR_MORPHING
                int morphingEnabled; // 0=disabled, 1=enabled, ignored unless variant & SKINNING_OR_MORPHING
                uint screenSpaceContactShadows; // 0=disabled, 1=enabled, ignored unless variant & SKINNING_OR_MORPHING
            };

            struct LightsUniforms
            {
                mat4 lights[MAX_LIGHT_COUNT];
            };

            struct ShadowUniforms
            {
                mat4 spotLightFromWorldMatrix[MAX_SHADOW_CASTING_SPOTS];
                vec4 directionShadowBias[MAX_SHADOW_CASTING_SPOTS];
            };

            FrameUniforms frameUniforms;
            ObjectUniforms objectUniforms;
            ShadowUniforms shadowUniforms;
            LightsUniforms lightsUniforms;
        ]],

        init_structs =
        [[
            frameUniforms.iblSH[0].x = 65504.0;
            frameUniforms.iblLuminance = frameUniforms_iblLuminance;
            frameUniforms.exposure = 1;
            frameUniforms.ev100 = 1;
            frameUniforms.worldOffset = vec3(0);
            
            #if defined(HAS_SHADOWING)
            frameUniforms.directionalShadows = frameUniforms_directionalShadows;
            frameUniforms.ssContactShadowDistance = 0u;
            frameUniforms.cascades = frameUniforms_cascades;
            #endif
            
            #if defined(HAS_SKINNING_OR_MORPHING)
            // TODO: expose these options outside the shader
            objectUniforms.skinningEnabled = 1;
            objectUniforms.morphingEnabled = 0;
            #else
            objectUniforms.skinningEnabled = 0;
            objectUniforms.morphingEnabled = 0;
            #endif
        ]],

        user_vertex = "void materialVertex(inout MaterialVertexInputs material) {}",
        user_material = "void material(inout MaterialInputs material) {prepareMaterial(material);}",
        user_shading = "void surfaceShading(const MaterialInputs materialInputs, const ShadingData shadingData, const LightData lightData",
        user_vertex_variables = "",
        user_fragment_variables = ""
    },

    passes =
    {
        {
            cullFace = "back",
            depthWrite = true,
            depthFunc = "greater",
            blendMode = "disabled",

            vertex =
            [[
                #version 430
                #include <codea/common.glsl>
                #include "common.glsl"
                #include "filament_config.glsl"
                #include "filament_compat.glsl"
                
                #include <codea/shaders/common_types.fs>
                #include <codea/shaders/common_math.fs>
                #include <codea/shaders/common_shadowing.fs>
                #include <codea/shaders/inputs.vs>

                #include <codea/shaders/common_getters.fs>
                #include <codea/shaders/getters.vs>
                #include <codea/shaders/material_inputs.vs>

                #include "user_vertex_variables.glsl"
                #include "user_vertex.glsl"
                #include <codea/shaders/voxel_inputs.vs>

                #include <codea/shaders/main.vs>
            ]],

            fragment =
            [[
                #version 430
                #include <codea/common.glsl>
                #include "common.glsl"
                #include "filament_config.glsl"
                #include "filament_compat.glsl"

                #include <codea/shaders/common_types.fs>
                #include <codea/shaders/common_math.fs>
                #include <codea/shaders/inputs.fs>

                #include <codea/shaders/common_lighting.fs>
                #include <codea/shaders/common_shading.fs>
                #include <codea/shaders/common_shadowing.fs>
                #include <codea/shaders/common_getters.fs>
                #include <codea/shaders/common_graphics.fs>
                #include <codea/shaders/common_material.fs>

                #include <codea/shaders/getters.fs>
                #include <codea/shaders/material_inputs.fs>
                #include <codea/shaders/shading_parameters.fs>

                #if defined(HAS_SHADOWING)
                #if defined(CODEA_EMULATE_SHADOW_COMPARE)
                #define CODEA_SHADOW_SAMPLER sampler2DArray
                #else
                #define CODEA_SHADOW_SAMPLER sampler2DArrayShadow
                #endif
                uniform highp CODEA_SHADOW_SAMPLER light_shadowMap;
                uniform sampler2D light_structure;
                #include <codea/shaders/shadowing.fs>
                #endif
                
                #if defined(SHADING_MODEL_UNLIT)
                #include <codea/shaders/shading_unlit.fs>
                #endif
                #if defined(SHADING_MODEL_STANDARD) || defined(SHADING_MODEL_CLOTH) || defined(SHADING_MODEL_SUBSURFACE)
                uniform sampler2D light_iblDFG;
                uniform samplerCube light_iblSpecular;

                #include <codea/shaders/brdf.fs>
                #include <codea/shaders/ambient_occlusion.fs>
                #if defined(MATERIAL_HAS_CUSTOM_SURFACE_SHADING)
                    #include "user_shading.glsl"
                    #include <codea/shaders/shading_lit_custom.fs>
                #elif defined(SHADING_MODEL_CLOTH)
                    #include <codea/shaders/shading_model_cloth.fs>
                #elif defined(SHADING_MODEL_SUBSURFACE)
                    #include <codea/shaders/shading_model_subsurface.fs>
                #else
                    #include <codea/shaders/shading_model_standard.fs>
                #endif
                #include <codea/shaders/light_indirect.fs>
                #include <codea/shaders/light_directional.fs>
                #include <codea/shaders/shading_lit.fs>
                #endif

                #include "user_fragment_variables.glsl"
                #include <codea/shaders/voxel_getters.fs>
                #include "user_material.glsl"

                #include <codea/shaders/main.fs>
            ]],
        },
        
        {
            passType = "depth",
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

                layout (location = 0) out vec4 FragColor;

                void main()
                {
                }
            ]],
        }
    }
}
