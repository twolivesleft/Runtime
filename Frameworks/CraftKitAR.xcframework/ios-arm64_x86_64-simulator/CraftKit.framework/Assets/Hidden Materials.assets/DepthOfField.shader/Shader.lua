{
	name = "DepthOfField",

	options =
	{
	},

	properties =
	{
		screenMap = {"texture2D", nil},
	},

	passes =
	{
		-- Pass 1
		{
			glesVersion = 3,
			depthWrite = false,
	    	renderQueue = "skybox",

			vertex =
			[[#version 300 es
			#extension GL_EXT_separate_shader_objects: enable

			precision mediump float;

			layout(location = 0) in vec3 position;
			layout(location = 2) in vec2 uv;

			out vec2 vUv;

			void main()
			{
			    gl_Position = vec4(position.xy, 1.0, 1.0);
			    vUv = uv;
			}]],

			fragment =
			[[#version 300 es
			precision highp float;

			in vec2 vUv;
			out vec4 fragColor;

			uniform mat4 inverseProjectionMatrix;
			uniform mediump sampler2D screenMap;
			uniform highp sampler2D cameraDepthMap;
			uniform vec4 depthParams;

			float depthToLinear(float depth)
			{
			    return ( depthParams.z + depthParams.w / depth );
			}

			float rawDepthToSceneDepth(vec2 screenUV, float sample)
			{
			#ifdef USE_LOGDEPTHBUF
			    sample = depthToLinear(pow(depthParams.y + 1.0, sample) - 1.0);
			#endif

			    vec4 sceneScreenPos = vec4(screenUV.x, screenUV.y, sample, 1.0) * 2.0 - 1.0;
			    vec4 sceneViewPosition = inverseProjectionMatrix * sceneScreenPos;
			    return -(sceneViewPosition.z / sceneViewPosition.w);
			}

			float sampleDepth(vec2 uv)
			{
				return rawDepthToSceneDepth(uv, texture(cameraDepthMap, uv).r);
			}

			const float GOLDEN_ANGLE = 2.39996323;
			const float MAX_BLUR_SIZE = 20.0;
			const float RAD_SCALE = 0.5; // Smaller = nicer blur, larger = faster

			float getBlurSize(float depth, float focusPoint, float focusScale)
			{
				float coc = clamp((1.0 / focusPoint - 1.0 / depth)*focusScale, -1.0, 1.0);
				return abs(coc) * MAX_BLUR_SIZE;
			}

			vec3 depthOfField(vec2 texCoord, float focusPoint, float focusScale)
			{
				float centerDepth = sampleDepth(texCoord);
				float centerSize = getBlurSize(centerDepth, focusPoint, focusScale);
				vec3 color = texture(screenMap, texCoord).rgb;
				float tot = 1.0;
				vec2 pixelSize = 1.0 / vec2(textureSize(screenMap, 0));

				float radius = RAD_SCALE;
				for (float ang = 0.0; radius<MAX_BLUR_SIZE; ang += GOLDEN_ANGLE)
				{
					vec2 tc = texCoord + vec2(cos(ang), sin(ang)) * pixelSize * radius;

					vec3 sampleColor = texture(screenMap, tc).rgb;
					float sampleDepth = sampleDepth(tc);
					float sampleSize = getBlurSize(sampleDepth, focusPoint, focusScale);
					if (sampleDepth > centerDepth)
						sampleSize = clamp(sampleSize, 0.0, centerSize*2.0);

					float m = smoothstep(radius-0.5, radius+0.5, sampleSize);
					color += mix(color/tot, sampleColor, m);
					tot += 1.0;
					radius += RAD_SCALE/radius;
				}
				return color /= tot;
			}

			void main()
			{
				// float d = depthToLinear(sampleDepth(vUv));
				// vec4 c1 = vec4(d, d, d, 1.0);
				// vec4 c2 = texture(screenMap, vUv);
				// fragColor = vUv.x < 0.5 ? c1 : c2;

				fragColor = vec4(depthOfField(vUv, 5.0, 4.0), 1.0);
			}]]
		}
	}
}
