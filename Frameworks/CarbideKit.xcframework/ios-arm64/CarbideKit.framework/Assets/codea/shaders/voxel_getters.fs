// Getters for voxel meshes, which have HAS_VOXELS set when they're drawn. Their uv0 is the position
// within a block face and uv1 is (texture layer, ambient occlusion). vertex_zzVoxel holds the block's
// tint and its surface settings (see BlockSurface::pack), packed as RGBA8

#if defined(HAS_VOXELS)

#define VOXEL_EMISSIVE_RANGE 8.0

// Named to come after every other input (see voxel_inputs.vs)
flat in highp uvec2 vertex_zzVoxel;

// The block textures, bound from the voxel mesh's texture
uniform mediump sampler2DArray voxel_textures;

/**
 * The block's texture tinted by its color. Cutout pixels are discarded and translucent colors are
 * premultiplied by their alpha.
 *
 * @public-api
 */
vec4 getVoxelColor() {
    vec4 color = texture(voxel_textures, vec3(getUV0(), floor(getUV1().x + 0.5))) * unpackUnorm4x8(vertex_zzVoxel.x);
#if defined(VOXEL_CUTOUT)
    if (color.a < 0.5) discard;
    color.a = 1.0;
#endif
#if defined(BLEND_MODE_TRANSPARENT)
    color.rgb *= color.a;
#endif
    return color;
}

/**
 * How open the corner of the block is, from 0 (hemmed in by neighbouring blocks) to 1 (open).
 *
 * @public-api
 */
float getVoxelOcclusion() {
    return getUV1().y;
}

// The block's surface setting in a channel, if the block type gives one
float getVoxelSurface(uint channel, float fallback, float range) {
    bool given = (vertex_zzVoxel.y & (1u << (24u + channel))) != 0u;
    return given ? unpackUnorm4x8(vertex_zzVoxel.y)[channel] * range : fallback;
}

/** @public-api The block type's roughness, or fallback if it doesn't give one */
float getVoxelRoughness(float fallback) {
    return getVoxelSurface(0u, fallback, 1.0);
}

/** @public-api The block type's metallic, or fallback if it doesn't give one */
float getVoxelMetallic(float fallback) {
    return getVoxelSurface(1u, fallback, 1.0);
}

/** @public-api How brightly the block type glows in its own color, or fallback if it doesn't give one */
float getVoxelEmissive(float fallback) {
    return getVoxelSurface(2u, fallback, VOXEL_EMISSIVE_RANGE);
}

#endif
