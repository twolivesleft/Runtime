local imageFormatToString = 
{
    [image.rg16i] = "rg16i",
    [image.a8] = "a8",
    [image.r8] = "r8",
    [image.r8i] = "r8i",
    [image.r8u] = "r8u",
    [image.r8s] = "r8s",
    [image.r16] = "r16",
    [image.r16i] = "r16i",
    [image.r16u] = "r16u",
    [image.r16f] = "r16f",
    [image.r16s] = "r16s",
    [image.r32i] = "r32i",
    [image.r32u] = "r32u",
    [image.r32f] = "r32f",
    [image.rg8] = "rg8",
    [image.rg8i] = "rg8i",
    [image.rg8u] = "rg8u",
    [image.rg8s] = "rg8s",
    [image.rg16] = "rg16",
    [image.rg16i] = "rg16i",
    [image.rg16u] = "rg16u",
    [image.rg16f] = "rg16f",
    [image.rg16s] = "rg16s",
    [image.rg32i] = "rg32i",
    [image.rg32u] = "rg32u",
    [image.rg32f] = "rg32f",
    [image.rgb8] = "rgb8",
    [image.rgb8i] = "rgb8i",
    [image.rgb8u] = "rgb8u",
    [image.rgb8s] = "rgb8s",
    [image.rgb9e5f] = "rgb9e5f",
    [image.bgra8] = "bgra8",
    [image.rgba8] = "rgba8",
    [image.rgba8i] = "rgba8i",
    [image.rgba8u] = "rgba8u",
    [image.rgba8s] = "rgba8s",
    [image.rgba16] = "rgba16",
    [image.rgba16i] = "rgba16i",
    [image.rgba16u] = "rgba16u",
    [image.rgba16f] = "rgba16f",
    [image.rgba16s] = "rgba16s",
    [image.rgba32i] = "rgba32i",
    [image.rgba32u] = "rgba32u",
    [image.rgba32f] = "rgba32f",
}

local imageFormatPrefix = 
{
    a8 = "",
    r8 = "",
    r8i = "",
    r8u = "",
    r8s = "",
    r16 = "",
    r16i = "i",
    r16u = "u",
    r16f = "",
    r16s = "",
    r32i = "i",
    r32u = "u",
    r32f = "",
    rg8 = "",
    rg8i = "i",
    rg8u = "u",
    rg8s = "",
    rg16 = "",
    rg16i = "i",
    rg16u = "u",
    rg16f = "",
    rg16s = "",
    rg32i = "i",
    rg32u = "u",
    rg32f = "",
    rgb8 = "",
    rgb8i = "i",
    rgb8u = "u",
    rgb8s = "",
    rgb9e5f = "",
    bgra8 = "",
    rgba8 = "",
    rgba8i = "i",
    rgba8u = "u",
    rgba8s = "",
    rgba16 = "",
    rgba16i = "i",
    rgba16u = "u",
    rgba16f = "",
    rgba16s = "",
    rgba32i = "i",
    rgba32u = "u",
    rgba32f = "",
}

local function glslTypeSuffix(imageType)
    return imageType == image.type.cube and "Cube" or (imageType == image.type.volume and "3D" or "2D")
end

local function imageFormatToGLSLImageType(format, imageType) 
    return string.format("%simage%s", imageFormatPrefix[format], glslTypeSuffix(imageType))
end

local function imageFormatToGLSLSamplerType(format, imageType)
    local suffix = format:sub(-1) == "f" and "highp " or ""
    return string.format("%s%ssampler%s", suffix, imageFormatPrefix[format], glslTypeSuffix(imageType))
end


local chunk = class('shader.chunk')

function chunk:init()
    self._includes = {}
    self._material = {}
    self._func = {}
    self._vertex = {}
    self._options = {}
    self._computedOptions = {}
    self._properties = {}
    self._variables = {}
    self._buffers = {}
    self._images = {}
    self._structs = {}
    self._uniforms = {}
    self._normals = {}
    self._compute = {}
end

function chunk:include(path)
    table.insert(self._includes, path)
    return self
end

