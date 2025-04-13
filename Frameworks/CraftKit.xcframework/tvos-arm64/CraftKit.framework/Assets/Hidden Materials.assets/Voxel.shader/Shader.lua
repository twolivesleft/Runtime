{
	name = "Voxel",

	options = 
	{
		GAMMA_CORRECTION = {true},
		USE_LIGHTING = {true},
		USE_COLOR = {true},
		USE_MAP = {false, {"map"}},
		USE_FOG = {false},		
		USE_OUTLINE = {false, {"showOutline"}}
	},

	properties =
	{
		map = {"texture2D", null},
    	outlineWidth = {"float", 5},
    	outlineColor = {"vec3", {0,0,0}},
    	showOutline = {"bool", false}
	},

	pass =
	{
		files = {"Vertex.vsh", "Fragment.fsh"}
	}
}
