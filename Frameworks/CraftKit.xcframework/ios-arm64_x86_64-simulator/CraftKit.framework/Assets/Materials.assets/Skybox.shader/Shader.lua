{
	name = "Skybox",

	options =
	{
		USE_ENVMAP = {false, {"envMap"}},
		USE_ENVMAP_HDR = {false, {"envMapHDR"}}
	},

	properties =
	{
	    envMap = {"cubeTexture", nil},
		envMapHDR = {"texture2D", nil},
	    sky = {"vec3", {0.35, 0.37, 0.42}},
	    horizon = {"vec3", {0.15, 0.15, 0.15}},
	    ground = {"vec3", {0.12, 0.13, 0.15}},
		bias = {"float", 0.0}
	},

	pass =
	{
		depthWrite = false,
    	renderQueue = "skybox",

		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
