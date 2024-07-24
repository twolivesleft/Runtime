{
	name = "Selection",

	options =
	{
		PREFILTER = {false, {"prefilter"}},
		DOWNSAMPLE = {false, {"downsample"}}
	},

	properties =
	{
		screenMap = {"texture2D", nil},
		sourceMap = {"texture2D", nil},
		texelSize = {"vec2", {0,0}},
		objectID = {"float", 0},
		prefilter = {"bool", false},
		downsample = {"bool", false},
		outlineThickness = {"float", 0.25},
		outlineColor = {"vec3", {1,0.7,0.2}}
	},

	pass =
	{
		depthWrite = false,
    	renderQueue = "skybox",

		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
