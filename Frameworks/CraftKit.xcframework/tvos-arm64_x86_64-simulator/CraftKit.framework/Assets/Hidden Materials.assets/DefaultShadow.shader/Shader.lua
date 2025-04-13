{
	name = "DefaultShadow",

	options =
	{
	},

	properties =
	{
	},

	pass =
	{
		glesVersion = 3,

		vertex =
		[[
		#version 300 es
		#extension GL_EXT_separate_shader_objects: enable

		precision highp float;

		uniform mat4 modelViewMatrix;
		uniform mat4 projectionMatrix;

		layout(location = 0) in vec3 position;

		void main()
		{
		    vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );
		    gl_Position = projectionMatrix * mvPosition;
		}
		]],

		fragment =
		[[
		#version 300 es
		precision highp float;

		out vec4 fragColor;

		void main()
		{
		    fragColor = vec3(1.0, 1.0, 1.0, 1.0);
		}
		]]
	}
}
