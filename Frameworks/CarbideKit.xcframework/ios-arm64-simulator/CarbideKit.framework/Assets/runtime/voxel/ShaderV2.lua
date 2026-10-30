{
    name = "Voxel",

    properties =
    {
        {"roughness", "float", 0.9, range = {0,1}},
        {"metallic", "float", 0.0, range = {0,1}},
        {"reflectance", "float", 0.2, range = {0,1}},
        {"emissive", "float", 0.0, range = {0,8}},
        {"occlusionStrength", "float", 0.45, range = {0,1}},
    },

    -- Block types can give their own roughness, metallic and emissive, which replace the material's
    pass =
    {
        shadingModel = "lit",
        detectShadingFeatures = false,

        material =
        [[
            uniform float roughness;
            uniform float metallic;
            uniform float reflectance;
            uniform float emissive;
            uniform float occlusionStrength;

            void material(inout MaterialInputs material)
            {
                prepareMaterial(material);

                #if defined(HAS_VOXELS)
                vec4 color = getVoxelColor();
                material.baseColor = vec4(color.rgb * mix(1.0 - occlusionStrength, 1.0, getVoxelOcclusion()), color.a);
                material.roughness = getVoxelRoughness(roughness);
                material.metallic = getVoxelMetallic(metallic);
                material.reflectance = reflectance;
                material.emissive = vec4(color.rgb * getVoxelEmissive(emissive), 0.0);
                #endif
            }
        ]]
    }
}
