-- Mixin for adding typed properties to a class
-- Example:
-- MyClass:property{name, type, default, getter = function(self) end, setter = function(self, v) end}
local properties = {}

local defaults =
{
    number = 0.0,
    integer = 0,
    string = "",
}

function properties:included(klass)
    klass.static.properties = {}
    klass.static.propertiesMap = {}
    klass.static.property = function(self, params)
        assert(params[1] ~= nil, "No property name specified")
        assert(params[2] ~= nil, "No property type specified")
        
        local key = params.key or '_'..params[1]
        local get = params.get or function(self)
            return rawget(self, key)
        end
        local set = params.set or function(self, v)
            rawset(self, key, v)
        end

        local type = params[2]
        local default = params.default or defaults[type]

        local prop = {name = params[1],
                      type = type,
                      default = default,
                      key = key,
                      setter = set,
                      getter = get,
                      title = params.title or params[1],
                      description = params.description}
        table.insert(self.properties, prop)
        self.propertiesMap[prop.name] = prop
    end
    
    klass.static.new = function(self, ...)
        assert(type(self) == 'table', "Make sure that you are using 'Class:new' instead of 'Class.new'")
        local instance = self:allocate()
        -- Assign default property values
        for k,v in pairs(self.properties) do
            if v.default then instance[v.key] = v.default end
        end
        instance:init(...)
        return instance
    end
    
    klass.static.subclassed = function(self, other)
        other.static.properties = {}
        other.static.propertiesMap = {}
        for k,v in pairs(self.properties) do
            table.insert(other.properties, v)
            other.propertiesMap[v.name] = v
        end
        other.static.subclassed = self.subclassed
    end
end

function properties:__index(k)
    local prop = self.class.propertiesMap[k]
    local getter = prop and prop.getter
    if getter ~= nil then
        return getter(self)
    end
end

function properties:__newindex(k, v)
    local prop = self.class.propertiesMap[k]
    local setter = prop and prop.setter
    if setter ~= nil then
        setter(self, v)
    else
        rawset(self, k, v)
    end
end

return properties


