{
	name = "Basic",

	options = 
	{
		USE_COLOR = {true},
		USE_MAP = {false, {"map"}},
	    USE_ENVMAP = {false, {"envMap"}},
	    ENVMAP_TYPE_CUBE = {true},
	    USE_NORMALMAP = {false, {"normalMap"}},
	    ENVMAP_BLENDING_MULTIPLY = {true},
	    ENVMAP_MODE_REFLECTION = {true},
	    PREMULTIPLIED_ALPHA = {false}
	},

	properties =
	{
	    map = {"texture2D", nil},
	    diffuse = {"vec3", {1,1,1}},
	    opacity = {"float", 1.0},
	    offsetRepeat = {"vec4", {0,0,1,1}},
	    envMap = {"cubeTexture", nil},
	    reflectivity = {"float", 1.0},
	    flipEnvMap = {"float", 1.0},
	},

	pass =
	{
		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
