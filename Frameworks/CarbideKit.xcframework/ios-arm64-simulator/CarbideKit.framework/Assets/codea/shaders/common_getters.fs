//------------------------------------------------------------------------------
// Uniforms access
//------------------------------------------------------------------------------

/** @public-api */
mat4 getViewFromWorldMatrix() {
    return frameUniforms_viewFromWorldMatrix;
}

/** @public-api */
mat4 getWorldFromViewMatrix() {
    return frameUniforms_worldFromViewMatrix;
}

/** @public-api */
mat4 getClipFromViewMatrix() {
    //return frameUniforms.clipFromViewMatrix;
    return u_proj;
}

/** @public-api */
mat4 getViewFromClipMatrix() {
//    return frameUniforms.viewFromClipMatrix;
    return u_invProj;
}

/** @public-api */
mat4 getClipFromWorldMatrix() {
    //return frameUniforms.clipFromWorldMatrix;
    return u_viewProj;
}

/** @public-api */
mat4 getWorldFromClipMatrix() {
    //return frameUniforms.worldFromClipMatrix;
    return u_invViewProj;
}

/** @public-api */
vec4 getResolution() {
    return frameUniforms_resolution;
}

/** @public-api */
vec3 getWorldCameraPosition() {
    return frameUniforms_cameraPosition;
}

/** @public-api */
highp vec3 getWorldOffset() {
    return frameUniforms.worldOffset;
}

/** @public-api */
float getTime() {
    return frameUniforms_time;
}

/** @public-api */
highp vec4 getUserTime() {
    return frameUniforms_userTime;
}

/** @public-api **/
highp float getUserTimeMod(float m) {
    return mod(mod(frameUniforms_userTime.x, m) + mod(frameUniforms_userTime.y, m), m);
}

/** @public-api */
float getExposure() {
    return frameUniforms.exposure;
}

/** @public-api */
float getEV100() {
    return frameUniforms.ev100;
}
