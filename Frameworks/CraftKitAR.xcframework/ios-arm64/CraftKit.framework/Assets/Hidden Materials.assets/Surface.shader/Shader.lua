{
	name = "Standard Surface",

	options =
	{
		USE_LOGDEPTHBUF = {false},
		GAMMA_CORRECTION = {true},
		USE_COLOR = {true},
		USE_FOG = {false},
		ENVMAP_TYPE_CUBE = {true},
		ENVMAP_MODE_REFLECTION = {true},
	},

	properties =
	{
	},

	surface = true,

	pass =
	{
		files = {"Vertex.glsl", "Fragment.glsl"}
	}
}
