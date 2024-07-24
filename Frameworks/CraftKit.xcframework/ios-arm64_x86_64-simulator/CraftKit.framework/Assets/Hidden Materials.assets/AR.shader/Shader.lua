{
	name = "AR",

	properties =
	{
    	preferredRotation = {"float", 0},
    	lumaThreshold = {"float", 1.0},
    	chromaThreshold = {"float", 1.0},
    	SamplerY = {"texture2D", nil},
    	SamplerUV = {"texture2D", nil},
    	colorConversionMatrix = {"mat3"}
	},

	pass =
	{
		files = {"Vertex.vsh", "Fragment.fsh"},
		renderQueue = "skybox"
	}
}
