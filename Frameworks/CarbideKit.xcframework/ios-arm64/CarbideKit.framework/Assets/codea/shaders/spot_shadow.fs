// Spot projection and distance-scaled normal bias follow Godot's scene_forward_lights_inc.glsl.
// Adapted to Carbide's forward depth and bounded atlas tiles; see GODOT-SHADOW-LICENSE.txt.
uniform highp sampler2D light_spotShadowMap;
// Keep array lengths in sync with ShadowAtlas::MaxSlots.
uniform highp mat4 light_spotTextureFromWorld[16];
uniform highp vec4 light_spotShadowParams[16];
uniform highp vec4 light_spotShadowRects[16];

float spotShadowVisibility(const Light light) {
    highp vec4 params = light_spotShadowParams[light.shadowIndex];
    highp vec4 rect = light_spotShadowRects[light.shadowIndex];
    highp float distanceToLight = length(light.worldPosition - vertex_worldPosition);
    highp vec3 normalBias = shading_normal * distanceToLight * params.y *
        (1.0 - abs(dot(shading_normal, light.l)));
    highp vec4 projected = light_spotTextureFromWorld[light.shadowIndex] * vec4(vertex_worldPosition + normalBias, 1.0);
    if (projected.w <= 0.0) return 1.0;
    highp vec3 coord = projected.xyz / projected.w;
    if (any(lessThan(coord, vec3(0.0))) || any(greaterThan(coord, vec3(1.0)))) return 1.0;
    highp float depth = max(0.0, coord.z - params.x);

    // Compare four texels, then interpolate visibility. This also works on backends
    // without comparison samplers and clamps the kernel at the cone's map boundary.
    // Rectangles are integer pixel coordinates: origin.xy, extent.zw. Clamping
    // to this tile prevents the PCF kernel from reading a neighboring spotlight.
    ivec2 minimum = ivec2(rect.xy);
    ivec2 maximum = minimum + ivec2(rect.zw) - 1;
    highp vec2 texel = rect.xy + coord.xy * rect.zw - 0.5;
    ivec2 base = ivec2(floor(texel));
    vec2 weight = fract(texel);
    ivec2 lo = clamp(base, minimum, maximum);
    ivec2 hi = clamp(base + 1, minimum, maximum);
    float a = step(depth, texelFetch(light_spotShadowMap, ivec2(lo.x, lo.y), 0).r);
    float b = step(depth, texelFetch(light_spotShadowMap, ivec2(hi.x, lo.y), 0).r);
    float c = step(depth, texelFetch(light_spotShadowMap, ivec2(lo.x, hi.y), 0).r);
    float d = step(depth, texelFetch(light_spotShadowMap, ivec2(hi.x, hi.y), 0).r);
    return mix(mix(a, b, weight.x), mix(c, d, weight.x), weight.y);
}
