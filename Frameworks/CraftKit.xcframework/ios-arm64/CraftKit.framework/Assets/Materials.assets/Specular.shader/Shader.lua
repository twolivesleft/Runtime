{
	name = "Specular",

	options =
	{
		USE_LOGDEPTHBUF = {false},
		GAMMA_CORRECTION = {true},
		USE_LIGHTING = {true},
		USE_COLOR = {true},
		USE_MAP = {false, {"map"}},
		USE_NORMALMAP = {false, {"normalMap"}},
		USE_SPECULARMAP = {false, {"specularMap"}},
	    USE_AOMAP = {false, {"aoMap"}},
		USE_DISPLACEMENTMAP = {false, {"displacementMap"}},
		USE_AOMAP = {false, {"aoMap"}},
		USE_FOG = {false},
		PREMULTIPLIED_ALPHA = {false}
	},

	properties =
	{
		map = {"texture2D", null},
		normalMap = {"texture2D", null},
		normalScale = {"vec2", {0.1, 0.1}},
		specularMap = {"texture2D", null},
		displacementMap = {"texture2D", null},
		displacementBias = {"float", 0.0},
		displacementScale = {"float", 1.0},
		aoMap = {"texture2D", null},
		aoMapIntensity = {"float", 0.5},
		offsetRepeat = {"vec4", {0,0,1,1}},
		diffuse = {"vec3", {1,1,1}},
		emissive = {"vec3", {0,0,0}},
	    specular = {"vec3", {1,1,1}},
    	shininess = {"float", 100},
		opacity = {"float", 1.0}
	},

	pass =
	{
		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
