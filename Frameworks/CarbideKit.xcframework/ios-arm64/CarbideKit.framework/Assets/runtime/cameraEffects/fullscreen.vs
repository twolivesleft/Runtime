#version 430
#include <codea/common.glsl>

layout (location = POSITION) in vec3 a_position;
layout (location = TEXCOORD0) in vec2 a_texcoord0;

out vec2 uv;

void main()
{
    gl_Position = u_modelViewProj * vec4(a_position, 1.0);
    uv = a_texcoord0;
}
