#define POSITION 0
#define NORMAL 1
#define TANGENT 2
#define BITANGENT 3
#define COLOR0 4
#define COLOR1 5
#define COLOR2 6
#define COLOR3 7
#define INDICES 8
#define WEIGHT 9
#define TEXCOORD0 10
#define TEXCOORD1 11
#define TEXCOORD2 12
#define TEXCOORD3 13
#define TEXCOORD4 14
#define TEXCOORD5 15
#define TEXCOORD6 16
#define TEXCOORD7 17

// bgfx SPIRV binding convention: sampler binding = texture binding + 16
// Pre-computed sampler slots (layout qualifiers require integer literals, not expressions)
#define BGFX_SAMPLER_SLOT_0  16
#define BGFX_SAMPLER_SLOT_1  17
#define BGFX_SAMPLER_SLOT_2  18
#define BGFX_SAMPLER_SLOT_3  19
#define BGFX_SAMPLER_SLOT_4  20
#define BGFX_SAMPLER_SLOT_5  21

#if !defined(BGFX_CONFIG_MAX_BONES)
#    define BGFX_CONFIG_MAX_BONES 128
#endif // !defined(BGFX_CONFIG_MAX_BONES)

// Non-SPIRV path: original uniform and sampler declarations (Metal/iOS)
// For SPIRV/Vulkan, each shader declares its own UBO, attributes, and
// separate image+sampler (attributes vary per shader, e.g. vec3 vs vec4).
#if !defined(SPIRV)

uniform vec4 u_viewRect;
uniform vec4 u_viewTexel;
uniform mat4 u_view;
uniform mat4 u_invView;
uniform mat4 u_proj;
uniform mat4 u_invProj;
uniform mat4 u_viewProj;
uniform mat4 u_invViewProj;
uniform mat4 u_model[BGFX_CONFIG_MAX_BONES];
uniform mat4 u_modelView;
uniform mat4 u_modelViewProj;
uniform vec4 u_alphaRef4;
uniform mat3 u_normal;
uniform vec3 u_cameraPosition;

// Default texture used by Codea for some drawing functions
uniform vec4 u_time;
uniform sampler2D s_texture;
uniform sampler2D s_curveAtlasTexture;
uniform vec4 u_tintColor;

#define CURVE(_name) \
    uniform float _name

#define GRADIENT(_name) \
    uniform float _name

float curve(float index, float t)
{
    return texture(s_curveAtlasTexture, vec2(t, index)).r;
}

vec4 gradient(float index, float t)
{
    return texture(s_curveAtlasTexture, vec2(t, index));
}

#endif // !defined(SPIRV)


// Compute Shade Defines
#define IMAGE_XX(_name, _format, _image, _access) \
    layout(_format) _access uniform highp _image _name

#define readwrite
#define IMAGE2D_RO( _name, _format) IMAGE_XX(_name, _format, image2D,  readonly)
#define UIMAGE2D_RO(_name, _format) IMAGE_XX(_name, _format, uimage2D, readonly)
#define IMAGE2D_WR( _name, _format) IMAGE_XX(_name, _format, image2D,  writeonly)
#define UIMAGE2D_WR(_name, _format) IMAGE_XX(_name, _format, uimage2D, writeonly)
#define IMAGE2D_RW( _name, _format) IMAGE_XX(_name, _format, image2D,  readwrite)
#define UIMAGE2D_RW(_name, _format) IMAGE_XX(_name, _format, uimage2D, readwrite)

#define IMAGE2D_ARRAY_RO( _name, _format) IMAGE_XX(_name, _format, image2DArray,  readonly)
#define UIMAGE2D_ARRAY_RO(_name, _format) IMAGE_XX(_name, _format, uimage2DArray, readonly)
#define IMAGE2D_ARRAY_WR( _name, _format) IMAGE_XX(_name, _format, image2DArray,  writeonly)
#define UIMAGE2D_ARRAY_WR(_name, _format) IMAGE_XX(_name, _format, uimage2DArray, writeonly)
#define IMAGE2D_ARRAY_RW( _name, _format) IMAGE_XX(_name, _format, image2DArray,  readwrite)
#define UIMAGE2D_ARRAY_RW(_name, _format) IMAGE_XX(_name, _format, uimage2DArray, readwrite)

#define IMAGE3D_RO( _name, _format) IMAGE_XX(_name, _format, image3D,  readonly)
#define UIMAGE3D_RO(_name, _format) IMAGE_XX(_name, _format, uimage3D, readonly)
#define IMAGE3D_WR( _name, _format) IMAGE_XX(_name, _format, image3D,  writeonly)
#define UIMAGE3D_WR(_name, _format) IMAGE_XX(_name, _format, uimage3D, writeonly)
#define IMAGE3D_RW( _name, _format) IMAGE_XX(_name, _format, image3D,  readwrite)
#define UIMAGE3D_RW(_name, _format) IMAGE_XX(_name, _format, uimage3D, readwrite)

#define BUFFER0 2
#define BUFFER1 3
#define BUFFER2 4
#define BUFFER3 5
#define BUFFER5 6
#define BUFFER6 7
#define BUFFER7 8

#define BUFFER_XX(_name, _type, _reg, _access)                \
    layout(std430, binding = _reg) _access buffer _name ## Buffer \
    {                                                           \
        _type _name[];                                          \
    }

#define BUFFER_RO(_name, _type, _reg) BUFFER_XX(_name, _type, _reg, readonly)
#define BUFFER_RW(_name, _type, _reg) BUFFER_XX(_name, _type, _reg, readwrite)
#define BUFFER_WR(_name, _type, _reg) BUFFER_XX(_name, _type, _reg, writeonly)

#define NUM_THREADS(_x, _y, _z) layout (local_size_x = _x, local_size_y = _y, local_size_z = _z) in;

#define saturate(_x) clamp(_x, 0.0, 1.0)

#define dispatchIndirect( \
      _buffer             \
    , _offset             \
    , _numX               \
    , _numY               \
    , _numZ               \
    )                     \
    _buffer[_offset*2+0] = uvec4(_numX, _numY, _numZ, 0u)

#define drawIndirect( \
      _buffer         \
    , _offset         \
    , _numVertices    \
    , _numInstances   \
    , _startVertex    \
    , _startInstance  \
    )                 \
    _buffer[_offset*2+0] = uvec4(_numVertices, _numInstances, _startVertex, _startInstance)

#define drawIndexedIndirect( \
      _buffer                \
    , _offset                \
    , _numIndices            \
    , _numInstances          \
    , _startIndex            \
    , _startVertex           \
    , _startInstance         \
    )                        \
    _buffer[_offset*2+0] = uvec4(_numIndices, _numInstances, _startIndex, _startVertex); \
    _buffer[_offset*2+1] = uvec4(_startInstance, 0u, 0u, 0u)
