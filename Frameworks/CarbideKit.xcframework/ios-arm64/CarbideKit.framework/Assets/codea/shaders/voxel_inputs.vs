// The block's tint and surface settings for voxel meshes (see voxel_getters.fs). Stage inputs and
// outputs are given locations in order of their names, counting only those a stage uses, so it's
// named to come last. Fragment shaders that don't use it then leave the others where they are
#if defined(HAS_VOXELS)
flat out highp uvec2 vertex_zzVoxel;
#endif
