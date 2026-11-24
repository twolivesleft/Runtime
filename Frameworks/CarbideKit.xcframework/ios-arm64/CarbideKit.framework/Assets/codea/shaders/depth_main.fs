// Material evaluation is shared with color rendering, including custom discard.
uniform vec4 shadowDepthBias;

void main() {
    #include <init_structs.glsl>
    computeShadingParams();
    MaterialInputs inputs;
    initMaterial(inputs);
    material(inputs);

#if defined(BLEND_MODE_MASKED)
#if defined(SHADING_MODEL_UNLIT)
    if (inputs.baseColor.a < getMaskThreshold()) discard;
#else
    // Match the lit color pass's derivative-smoothed threshold.
    float alpha = (inputs.baseColor.a - getMaskThreshold()) / max(fwidth(inputs.baseColor.a), 1e-3) + 0.5;
    if (alpha <= 0.0) discard;
#endif
#endif
    float depth = gl_FragCoord.z;
    float slope = max(abs(dFdx(depth)), abs(dFdy(depth)));
    gl_FragDepth = depth + slope * shadowDepthBias.x + shadowDepthBias.y / 16777216.0;
}
