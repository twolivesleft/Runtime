{
	name = "PrefilterIrradiance",

	options =
	{
	},

	properties =
	{
		environmentMap = {"cubeTexture", nil},
		resolution = {"float", 256},
		roughness = {"float", 0.0},
		inverseModelViewMatrix = {"mat4"},
		inverseProjectionMatrix = {"mat4"},
		samples = {"int", 512},
	},

	pass =
	{
		depthWrite = false,
    	renderQueue = "skybox",

		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
