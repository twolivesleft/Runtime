precision highp float;

attribute vec3 position;
uniform highp mat4 inverseProjectionMatrix;
uniform highp mat4 inverseModelViewMatrix;

varying highp vec3 eyeDirection;

void main()
{
    vec3 unprojected = (inverseProjectionMatrix * vec4(position, 1)).xyz;
    eyeDirection = mat3(inverseModelViewMatrix) * unprojected;

    gl_Position = vec4(position.xy, 1, 1);
}
