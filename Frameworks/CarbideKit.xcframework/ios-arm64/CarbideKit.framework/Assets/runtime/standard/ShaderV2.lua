{
    name = "Standard",

    options =
    {
        HAS_BASE_COLOR_MAP = {false},
        HAS_EMISSIVE_MAP = {false},
        HAS_ROUGHNESS_MAP = {false},
        HAS_NORMAL_MAP = {false},
        HAS_METALLIC_MAP = {false},
        HAS_REFLECTANCE_MAP = {false},
        HAS_CLEAR_COAT_MAP = {false},
        HAS_ANISOTROPY_MAP = {false},
        HAS_ANISOTROPY_DIRECTION_MAP = {false},
        HAS_HEIGHT_MAP = {false},
        HAS_OCCLUSION_MAP = {false},
        HAS_COMBINED_METALLIC_ROUGHNESS_MAPS = {false},
        MATERIAL_HAS_EMISSIVE = {true},
    },

    -- Compute current set of options based on logic derived from property values
    computedOptions =
    {
        HAS_BASE_COLOR_MAP = function(map) return map ~= nil end,
        HAS_EMISSIVE_MAP = function(emissiveMap) return emissiveMap ~= nil end,
        HAS_ROUGHNESS_MAP = function(roughnessMap) return roughnessMap ~= nil end,
        HAS_METALLIC_MAP = function(metallicMap) return metallicMap ~= nil end,
        HAS_NORMAL_MAP = function(normalMap) return normalMap ~= nil end,
        HAS_OCCLUSION_MAP = function(occlusionMap) return occlusionMap ~= nil end,
        HAS_HEIGHT_MAP = function(heightMap) return heightMap ~= nil end,
        MATERIAL_HAS_NORMAL = function(normalMap) return normalMap ~= nil end,
        -- Tangent matrix needed by material if anisotropy or normal mapping are enabled, compute with lua function
        MATERIAL_NEEDS_TBN = function(enableAnisotropy, normalMap)
            return enableAnisotropy or normalMap ~= nil
        end,
        MATERIAL_HAS_ANISOTROPY = function(enableAnisotropy) return enableAnisotropy end,
        HAS_ANISOTROPY_DIRECTION_MAP = function(anisotropyDirectionMap) return anisotropyDirectionMap ~= nil end,
        MATERIAL_HAS_CLEAR_COAT = function(enableClearCoat) return enableClearCoat end,
        -- MATERIAL_HAS_CLEAR_COAT_NORMAL
        HAS_REFRACTION = function(enableRefraction) return enableRefraction end,
        MATERIAL_HAS_IOR = function(enableRefraction) return enableRefraction end,
        MATERIAL_HAS_TRANSMISSION = function(enableTransmission) return enableTransmission end,
        MATERIAL_HAS_ABSORPTION = function(enableAbsorption) return enableAbsorption end,
        MATERIAL_HAS_POST_LIGHTING_COLOR = function(tintBlend)
            return tintBlend ~= 1
        end,
        HAS_COMBINED_METALLIC_ROUGHNESS_MAPS = function(hasCombinedMetallicRoughnessMaps)
            return hasCombinedMetallicRoughnessMaps
        end,
        MATERIAL_HAS_AMBIENT_OCCLUSION = function(occlusionMap, hasCombinedMetallicRoughnessMaps)
            return hasCombinedMetallicRoughnessMaps or (occlusionMap ~= nil)
        end,
    },

    properties =
    {
        {"shadingModel", "uint", 2, enum = {"Unlit", "Lit", "Cloth", "Subsurface"}, onSet = function(shader, v)
            shader:setOption("SHADING_MODEL_UNLIT", v == 1)
            shader:setOption("SHADING_MODEL_STANDARD", v == 2)
            shader:setOption("SHADING_MODEL_CLOTH", v == 3)
            shader:setOption("SHADING_MODEL_SUBSURFACE", v == 4)
        end},

        {"blend", "uint", 1, enum = {"Opaque", "Transparent", "Add", "Masked", "Multiply", "Screen"}, onSet = function(shader, v)

            shader:setOption("BLEND_MODE_OPAQUE", v == 1)
            shader:setOption("BLEND_MODE_TRANSPARENT", v == 2)
            shader:setOption("BLEND_MODE_ADD", v == 3)
            shader:setOption("BLEND_MODE_MASKED", v == 4)
            shader:setOption("BLEND_MODE_MULTIPLY", v == 5)
            shader:setOption("BLEND_MODE_SCREEN", v == 6)

            local pass = shader:pass(1)

            if v == 1 or v == 4 then
                pass.blendMode = DISABLED
                pass.depthWrite = DEPTH_WRITE_ENABLED
            elseif v == 2 then
                pass.blendMode = PREMULTIPLIED
                pass.depthWrite = DEPTH_WRITE_DISABLED
            elseif v == 3 then
                pass.blendMode = ADDITIVE
                pass.depthWrite = DEPTH_WRITE_DISABLED
            elseif v == 5 then
                pass.blendMode = MULTIPLY
                pass.depthWrite = DEPTH_WRITE_DISABLED
            elseif v == 6 then
                pass.blendMode = SCREEN
                pass.depthWrite = DEPTH_WRITE_DISABLED
            end
        end},

        {"tintBlend", "uint", 1, enum = {"None", "Opaque", "Transparent", "Add", "Multiply", "Screen"}, onSet = function(shader, v)
            shader:setOption("POST_LIGHTING_BLEND_MODE_OPAQUE", v == 2)
            shader:setOption("POST_LIGHTING_BLEND_MODE_TRANSPARENT", v == 3)
            shader:setOption("POST_LIGHTING_BLEND_MODE_ADD", v == 4)
            shader:setOption("POST_LIGHTING_BLEND_MODE_MULTIPLY", v == 5)
            shader:setOption("POST_LIGHTING_BLEND_MODE_SCREEN", v == 6)
        end},

        {"tintColor", "vec4", {0,0,0,0}, color = true, visible = function(shader)
            return shader.tintBlend ~= 1
        end},

        {"map", "texture"},
        {"emissiveMap", "texture"},
        {"emissive", "vec4", {0,0,0,0}, color = true, hdr = true},
        {"scaleOffset", "vec4", {1,1,0,0}},
        {"color", "vec4", {1,1,1,1}, color = true, alias = "diffuse"},
        {"roughnessMap", "texture"},
        {"roughness", "float", 0.4, range = {0,1}},
        {"normalMap", "texture"},
        {"metallicMap", "texture"},
        {"metallic", "float", 0.0, range = {0,1}},
        {"reflectance", "float", 0.5, range = {0,1}},
        {"enableClearCoat", "bool", false},
        {"clearCoat", "vec2", {0.0, 0.0}, range = {0,1}},
        {"enableAnisotropy", "bool", false},
        {"anisotropy", "float", 0.0, range = {-1,1}, visible = function(shader)
            return shader.enableAnisotropy
        end},
        {"anisotropyDirection", "vec3", {1.0, 0.0, 0.0}, visible = function(shader)
            return shader.enableAnisotropy
        end},
        {"anisotropyDirectionMap", "texture", visible = function(shader)
            return shader.enableAnisotropy
        end},
        {"heightMap", "texture"},
        {"heightScale", "float", 0.0},
        {"occlusionMap", "texture"},
        {"enableRefraction", "bool", false, onSet = function(shader, v)
            if v then
                shader.refractionMode = 1
            end
        end},
        {"ior", "float", 1.5, visible = function(shader)
            return shader.enableRefraction
        end},
        {"refractionType", "uint", 1, enum = {"Solid", "Thin"}, onSet = function(shader, v)
            shader:setOption("USE_REFRACTION_TYPE_SOLID", v == 1)
            shader:setOption("USE_REFRACTION_TYPE_THIN", v == 2)
        end, visible = function(shader)
            return shader.enableRefraction
        end},
        {"refractionMode", "uint", 1, enum = {"Environment", "Scene"}, onSet = function(shader, v)
            shader:setOption("USE_REFRACTION_MODE_CUBEMAP", v == 1)
        end, visible = function(shader)
            return shader.enableRefraction
        end},
        {"enableTransmission", "bool", false, visible = function(shader)
            return shader.enableRefraction
        end},
        {"transmission", "float", 1.0, range = {0,1}, visible = function(shader)
            return shader.enableRefraction and shader.enableTransmission
        end},
        {"enableAbsorption", "bool", false, visible = function(shader)
            return shader.enableRefraction
        end},
        {"absorption", "vec4", {0.0, 0.0, 0.0, 0.0}, color = true, visible = function(shader)
            return shader.enableRefraction and shader.enableAbsorption
        end},
        {"hasCombinedMetallicRoughnessMaps", "bool", false}
    },

    pass =
    {
        shadingModel = "lit",
        detectShadingFeatures = false,

        vertex =
        [[
            #if defined(HAS_HEIGHT_MAP)
            layout(binding=0) uniform sampler2D heightMap;
            uniform vec4 scaleOffset;
            uniform float heightScale;
            #endif

            void materialVertex(inout MaterialVertexInputs material)
            {
                #if defined(HAS_HEIGHT_MAP)
                    vec2 uv =  material.uv0 * scaleOffset.xy + scaleOffset.zw;
                    material.worldPosition.xyz += material.worldNormal * texture(heightMap, uv).x * heightScale;
                #endif
            }
        ]],

        material =
        [[
            #if defined(HAS_BASE_COLOR_MAP)
            layout(binding=1) uniform sampler2D map;
            #endif
            #if defined(HAS_METALLIC_MAP)
            layout(binding=2) uniform sampler2D metallicMap;
            #endif
            #if defined(HAS_ROUGHNESS_MAP) && !defined(HAS_COMBINED_METALLIC_ROUGHNESS_MAPS)
            layout(binding=3) uniform sampler2D roughnessMap;
            #endif
            #if defined(HAS_NORMAL_MAP)
            layout(binding=4) uniform sampler2D normalMap;
            #endif
            #if defined(HAS_EMISSIVE_MAP)
            layout(binding=5) uniform sampler2D emissiveMap;
            #endif
            #if defined (HAS_OCCLUSION_MAP) && !defined(HAS_COMBINED_METALLIC_ROUGHNESS_MAPS)
            layout(binding=6) uniform sampler2D occlusionMap;
            #endif
            #if defined(HAS_ANISOTROPY_DIRECTION_MAP)
            layout(binding=7) uniform sampler2D anisotropyDirectionMap;
            #endif

            uniform vec4 scaleOffset;
            uniform vec4 color;
            uniform vec4 emissive;

            uniform float roughness;
            uniform float metallic;
            uniform float reflectance;
            #if defined(MATERIAL_HAS_CLEAR_COAT)
            uniform vec2 clearCoat;
            #endif
            #if defined(MATERIAL_HAS_ANISOTROPY)
            uniform float anisotropy;
            uniform vec3 anisotropyDirection;
            #endif
            #if defined(HAS_REFRACTION)
            #if defined(MATERIAL_HAS_TRANSMISSION)
            uniform float transmission;
            #endif
            #if defined(MATERIAL_HAS_ABSORPTION)
            uniform vec4 absorption;
            #endif
            #if defined(MATERIAL_HAS_IOR)
            uniform float ior;
            #endif
            #endif

            #if defined(MATERIAL_HAS_POST_LIGHTING_COLOR)
            uniform vec4 tintColor;
            #endif

            // Every shading model except unlit goes through the lit pipeline
            #if defined(SHADING_MODEL_STANDARD) || defined(SHADING_MODEL_CLOTH) || defined(SHADING_MODEL_SUBSURFACE)
            #define MATERIAL_IS_LIT
            #endif

            void material(inout MaterialInputs material)
            {
                vec2 uv = getUV0() * scaleOffset.xy + scaleOffset.zw;

                #if defined(MATERIAL_IS_LIT)
                #if defined(HAS_NORMAL_MAP)
                material.normal = texture(normalMap, uv).xyz * 2.0 - 1.0;
                material.normal.y *= -1;
                #endif

                prepareMaterial(material);
                #endif

                #if defined(MATERIAL_HAS_POST_LIGHTING_COLOR)
                    material.postLightingColor = tintColor;
                #endif

                material.baseColor = color;
                #if defined(HAS_BASE_COLOR_MAP)
                    material.baseColor *= texture(map, uv);
                #endif
                
                material.emissive = emissive;
                #if defined(HAS_EMISSIVE_MAP)
                    material.emissive.rgb += texture(emissiveMap, uv).rgb;
                #endif

                #if defined(BLEND_MODE_TRANSPARENT)
                    material.baseColor.rgb *= material.baseColor.a;
                #endif

                #if defined(MATERIAL_IS_LIT)
                material.roughness = roughness;
                // Cloth has a sheen in place of metallic and reflectance
                #if !defined(SHADING_MODEL_CLOTH)
                material.metallic = metallic;
                #endif
                
                #if defined(HAS_COMBINED_METALLIC_ROUGHNESS_MAPS)
                    vec3 maskMap = texture(metallicMap, uv).rgb;
                    material.ambientOcclusion = maskMap.r;
                    material.roughness *= maskMap.g;
                    #if !defined(SHADING_MODEL_CLOTH)
                    material.metallic *= maskMap.b;
                    #endif
                #else
                    #if defined(HAS_METALLIC_MAP) && !defined(SHADING_MODEL_CLOTH)
                        material.metallic *= texture(metallicMap, uv).r;
                    #endif
                    #if defined(HAS_ROUGHNESS_MAP)
                        material.roughness *= texture(roughnessMap, uv).r;
                    #endif
                    #if defined(HAS_OCCLUSION_MAP)
                        material.ambientOcclusion = texture(occlusionMap, uv).r;
                    #endif
                #endif
                
                #if !defined(SHADING_MODEL_CLOTH)
                material.reflectance = reflectance;
                #endif

                #if defined(MATERIAL_HAS_CLEAR_COAT)
                material.clearCoat = clearCoat.x;
                material.clearCoatRoughness = clearCoat.y;
                #endif
                #if defined(MATERIAL_HAS_ANISOTROPY)
                material.anisotropy = anisotropy;
                #if defined(HAS_ANISOTROPY_DIRECTION_MAP)
                    material.anisotropyDirection = texture(anisotropyDirectionMap, uv).rgb * 2.0 - 1.0;
                #else
                    material.anisotropyDirection = anisotropyDirection;
                #endif
                #endif
                #if defined(HAS_REFRACTION)
                #if defined(MATERIAL_HAS_TRANSMISSION)
                material.transmission = transmission;
                #endif
                #if defined(MATERIAL_HAS_ABSORPTION)
                material.absorption = absorption.rgb;
                #endif
                #if defined(MATERIAL_HAS_IOR)
                material.ior = ior;
                #endif
                #endif
                #endif
            }
        ]]
    }
}
