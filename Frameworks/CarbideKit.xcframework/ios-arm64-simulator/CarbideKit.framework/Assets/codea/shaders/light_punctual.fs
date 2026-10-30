//------------------------------------------------------------------------------
// Punctual lights evaluation
//------------------------------------------------------------------------------

// The lights are binned into a grid of froxels (screen tiles split into depth
// slices) on the CPU, see LightGrid.cpp. Everything is packed into one float
// texture, light_froxels, LIGHT_GRID_WIDTH texels wide:
//
//  * From texel 0, one texel per froxel: the first record (x) and the count (y)
//  * From LIGHT_GRID_RECORDS, the records: light indices, four to a texel
//  * From LIGHT_GRID_LIGHTS, four texels per light
//
// Make sure these match the constants in LightGrid.hpp
#define LIGHT_GRID_WIDTH_SHIFT      7
#define LIGHT_GRID_WIDTH_MASK       127
#define LIGHT_GRID_RECORDS          8192
#define LIGHT_GRID_LIGHTS           16384

#define LIGHT_TYPE_POINT            0u
#define LIGHT_TYPE_SPOT             1u

// The grid's size in tiles and slices (xyz), and how clip space z gives depth (w)
#define frameUniforms_froxelGrid u_filamentParams[7]
// Maps depth to a slice (xy). Perspective views slice log2 of depth, which is clip
// space w (z is 1), orthographic ones slice depth itself, from clip space z and an
// offset (w)
#define frameUniforms_froxelZ u_filamentParams[6]

highp vec4 lightGridTexel(int index) {
    return texelFetch(light_froxels, ivec2(index & LIGHT_GRID_WIDTH_MASK, index >> LIGHT_GRID_WIDTH_SHIFT), 0);
}

struct FroxelParams {
    uint recordOffset; // offset at which the list of lights for this froxel starts
    uint count;   // number lights in this froxel
};

/**
 * Returns the index of the froxel containing a fragment, from its clip space position.
 * The tile comes from where it lands on screen, and the slice from its depth.
 */
uint getFroxelIndex(const highp vec4 clip) {
    highp vec4 grid = frameUniforms_froxelGrid;
    highp vec4 slicing = frameUniforms_froxelZ;

    highp vec2 tile = (clip.xy / clip.w * 0.5 + 0.5) * grid.xy;
    highp float depth = clip.z * grid.w + clip.w * slicing.z + slicing.w;
    highp float slice = (slicing.z > 0.5 ? log2(max(depth, 1e-4)) : depth) * slicing.x + slicing.y;

    uvec3 froxel = uvec3(clamp(floor(vec3(tile, slice)), vec3(0.0), grid.xyz - 1.0));
    uint tilesX = uint(grid.x);
    return froxel.x + froxel.y * tilesX + froxel.z * tilesX * uint(grid.y);
}

FroxelParams getFroxelParams(uint froxelIndex) {
    highp vec4 entry = lightGridTexel(int(froxelIndex));

    FroxelParams froxel;
    froxel.recordOffset = uint(entry.x);
    froxel.count = uint(entry.y);
    return froxel;
}

/**
 * Returns the index of the light in a record
 */
uint getRecord(uint index) {
    highp vec4 records = lightGridTexel(LIGHT_GRID_RECORDS + int(index >> 2u));
    return uint(records[index & 3u]);
}

float getSquareFalloffAttenuation(float distanceSquare, float falloff) {
    float factor = distanceSquare * falloff;
    float smoothFactor = saturate(1.0 - factor * factor);
    // We would normally divide by the square distance here
    // but we do it at the call site
    return smoothFactor * smoothFactor;
}

float getDistanceAttenuation(const highp vec3 posToLight, float falloff) {
    float distanceSquare = dot(posToLight, posToLight);
    float attenuation = getSquareFalloffAttenuation(distanceSquare, falloff);
    // Assume a punctual light occupies a volume of 1cm to avoid a division by 0
    return attenuation * 1.0 / max(distanceSquare, 1e-4);
}

float getAngleAttenuation(const vec3 lightDir, const vec3 l, const vec2 scaleOffset) {
    float cd = dot(lightDir, l);
    float attenuation = saturate(cd * scaleOffset.x + scaleOffset.y);
    return attenuation * attenuation;
}

/**
 * Returns a Light structure (see common_lighting.fs) describing a point or spot light.
 * The colorIntensity field will store the *pre-exposed* intensity of the light
 * in the w component.
 */
Light getLight(const uint index) {

    // retrieve the light data from the light grid
    int lightTexel = LIGHT_GRID_LIGHTS + int(getRecord(index)) * 4;
    highp vec4 positionFalloff       = lightGridTexel(lightTexel);
    highp vec4 colorIntensity        = lightGridTexel(lightTexel + 1);
          vec4 direction             = lightGridTexel(lightTexel + 2);
    highp vec4 scaleOffsetType       = lightGridTexel(lightTexel + 3);

    // position-to-light vector
    highp vec3 worldPosition = vertex_worldPosition;
    highp vec3 posToLight = positionFalloff.xyz - worldPosition;

    // and populate the Light structure
    Light light;
    light.colorIntensity.rgb = colorIntensity.rgb;
    light.colorIntensity.w = computePreExposedIntensity(colorIntensity.w, frameUniforms.exposure);
    light.l = normalize(posToLight);
    light.attenuation = getDistanceAttenuation(posToLight, positionFalloff.w);
    light.NoL = saturate(dot(shading_normal, light.l));
    light.worldPosition = positionFalloff.xyz;
    light.castsShadows = false;
    light.contactShadows = false;
    light.shadowIndex = 0u;
    light.shadowLayer = 0u;

    if (uint(scaleOffsetType.w) == LIGHT_TYPE_SPOT) {
        light.attenuation *= getAngleAttenuation(-direction.xyz, light.l, scaleOffsetType.xy);
    }

    return light;
}

/**
 * Evaluates all punctual lights that my affect the current fragment.
 * The result of the lighting computations is accumulated in the color
 * parameter, as linear HDR RGB.
 */
void evaluatePunctualLights(const MaterialInputs material, const PixelParams pixel, inout vec3 color) {
    // Fetch the light information stored in the froxel that contains the
    // current fragment
    FroxelParams froxel = getFroxelParams(getFroxelIndex(vertex_position));

    // Each froxel contains how many lights can influence
    // the current fragment. A froxel also contains a record offset that
    // tells us where the indices of those lights are in the records
    // section of the light grid

    uint index = froxel.recordOffset;
    uint end = index + froxel.count;

    // Iterate point lights
    for ( ; index < end; index++) {
        Light light = getLight(index);
        float visibility = 1.0;
#if defined(MATERIAL_CAN_SKIP_LIGHTING)
        if (light.NoL <= 0.0) {
            continue;
        }
#endif

#if defined(MATERIAL_HAS_CUSTOM_SURFACE_SHADING)
        color.rgb += customSurfaceShading(material, pixel, light, visibility);
#else
        color.rgb += surfaceShading(pixel, light, visibility);
#endif
    }
}
