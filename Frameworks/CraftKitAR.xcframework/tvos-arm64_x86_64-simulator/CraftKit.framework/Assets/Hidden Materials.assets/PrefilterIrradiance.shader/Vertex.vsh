#version 300 es
#extension GL_EXT_separate_shader_objects: enable

precision highp float;

layout(location = 0) in vec3 position;
uniform mat4 inverseProjectionMatrix;
uniform mat4 inverseModelViewMatrix;

out vec3 eyeDirection;

void main()
{
    vec3 unprojected = (inverseProjectionMatrix * vec4(position, 1)).xyz;
    eyeDirection = mat3(inverseModelViewMatrix) * unprojected;

    gl_Position = vec4(position.xy, 1, 1);
}
