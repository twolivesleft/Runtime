#version 300 es
#extension GL_EXT_separate_shader_objects: enable

precision mediump float;

layout(location = 0) in vec3 position;
layout(location = 2) in vec2 uv;

out vec2 vUv;

void main()
{
    gl_Position = vec4(position.xy, 1.0, 1.0);
    vUv = uv;
}
