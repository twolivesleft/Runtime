#version 430
#include <codea/common.glsl>
#include <codea/dither.glsl>

in vec2 uv;
out vec4 FragColor;
uniform sampler2D source;
uniform vec4 outputDither;

void main()
{
    FragColor = cameraDither(texture(source, uv), gl_FragCoord.xy, outputDither);
}
