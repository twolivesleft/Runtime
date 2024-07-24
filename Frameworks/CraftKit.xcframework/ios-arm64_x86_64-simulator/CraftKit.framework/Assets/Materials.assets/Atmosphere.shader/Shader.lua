{
	name = "Atmosphere",

	options =
	{
	},

	properties =
	{
	    sunPos = {"vec3", {0, 1.0 * 0.3 + 0.2, -1}}
	},

	pass =
	{
		depthWrite = false,
    	renderQueue = "skybox",

		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
