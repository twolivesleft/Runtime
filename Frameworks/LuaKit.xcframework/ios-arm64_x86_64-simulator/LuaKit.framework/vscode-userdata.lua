local function getUserDataType(var)
    if var.r ~= nil and var.g ~= nil and var.b ~= nil and var.a ~= nil and var.mix ~= nil then
        return "color"
    end
    
    if var.x ~= nil and var.y ~= nil and var.dot ~= nil and var.normalize ~= nil then
        return "vector"
    end
    
    if var.prevPos ~= nil then
        return "touch"
    end
    
    local mt = getmetatable(var)
    
    if mt and (string.find(mt.__name, "codeaimage") or string.find(mt.__name, "Carbide::Image")) then
        return "image"
    end
    
    return "unknown"
end

local function canWriteUserData(var)
    local userDataType = getUserDataType(var)
    
    if userDataType == "color" or userDataType == "vector" then
        return true
    end
    
    return false
end

local function addVars(var, addVar, vars)
    for i, v in ipairs(vars) do
        if var[v] ~= nil then
            addVar(v, var[v])
        end
    end
end

function addUserdataVar(var, addVar)
    local userDataType = getUserDataType(var)
    
    if userDataType == "color" then
        addVars(var, addVar, {"r", "g", "b", "a"})
    end
    
    if userDataType == "vector" then
        addVars(var, addVar, {"x", "y", "z", "w"})
    end

    if userDataType == "touch" then
        addVars(var, addVar, {
            "x", "y", "pos", "prevPos", "prevX", "prevY", "deltaX", "deltaY",
            "delta", "id", "state", "type", "tapCount", "radius", "radiusTolerance",
            "force", "maxForce", "precisePos", "precisePrevPos", "altitude", "azimuth",
            "azimuthVec", "timestamp"
        })
    end
    
    if userDataType == "image" then
        addVars(var, addVar, {
            "width", "height", "rawWidth", "rawHeight", "premultiplied", "scale",
            "depth", "numLayers", "hasMips", "cubeMap", "volume", "numMips", "format"
        })
    end
end

function setUserdataVar(var, varName, varValue)
    if not canWriteUserData(var) then
        return var[varName]
    end
    
    var[varName] = varValue
    
    return var[varName]
end
