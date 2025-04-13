{
	name = "Bloom",

	options =
	{
		PREFILTER = {false, {"prefilter"}},
		USE_TONEMAPPING = {false}
	},

	properties =
	{
		sourceMap = {"texture2D", nil},
		screenMap = {"texture2D", nil},
		texelSize = {"vec2", {0,0}},
		intensity = {"float", 0.75},
		prefilter = {"bool", false},
		filter = {"vec4", {0,0,0,0}},
		exposure = {"float", 1.0},
	},

	passes =
	{
		-- Box Blur Downsample Pass [0]
		{
			glesVersion = 3,
			depthWrite = false,
	    	renderQueue = "skybox",

			vertex =
			[[
			#extension GL_EXT_separate_shader_objects: enable

			precision mediump float;

			layout(location = 0) attribute vec3 position;
			layout(location = 2) attribute vec2 uv;

			varying vec2 vUv;

			void main()
			{
			    gl_Position = vec4(position.xy, 1.0, 1.0);
			    vUv = uv;
			}
			]],

			fragment =
			[[
			precision highp float;

			varying vec2 vUv;

			uniform mediump sampler2D screenMap;
			uniform vec2 texelSize;

			#ifdef PREFILTER
			uniform vec4 filter;

			vec3 prefilter (vec3 c)
			{
				float brightness = max(c.r, max(c.g, c.b));
				float soft = brightness - filter.y;
				soft = clamp(soft, 0.0, filter.z);
				soft = soft * soft * filter.w;
				float contribution = max(soft, brightness - filter.x);
				contribution /= max(brightness, 0.00001);
				return c * contribution;
			}
			#endif

			vec3 sample (vec2 uv)
			{
				return texture2D(screenMap, clamp(uv, 0.0, 1.0)).rgb;
			}

			vec3 sampleBox (vec2 uv, float delta)
			{
				vec4 o = texelSize.xyxy * vec2(-delta, delta).xxyy;
				vec3 s =
					sample(uv + o.xy) + sample(uv + o.zy) +
					sample(uv + o.xw) + sample(uv + o.zw);
				return s * 0.25;
			}

			void main()
			{
			#ifdef PREFILTER
				gl_FragColor = vec4(prefilter(sampleBox(vUv, 1.0)), 1.0);
			#else
				gl_FragColor = vec4(sampleBox(vUv, 1.0), 1.0);
			#endif
			}
			]]
		},

		-- Box Blur Upsample Pass [1]
		{
			glesVersion = 3,
			depthWrite = false,
	    	renderQueue = "skybox",
			blendMode = "additive",

			vertex =
			[[
			#extension GL_EXT_separate_shader_objects: enable

			precision mediump float;

			layout(location = 0) attribute vec3 position;
			layout(location = 2) attribute vec2 uv;

			varying vec2 vUv;

			void main()
			{
			    gl_Position = vec4(position.xy, 1.0, 1.0);
			    vUv = uv;
			}
			]],

			fragment =
			[[
			precision mediump float;

			varying vec2 vUv;

			uniform mediump sampler2D screenMap;
			uniform vec2 texelSize;

			vec3 sample (vec2 uv)
			{
				return texture2D(screenMap, clamp(uv, 0.0, 1.0)).rgb;
			}

			vec3 sampleBox (vec2 uv, float delta)
			{
				vec4 o = texelSize.xyxy * vec2(-delta, delta).xxyy;
				vec3 s =
					sample(uv + o.xy) + sample(uv + o.zy) +
					sample(uv + o.xw) + sample(uv + o.zw);
				return s * 0.25;
			}

			void main()
			{
				gl_FragColor = vec4(sampleBox(vUv, 0.5), 1.0);
			}

			]]
		},


		-- Bloom Final Pass [2]
		{
			glesVersion = 3,
			depthWrite = false,
	    	renderQueue = "skybox",

			vertex =
			[[
			#version 300 es
			#extension GL_EXT_separate_shader_objects: enable

			precision mediump float;

			layout(location = 0) in vec3 position;
			layout(location = 2) in vec2 uv;

			out vec2 vUv;

			void main()
			{
			    gl_Position = vec4(position.xy, 1.0, 1.0);
			    vUv = uv;
			}
			]],

			fragment =
			[[
			#version 300 es
			precision mediump float;

			in vec2 vUv;
			out vec4 fragColor;

			uniform mediump sampler2D sourceMap;
			uniform mediump sampler2D screenMap;
			uniform vec2 texelSize;
			uniform float intensity;
			
			#ifdef USE_TONEMAPPING
			uniform float exposure;
			#endif

			vec3 sample (vec2 uv)
			{
				return texture(screenMap, uv).rgb;
			}

			vec3 sampleBox (vec2 uv, float delta)
			{
				vec4 o = texelSize.xyxy * vec2(-delta, delta).xxyy;
				vec3 s =
					sample(uv + o.xy) + sample(uv + o.zy) +
					sample(uv + o.xw) + sample(uv + o.zw);
				return s * 0.25;
			}

			void main()
			{
				// Add bloom to source
				fragColor = texture(sourceMap, vUv);
				fragColor.rgb += intensity * sampleBox(vUv, 0.5);

				#ifdef USE_TONEMAPPING
    			// Exposure tone mapping
				fragColor.rgb = vec3(1.0) - exp(-fragColor.rgb * exposure);
				#endif

				// Gamma correction (disabled for now)
				// const vec3 inverseGamma = vec3(1.0 / 2.2);
    			// fragColor.rgb = pow(fragColor.rgb, inverseGamma);
			}
			]]
		}
	}
}
