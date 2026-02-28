#ifdef USE_FOG

uniform vec3 fogColor;

#ifdef FOG_EXP2
	uniform float fogDensity;
#else
	uniform float fogNear;
	uniform float fogFar;
#endif

void applyFog(inout vec4 fragmentColor)
{
#ifdef USE_LOGDEPTHBUF
	float depth = gl_FragDepth / gl_FragCoord.w;
#else
	float depth = gl_FragCoord.z / gl_FragCoord.w;
#endif

#ifdef FOG_EXP2
	float fogFactor = whiteCompliment( exp2( - fogDensity * fogDensity * depth * depth * LOG2 ) );
#else
	float fogFactor = smoothstep( fogNear, fogFar, depth );
#endif

	fragmentColor.rgb = mix( fragmentColor.rgb, fogColor, fogFactor );    
}

#endif
