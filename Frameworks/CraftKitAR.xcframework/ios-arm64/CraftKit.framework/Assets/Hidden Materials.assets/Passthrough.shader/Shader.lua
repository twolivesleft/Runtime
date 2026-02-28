{
	name = "Passthrough",

	options = 
	{
		PRESERVE_ALPHA = {false}
	},

	properties =
	{
		screenMap = {"texture2D", nil},
	},

	pass =
	{
		depthWrite = false,
    	renderQueue = "skybox",

		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
