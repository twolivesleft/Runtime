precision mediump float;

varying vec2 vUv;

uniform sampler2D screenMap;

void main()
{
	gl_FragColor = texture2D( screenMap, vUv );	    
}
