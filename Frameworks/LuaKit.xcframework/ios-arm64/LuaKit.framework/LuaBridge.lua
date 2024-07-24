-- LuaBridge.lua

-- Based on:
-- NSLua by Simon Cozens (https://github.com/simoncozens/NSLua)
-- Portions copyrighted by Toru Hisai, 2015 and Crimson Moon Entertainment LLC, 2015.

-- Modified for Codea by Jean-François Pérusse 2021-12
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

--
-- Objective-C Classes
--

-- Send Objective-C Messages 
function sendMesg (target, selector, ...)
   local to_send = {}
   local n = select("#", ...)
   local key = 1
   for i = 1, n do
      local arg = select(-i, ...)

      -- If this is a wrapped object, then send what is in the wrapper
      arg = unwrap(arg)
      to_send[key] = arg
      key = key + 1
   end
   
   to_send[key] = target
   key = key + 1
   to_send[key] = selector

   return objc.call(n + 2, to_send)
end

function objcCallMethod(target, name, ...)
  -- Having an explicit target here (even though we know the target)
  -- allows us to use Lua-like "foo:bar()" syntax
  local status, ret = pcall(sendMesg, unwrap(target), name, ...)
  if not status then
    local info = debug.getinfo(2)
    print(info.source:sub(2) .. ":" ..
          info.currentline .. ": " ..
          name .. "' not found, are you using '.' instead of ':'?")
    return
  end
  if type(ret) == "userdata" then
    return wrap(ret)
  else
    return ret
  end
end

local method_mt = {
  __tostring = function(o)
      return "<method "..(o.name).." on "..tostring(o.target)..">"
  end,
  __call = function (o, target, ...)
    return objcCallMethod(target, o.name, ...)
  end
}

local parameterless_mt = {
  __tostring = function (o)
    return "<"..(o.target.Class)..":"..(o.property).."()>"
  end,
  __call = function (o, target, ...)
    return objc.getproperty(unwrap(o.target), o.property)
  end
}

local hasvariable_or_property = function(inObject, inKey)
    return objc.hasvariable(unwrap(inObject), inKey) or objc.hasproperty(unwrap(inObject), inKey)
end

local object_mt = {
  __tostring = function (o)
    return "<"..(o.Class)..">"
  end,
  __index = function(inObject, inKey)
    if hasvariable_or_property(inObject, inKey) then
      local result, isKeyError = objc.getproperty(unwrap(inObject), inKey)
      -- If getproperty returned a key error for an existing key, try the method instead
      if not isKeyError then
        return result
      end
      local method = objc.hasmethod(unwrap(inObject), inKey)
      if method then
        return objcCallMethod(inObject, inKey)
      end
      return nil
    end
    
    local newKey = inKey:gsub("_",":")
    p = objc.hasmethod(unwrap(inObject), newKey)
    if p then
      p = { name = newKey, target = inObject }
      setmetatable(p, method_mt)
      return p
    end
    
    -- Handle special case of parameterless methods
    if string.sub(inKey, -1) == "_" then
      newKey = string.sub(inKey, 1, string.len(inKey) - 1)
      
      if hasvariable_or_property(inObject, newKey) then
        p = { target = inObject, property = newKey }
        setmetatable(p, parameterless_mt)
        return p
      end

      -- Added this case for failing to call void and parameterless methods
      -- which apparently do not have ':' in their selector
      p = objc.hasmethod(unwrap(inObject), newKey)
      if p then
        p = { name = newKey, target = inObject }
        setmetatable(p, method_mt)
        return p
      end
    end
    
    objc.warning("No property or method '" .. inKey .. "' was found on " .. tostring(inObject))
  end,
  __newindex = function(inObject, inKey, inValue)
    if (hasvariable_or_property(inObject, inKey)) then
        sendMesg(inObject["WrappedObject"], 'setValue:forKeyPath:', inValue, inKey)
        return
    end
    local setter = "set" .. inKey:gsub("^%l", string.upper) .. ":"
    if (objc.hasmethod(unwrap(inObject), setter)) then
        sendMesg(unwrap(inObject), setter, inValue)
    else
        objc.warning("Trying to set non-existing property " .. inKey .. " on " .. tostring(inObject))
    end
  end,
  __call = function(inObject, target, ...)
    if objc.hasmethod(unwrap(inObject), "new") then
      return sendMesg(unwrap(inObject), "new", ...)
    end
  end,
  __gc = function(inObject)
    objc.release(unwrap(inObject))
  end,
  __eq = function(a, b)
    local wrappedA = a["WrappedObject"]
    local wrappedB = b["WrappedObject"]
    if wrappedA ~= nil and wrappedB ~= nil then
      return wrappedA == wrappedB
    end
  end
}

-- Wrap Objective-C Objects
function wrap(obj)
    local o = {}
    o["WrappedObject"] = obj;
    o["Class"] = objc.classof(obj);
    setmetatable(o, object_mt)
    return o
end

local pointer_mt = {
  __tostring = function (o)
    return "<pointer to "..(o.Type)..">"
  end,
  __index = function(inObject, inKey)
    if inKey == "value" then
        return objc.readpointer(inObject.WrappedPointer, inObject.Type)
    end
  end,
  __newindex = function(inObject, inKey, inValue)
    if inKey == "value" then
        objc.writepointer(inObject.WrappedPointer, inObject.Type, inValue)
    end
  end
}

-- Wrap Objective-C Value Pointers
function wrapPointer(pointer, type)
    local o = {}
    o["WrappedPointer"] = pointer;
    o["Type"] = type;
    setmetatable(o, pointer_mt)
    return o
end

-- Unwrap Objective-C Pointers
function unwrap(obj)
  if type(obj) == "table" then
      if obj["WrappedObject"] ~= nil then
        return obj["WrappedObject"]
      end
  end

  return obj
end

objc.cls = {}
objc._clsWarningSent = false

objc._getClass = function(inKey)
    local cls = objc.getclass(inKey)
    if cls then
        return wrap(cls)
    else
        objc.warning("Could not find class: " .. inKey)
    end
end

local cls_mt = {
    __index = function(inObject, inKey)
        if objc._clsWarningSent == false then
            objc.warning("objc.cls.ClassName is deprecated. Use objc.ClassName instead.")
            objc._clsWarningSent = true
        end
        return objc._getClass(inKey)
    end
}

setmetatable(objc.cls, cls_mt)

objc.rect = function(x, y, width, height)
    return objc.struct("CGRect", x, y, width, height)
end

objc.point = function(x, y)
    return objc.struct("CGPoint", x, y)
end

objc.size = function(width, height)
    return objc.struct("CGSize", width, height)
end

objc.range = function(loc, len)
    return objc.struct("NSRange", loc, len)
end

objc.color = function(r, g, b, a)
    return objc.struct("CGColor", r, g, b, a)
end

objc.vector = function(dx, dy)
    return objc.struct("CGVector", dx, dy)
end

objc.affineTransform = function(a, b, c, d, tx, ty)
    return objc.struct("CGAffineTransform", a, b, c, d, tx, ty)
end

objc.insets = function(top, left, bottom, right)
    return objc.struct("UIEdgeInsets", top, left, bottom, right)
end

function objcdelegate()
    local c = {}

    c.__index = c
    
    c.__tostring = function(o)
        if o._protocol ~= nil then
            return "<delegate instance "..(o._classname)..">"
        elseif o._classname ~= nil then
            return "<class instance "..(o._classname)..">"
        else
            return "<invalid>"
        end
    end
    
    c.__gc = function(o)
        objc.release(o._delegate)
    end

    local mt = {}
    mt.__call = function(t, ...)
        local o = {}
        setmetatable(o, c)
        objc.initdelegate(o)
        if viewer.runtime == LEGACY then
            if o.init ~= nil then
                o:init(...)
            end
        else
            if o._init ~= nil then
                o:_init(...)
            end
        end
        return o
    end
    mt.__tostring = function (o)
        if o._protocol ~= nil then
            return "<delegate "..(o.classname)..">"
        elseif o._classname ~= nil then
            return "<class "..(o._classname)..">"
        else
            return "<invalid>"
        end
    end

    setmetatable(c, mt)
    
    return c
end

objc.delegate = function(protocolName)
    local protocol = objc.getprotocol(protocolName)
    if protocol then
        c = objcdelegate()
        c._classname = objc.reserveclassname(protocolName)
        c._protocol = protocol
        return c
    else
        objc.warning("Could not find protocol: " .. protocolName)
    end
end

objc.class = function(className)
    c = objcdelegate()
    c._classname = objc.reserveclassname(className)
    return c
end

objc.inspect = function(target)
    return objc.inspectclass(unwrap(target))
end

--- objc.viewer: objc.UIViewController
local objc_mt = {
   __index = function(inObject, inKey)
        if inKey == "viewer" then
            return objc.getviewer()
        end

        if inKey == "_viewerContainer" then
            local viewer = objc.viewer
            if viewer ~= nil then
                return viewer.parentViewController
            end
            
            return nil
        end
        
        return objc._getClass(inKey)
   end
}

setmetatable(objc, objc_mt)

--- objc.app: objc.UIApplication
objc.app = objc.UIApplication.sharedApplication

objc.semaphore = function(value)
    local semaphore = {}
    semaphore.pointer = objc.semaphore_create(value)
    semaphore.signal = function(self)
        objc.semaphore_signal(self.pointer)
    end
    semaphore.wait = function(self)
        objc.semaphore_wait(self.pointer)
    end
    return semaphore
end
