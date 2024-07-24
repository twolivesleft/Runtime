{
	name = "Standard",

	options =
	{
		USE_LOGDEPTHBUF = {false},
		GAMMA_CORRECTION = {true},
		STANDARD = {true},
		USE_LIGHTING = {true},
		USE_COLOR = {true},
		USE_MAP = {false, {"map"}},
		USE_NORMALMAP = {false, {"normalMap"}},
		USE_ROUGHNESSMAP = {false, {"roughnessMap"}},
		USE_METALNESSMAP = {false, {"metalnessMap"}},
		USE_DISPLACEMENTMAP = {false, {"displacementMap"}},
		USE_AOMAP = {false, {"aoMap"}},
		USE_ENVMAP = {false, {"envMap"}},
		ENVMAP_TYPE_CUBE = {true},
		ENVMAP_MODE_REFLECTION = {true},
		USE_FOG = {false},
		PREMULTIPLIED_ALPHA = {false}
	},

	properties =
	{
		map = {"texture2D", nil},
		normalMap = {"texture2D", nil},
		normalScale = {"vec2", {0.1, 0.1}},
		roughnessMap = {"texture2D", nil},
		metalnessMap = {"texture2D", nil},
		displacementMap = {"texture2D", nil},
		displacementBias = {"float", 0.0},
		displacementScale = {"float", 1.0},
		aoMap = {"texture2D", null},
		aoMapIntensity = {"float", 0.5},
		envMap = {"cubeTexture", null},
		envMapIntensity = {"float", 1.0},
		flipEnvMap = {"float", 1.0},
		refractionRatio = {"float", 0.5},
		offsetRepeat = {"vec4", {0,0,1,1}},
		diffuse = {"vec3", {1,1,1}},
		emissive = {"vec3", {0,0,0}},
		roughness = {"float", 0.0},
		metalness = {"float", 0.0},
		opacity = {"float", 1.0}
	},

	pass =
	{
		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
