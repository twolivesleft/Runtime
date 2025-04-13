{
	name = "BoxBlurUp",

	options = 
	{
	},

	properties =
	{
		screenMap = {"texture2D", nil},
		texelSize = {"vec2", {0,0}}
	},

	pass =
	{
		depthWrite = false,
		blendMode = "additive",
    	renderQueue = "skybox",

		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