function chunk:variable(def)
    assert(def[1], "No name given for custom interpolator")
    assert(#self._variables < 4, "Maximum of 4 variables (interpolants)")
    table.insert(self._variables, def[1])
    return self
end

function chunk:option(def)
    assert(def[1], "No name given for option") 
    self._options[def[1]] = {def.value or false}

    
    if def.linked then 
        assert(type(def.linked) == "table", "Linked properties should be a table")
        local func = "return function("
        for k, v in pairs(def.linked) do
            func = func..v
            if k < #def.linked then 
                func = func..", "                
            end
        end
        func = func..")\n\treturn "
        for k, v in pairs(def.linked) do
            func = func..v
            if k < #def.linked then 
                func = func.."and "                
            end    
        end
        func = func.."\nend"
        print(func)

        local chunk, err = load(func)
        if chunk then 
            local result = chunk()
            -- print(result)
            assert(type(result) == "function")
            self._computedOptions[def[1]] = result
        else 
            error(err)
        end
    end
    return self
end

function chunk:uint(def)
    assert(def[1], "No name given for uint property")
    local p = {def[1], 'uint', def.value or 0}
    local u = {name = def[1], type = 'uint'}    
    table.insert(self._properties, p)
    table.insert(self._uniforms, u)
    return self
end

function chunk:number(def)
    assert(def[1], "No name given for number property")
    local p = {def[1], 'float', def.value or 0}
    local u = {name = def[1], type = 'float'}
    table.insert(self._properties, p)
    table.insert(self._uniforms, u)
    return self
end

function chunk:vec2(def)
    assert(def[1], "No name given for vec2 property")
    local p = {def[1], 'vec2', def.value and {def.value:unpack()} or {0, 0}}
    local u = {name = def[1], type = 'vec2'}
    table.insert(self._properties, p)
    table.insert(self._uniforms, u)
    return self
end

function chunk:vec3(def)
    assert(def[1], "No name given for vec3 property")
    local p = {def[1], 'vec3', def.value and {def.value:unpack()} or {0, 0, 0}}
    local u = {name = def[1], type = 'vec3'}
    table.insert(self._properties, p)
    table.insert(self._uniforms, u)
    return self
end

function chunk:vec4(def)
    assert(def[1], "No name given for vec4 property")
    local p = {def[1], 'vec4', def.value and {def.value:unpack()} or {0, 0, 0, 0}}
    local u = {name = def[1], type = 'vec4'}
    table.insert(self._properties, p)
    table.insert(self._uniforms, u)
    return self
end

function chunk:color(def)
    assert(def[1], "No name given for color property")
    
    local c = def.value and {def.value:unpack()} or {255,255,255,255}
    for i = 1,4 do
        c[i] = c[i] / 255
    end
    local p = {def[1], 'vec4', c, color = true}
    local u = {name = def[1], type = 'vec4'}
    table.insert(self._properties, p)
    table.insert(self._uniforms, u)
    return self
end

function chunk:texture(def)
    assert(def[1], "No name given for texture property")
    local p = {def[1], 'texture', def.value}
    local samplerType = def.samplerType or "sampler2D"
    if def.value and is(def.value, image) then 
        local value = def.value
        local format = imageFormatToString[def.value.format]
        samplerType = imageFormatToGLSLSamplerType(format, value.type)
    end
    
    local u = {name = def[1], type = samplerType, binding = def.binding, linkedOption = def.option}
    table.insert(self._properties, p)
    table.insert(self._uniforms, u)
    
    return self
end

function chunk:image(def)
    assert(def[1], "No name given for image property")

    local format = def.format or (def.value and def.value.format) or "rbga8"
    if type(format) == "number" then
        format = imageFormatToString[format]
        assert(format, "Invalid image format for image property named: "..def[1])
    end

    local imageType = def[2] or imageFormatToGLSLImageType(format, def.value and def.value.type) or "image2D"

    local p = {def[1], imageType, def.value }
    local u = {name = def[1], type = imageType, binding = def.binding, format = format, imageUniform = true, linkedOption = def.option}
    table.insert(self._properties, p)
    table.insert(self._uniforms, u)
    return self
end

local structDef = class('shader.chunk.structDef')

function structDef:init(owner, def)
    self.owner = owner
    self.structName = def[1]
    self.layout = {}
end

function structDef:float(name)
    local d = { type = "float", name = name }
    table.insert(self.layout, d)
    return self
end

function structDef:vec2(name)
    local d = { type = "vec2", name = name }
    table.insert(self.layout, d)
    return self
end

function structDef:vec3(name)
    local d = { type = "vec3", name = name }
    table.insert(self.layout, d)
    return self
end

function structDef:vec4(name)
    local d = { type = "vec4", name = name }
    table.insert(self.layout, d)
    return self
end

function structDef:uint(name)
    local d = { type = "uint", name = name }
    table.insert(self.layout, d)
    return self
end

function structDef:done()
    return self.owner
end

local _meshVertexLayout = mesh().vertexBuffer.layout
-- TODO: support skinned mesh layout, generic layouts

function chunk:struct(def, owner)

    assert(def[1], "No struct name given")
    local b = structDef(owner or self, def)
    self._structs[def[1]] = b
   
    if def.layout and def.layout == _meshVertexLayout then
        b:vec3("position"):float("padding0")
        :vec3("normal"):float("padding1")
        :vec4("tangent")
        :vec2("uv0"):vec2("uv1")
        :uint("color")
        :float("padding3"):float("padding4"):float("padding5")
    end
   
    return b
end

function chunk:buffer(def)
    assert(def[1], "No struct name given")
    assert(def[2], "No name given for buffer")
    local b = {structName = def[1], name = def[2], binding = #self._buffers, access = def.access or "readwrite"}
    table.insert(self._buffers, b)
    table.insert(self._properties, {def[2].."Buffer", "buffer", def.value})    
    return self
 end

function chunk:func(code)
    table.insert(self._func, code)
    return self
end

function chunk:material(code)
    table.insert(self._material, code)
    return self
end

function chunk:vertex(code)
    table.insert(self._vertex, code)
    return self
end

function chunk:normals(code)
    table.insert(self._normals, code)
    return self
end


shader.chunk = chunk

local modular = class('shader.modular')
local lustache = require('codea.lustache')

function modular:init(name)
    self.model = "lit"
    self._name = name or "Untitled Shader"
    self._settings =
    {
        blendMode = "disabled",
        cullFace = "back",
        depthWrite = "true",
        depthFunc = "less",
        colorMask = "rgba",
        renderQueue = "opaque"
    }
    self._chunk = shader.chunk()
end

function modular:blend(blend)
    self._settings.blendMode = blend
    return self
end

function modular:cull(cull)
    self._settings.cullFace = cull
    return self
end

function modular:doubleSided(ds)
    self._settings.doubleSided = ds
    return self
end

function modular:depthWrite(write)
    self._settings.depthWrite = write
    return self
end

function modular:depthFunc(func)
    self._settings.depthFunc = func
    return self
end

function modular:colorMask(mask)
    self._settings.colorMask = mask
    return self
end

function modular:renderQueue(queue)
    self._settings.renderQueue = queue
    return self
end

function modular:lit()
    self.model = "lit"
    return self
end

function modular:unlit()
    self.model = "unlit"
    return self
end

function modular:sprite()
    self.model = "unlit"
    self._settings.blendMode = "normal"
    self._settings.cullFace = "none"
    self._settings.renderQueue = "overlay"
    self._settings.depthWrite = false
    self._settings.depthTest = true
    self._settings.depthFunc = "less"
    return self
end

function modular:compute(code)
    self.model = "compute"
    table.insert(self._chunk._compute, code)    
    return self
end

function modular:threads(x, y, z)
    self._chunk._threads = {x = x, y = y, z = z}    
    return self
end

function modular:include(path)
    table.insert(self._chunk._includes, path)
    return self
end

function modular:add(chunk)
    for _, v in pairs(chunk._includes) do
        table.insert(self._chunk._includes, v)
    end
    
    for _, v in pairs(chunk._material) do
        table.insert(self._chunk._material, v)
    end

    for _, v in pairs(chunk._vertex) do
        table.insert(self._chunk._vertex, v)
    end

    for _, v in pairs(chunk._func) do
        table.insert(self._chunk._func, v)
    end

    for _, v in pairs(chunk._variables) do
        table.insert(self._chunk._variables, v)
    end

    for k, v in pairs(chunk._options) do
        self._chunk._options[k] = v
    end

    for k, v in pairs(chunk._computedOptions) do
        self._chunk._computedOptions[k] = v
    end

    for _, v in pairs(chunk._properties) do
        table.insert(self._chunk._properties, v)
    end

    for _, v in pairs(chunk._uniforms) do
        table.insert(self._chunk._uniforms, v)
    end
    
    for _, v in pairs(chunk._normals) do
        table.insert(self._chunk._normals, v)
    end

    for _, v in pairs(chunk._structs) do
        table.insert(self._chunk._structs, v)
    end

    for _, v in pairs(chunk._buffers) do
        table.insert(self._chunk._buffers, v)
    end
    
    return self
end

function modular:variable(def)
    self._chunk:variable(def)
    return self
end

function modular:option(def)
    self._chunk:option(def)
    return self
end

function modular:uint(def)
    self._chunk:uint(def)
    return self
end

function modular:number(def)
    self._chunk:number(def)
    return self
end

function modular:vec2(def)
    self._chunk:vec2(def)
    return self
end

function modular:vec3(def)
    self._chunk:vec3(def)
    return self
end

function modular:vec4(def)
    self._chunk:vec4(def)
    return self
end

function modular:color(def)
    self._chunk:color(def)
    return self
end

function modular:texture(def)
    self._chunk:texture(def)
    return self
end

function modular:image(def)
    self._chunk:image(def)
    return self
end

function modular:material(code)
    self._chunk:material(code)
    return self
end

function modular:vertex(code)
    self._chunk:vertex(code)
    return self
end

function modular:func(code)
    self._chunk:func(code)
    return self
end

function modular:normals(code)
    self._chunk:normals(code)
    return self
end

function modular:struct(def)
    return self._chunk:struct(def, self)
end

function modular:buffer(def)
    self._chunk:buffer(def)
    return self
end

function modular:buildSurfaceDefinition()
    local def =
    {
        name = self._name,
        options = self._chunk._options,
        computedOptions = self._chunk._computedOptions,
        properties = self._chunk._properties,        
        
        pass =
        {
            shadingModel = self.model,

            blendMode = self._settings.blendMode,
            cullFace = self._settings.cullFace,
            doubleSided = self._settings.doubleSided,
            depthWrite = self._settings.depthWrite,
            depthFunc = self._settings.depthFunc,
            colorMask = self._settings.colorMask,
            renderQueue = self._settings.renderQueue,   
            
            variables = self._chunk._variables,

            vertex = lustache:render([[
                {{#_chunk._includes}}
                #include <{{{.}}}>
                {{/_chunk._includes}}
            
                {{#_chunk._structs}}
                struct {{{structName}}}
                {
                {{#layout}}
                    {{{type}}} {{{name}}};
                {{/layout}}
                };
                {{/_chunk._structs}}

                {{#_chunk._buffers}}
                layout (std430, binding = BUFFER{{{binding}}}) {{{access}}} buffer {{{name}}}Buffer 
                {
                    {{{structName}}} {{{name}}}[];
                };
                {{/_chunk._buffers}}

                {{#_chunk._uniforms}}
                {{#linkedOption}}
                #ifdef {{{linkedOption}}}
                {{/linkedOption}}
                {{#imageUniform}}
                layout({{{format}}}{{#binding}}, binding = {{{binding}}}{{/binding}}) uniform {{{type}}} {{{name}}};
                {{/imageUniform}}
                {{^imageUniform}}
                {{#binding}}layout(binding = {{{binding}}}) uniform {{{type}}} {{{name}}};{{/binding}}
                {{^binding}}uniform {{{type}}} {{{name}}};{{/binding}}
                {{/imageUniform}}
                {{#linkedOption}}
                #endif
                {{/linkedOption}}
                {{/_chunk._uniforms}}
                
                {{#_chunk._func}}
                {{{.}}}
                {{/_chunk._func}}

                void materialVertex(inout MaterialVertexInputs material)
                {
                    {{#_chunk._vertex}}
                    {{{.}}}
                    {{/_chunk._vertex}}
                }
            ]], self),
            
            material = lustache:render([[
                {{#_chunk._includes}}
                #include <{{{.}}}>
                {{/_chunk._includes}}
            
                {{#_chunk._structs}}
                struct {{{structName}}}
                {
                {{#layout}}
                    {{{type}}} {{{name}}};
                {{/layout}}
                };
                {{/_chunk._structs}}

                {{#_chunk._buffers}}
                layout (std430, binding = BUFFER{{{binding}}}) {{{access}}} buffer {{{name}}}Buffer 
                {
                    {{{structName}}} {{{name}}}[];
                };
                {{/_chunk._buffers}}

                {{#_chunk._uniforms}}
                {{#linkedOption}}
                #ifdef {{{linkedOption}}}
                {{/linkedOption}}
                {{#imageUniform}}
                layout({{{format}}}{{#binding}}, binding = {{{binding}}}{{/binding}}) uniform {{{type}}} {{{name}}};
                {{/imageUniform}}
                {{^imageUniform}}
                {{#binding}}layout(binding = {{{binding}}}) uniform {{{type}}} {{{name}}};{{/binding}}
                {{^binding}}uniform {{{type}}} {{{name}}};{{/binding}}
                {{/imageUniform}}
                {{#linkedOption}}
                #endif
                {{/linkedOption}}
                {{/_chunk._uniforms}}

                {{#_chunk._func}}
                {{{.}}}
                {{/_chunk._func}}
                                    
                void setupMaterial(inout MaterialInputs material)
                {
                    {{#_chunk._material}}
                    {{{.}}}
                    {{/_chunk._material}}
                }
            
                void setupNormals(inout MaterialInputs material)
                {
                    {{#_chunk._normals}}
                    {{{.}}}
                    {{/_chunk._normals}}
                }
            
                void material(inout MaterialInputs material)
                {
                    setupNormals(material);
                    prepareMaterial(material);
                    vec2 uv = getUV0();
                    setupMaterial(material);
                }
            ]], self)
        }
    }
    return def    
end

function modular:buildComputeDefinition()
    assert(self._chunk._threads, "Compute shader must define workgroup thread counts via builder:threads(x, y, z)")

    local def =
    {
        options = self._chunk._options,
        properties = self._chunk._properties,
        
        pass =
        {
            compute = lustache:render([[
                #version 430
                #include <codea/common.glsl>
       
                {{#_chunk._includes}}
                #include <{{{.}}}>
                {{/_chunk._includes}}
            
                {{#_chunk._structs}}
                struct {{{structName}}}
                {
                {{#layout}}
                    {{{type}}} {{{name}}};
                {{/layout}}
                };
                {{/_chunk._structs}}

                {{#_chunk._buffers}}
                layout (std430, binding = BUFFER{{{binding}}}) {{{access}}} buffer {{{name}}}Buffer 
                {
                    {{{structName}}} {{{name}}}[];
                };
                {{/_chunk._buffers}}
                
                {{#_chunk._uniforms}}
                {{#linkedOption}}
                #ifdef {{{linkedOption}}}
                {{/linkedOption}}
                {{#imageUniform}}
                layout({{{format}}}{{#binding}}, binding = {{{binding}}}{{/binding}}) uniform {{{type}}} {{{name}}};
                {{/imageUniform}}
                {{^imageUniform}}
                {{#binding}}layout(binding = {{{binding}}}) uniform {{{type}}} {{{name}}};{{/binding}}
                {{^binding}}uniform {{{type}}} {{{name}}};{{/binding}}
                {{/imageUniform}}
                {{#linkedOption}}
                #endif
                {{/linkedOption}}
                {{/_chunk._uniforms}}

                {{#_chunk._func}}
                {{{.}}}
                {{/_chunk._func}}

                NUM_THREADS({{{_chunk._threads.x}}}, {{{_chunk._threads.y}}}, {{{_chunk._threads.z}}})
                void main()
                {
                    {{#_chunk._compute}}
                    {{{.}}}
                    {{/_chunk._compute}}
                }
            ]], self)            
        }
    }

    return def    
end

function modular:build()
    if self.model == "compute" then 
        return shader(self:buildComputeDefinition())
    elseif self.model == "lit" or self.model == "unlit" then
        return shader(self:buildSurfaceDefinition())
    else 
        assert(false, "Invalid shader model: ".. self.model)
    end
end

shader.builder = modular
