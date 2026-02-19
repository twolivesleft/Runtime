{
	name = "EquirectToCubemap",

	options =
	{
	},

	properties =
	{
		equirectMap = {"texture2D", nil},
		inverseModelViewMatrix = {"mat4"},
		inverseProjectionMatrix = {"mat4"},
	},

	pass =
	{
		depthWrite = false,
    	renderQueue = "skybox",

		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
