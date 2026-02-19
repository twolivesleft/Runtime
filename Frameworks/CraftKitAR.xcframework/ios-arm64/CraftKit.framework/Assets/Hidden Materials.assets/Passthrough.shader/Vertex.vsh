#extension GL_EXT_separate_shader_objects: enable

precision mediump float;

layout(location = 0) attribute vec3 position;
layout(location = 2) attribute vec2 uv;

varying vec2 vUv;

void main()
{
    gl_Position = vec4(position.xy, 1.0, 1.0);
    vUv = uv;
}