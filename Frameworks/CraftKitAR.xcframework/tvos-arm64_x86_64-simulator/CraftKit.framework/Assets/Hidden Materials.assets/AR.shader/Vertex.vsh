#extension GL_EXT_separate_shader_objects: enable

precision highp float;

layout(location = 0) attribute vec3 position;
layout(location = 2) attribute vec2 uv;

uniform float preferredRotation;

varying vec2 texCoordVarying;

void main()
{
    mat4 rotationMatrix = mat4( cos(preferredRotation), -sin(preferredRotation), 0.0, 0.0,
                                sin(preferredRotation),  cos(preferredRotation), 0.0, 0.0,
                                                   0.0,                     0.0, 1.0, 0.0,
                                                   0.0,                     0.0, 0.0, 1.0);
    gl_Position = vec4(position.xy, 1.0, 1.0) * rotationMatrix;
    texCoordVarying = uv;
}