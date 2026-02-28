local mclass = require "middleclass"

local lookup =
{
    type = 0,
    name = 1,
    state = 2,
    color = 3,
    torchlight = 4,
    light = 5,
    entity = 6
}

local block = mclass("block")

local function createIndexWrapper(aClass, f)
    return function(self, name)
        local value = aClass.__instanceDict[name]

        if value ~= nil then
            return value
        elseif type(f) == "function" then
            return (f(self, name))
        else
            return f[name]
        end
    end
end

local function createNewindexWrapper(aClass, f)
    return function(self, name, value)
        if type(f) == "function" then
            f(self, name, value)
        else
            f[name] = value
        end
    end
end

block.__instanceDict.__index = createIndexWrapper(block, function(self, name)
    return (lookup[name] and self:get(lookup[name])) or nil
end)


block.__instanceDict.__newindex = createNewindexWrapper(block, function(self, name, value)
    if lookup[name] then
        self:set(lookup[name], value)
    else
        rawset(self,name,value)
    end
end)

block.static.includeBlockTypeMixin = function(aClass, blockType)
    local mt = getmetatable(aClass)
    local static = aClass.static

    local __index = mt.__index

    mt.__index = function(self, name)
        local value = __index[name]
        if value ~= nil then
            return value
        elseif blockType then
            value = blockType[name]
            if value then
                -- allow BlockType methods to be involked as static functions
                if type(value) == "function" then
                    return function(...) return value(blockType, ...) end
                else
                    return value
                end
            end
        end
        return nil
    end

    local __newindex = mt.__newindex
    mt.__newindex = function(self, name, value)
        if blockType[name] ~= nil then
            blockType[name] = value
        else
            -- Call original newindex method
            __newindex(self, name, value)
        end
    end    
end

-- Static methods
function block.create(name)
    return craft.voxels.blocks:new(name)
end

function block.addAssetPack(assetPack)
    craft.voxels.blocks:addAssetPack(assetPack)
end

function block.addAsset(assetName)
    craft.voxels.blocks:addAsset(assetName)
end

function block.all()
    return craft.voxels.blocks:all()
end

function block:initialize()
end

-- Get a black property
function block:get(k)
    local x,y,z = self:xyz()
    return self.voxels:get(x, y, z, k)
end

-- Set a block property
function block:set(k,v)
    local x,y,z = self:xyz()
    return self.voxels:set(x, y, z, {[k] = v})
end

function block:destroy()
    self.name = "air"
end

function block:find(...)
    local x,y,z = self:xyz()
    return self.voxels:find(x, y, z, ...)
end

-- Schedule this block for an update in x ticks
function block:schedule(ticks)
    local x,y,z = self:xyz()
    self.voxels:updateBlock(x, y, z, ticks)
end

-- Unpack coordinates in as multiple return values
function block:xyz()
    return self.x, self.y, self.z
end

return block
