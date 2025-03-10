local viewer = {
    STANDARD = 0,
    FULLSCREEN = 1,
    FULLSCREEN_NO_BUTTONS = 2,
    OVERLAY = 3,
    LEGACY = 0,
    MODERN = 1
}

-- Globals
STANDARD = viewer.STANDARD
FULLSCREEN = viewer.FULLSCREEN
FULLSCREEN_NO_BUTTONS = viewer.FULLSCREEN_NO_BUTTONS
OVERLAY = viewer.OVERLAY
LEGACY = viewer.LEGACY
MODERN = viewer.MODERN

local function propertyAccess(key, deprecationMessage, readOnly)
    return function(obj, value)
        if deprecationMessage ~= nil then
            warning(deprecationMessage)
        end
        
        if value ~= nil then
            if readOnly ~= true then
                obj[key] = value
            else
                warning("Cannot set read-only property " .. key)
            end
        else
            return obj[key]
        end
    end
end

local props = {
    mode = function(obj, value)
        if value ~= nil then
            if value == viewer.OVERLAY then
                warning("`OVERLAY` viewer mode is deprecated. Please use `STANDARD`")
                value = viewer.STANDARD
            end
            
            obj.mode = value
        else
            return obj.mode
        end
    end,
    preferredFPS = propertyAccess("preferredFPS", "`viewer.preferredFPS` is deprecated. Please use `viewer.framerate`"),
    framerate = propertyAccess("preferredFPS"),
    showWarnings = propertyAccess("showWarnings"),
    displayStats = propertyAccess("displayStats"),
    drawOnRequest = propertyAccess("drawOnRequest"),
    pointerLocked = propertyAccess("prefersPointerLocked"),
    safeArea = propertyAccess("safeArea"),
    runtime = propertyAccess("runtime", nil, true),
    uniformResizing = propertyAccess("uniformResizing"),
    isPresenting = function(obj)
        return obj.presentedViewController ~= nil
    end
}

local mt = {
    __newindex = function(self, key, value)
        if props[key] then
            if objc._viewerContainer ~= nil then
                props[key](objc._viewerContainer, value)
            end
        else
            rawset(self, key, value)
        end
    end,
    __index = function(self, key)
        if props[key] then
            if objc._viewerContainer ~= nil then
                return props[key](objc._viewerContainer)
            end
        else
            return rawget(self, key)
        end
    end
}

setmetatable(viewer, mt)

function viewer.close()
    objc._viewerContainer:close()
end

function viewer.restart()
    objc._viewerContainer:restart()
end

function viewer.snapshot()
    return objc._viewerContainer.snapshot
end

function viewer.alert(message, title)
    --- alert: objc.UIAlertController
    local alert = objc.UIAlertController:alertControllerWithTitle_message_preferredStyle_(title or "Alert", message or "No Message", objc.enum.UIAlertControllerStyle.alert)
    
    --- action: objc.UIAlertAction
    local action = objc.UIAlertAction:actionWithTitle_style_handler_("OK", objc.enum.UIAlertActionStyle.default, nil)
    
    alert:addAction_(action)
    
    objc._viewerContainer:presentModalViewController_animated_(alert, true)
end

function viewer.share(data)
    if type(data) ~= "table" then
        data = {data}
    end
    
    --- bounds: objc.rect
    local bounds = objc._viewerContainer.view.bounds
    
    --- activity: objc.UIActivityViewController
    local activity = objc.UIActivityViewController:alloc():initWithActivityItems_applicationActivities_(data, nil)
    
    activity.popoverPresentationController.sourceView = objc._viewerContainer.view
    activity.popoverPresentationController.sourceRect = objc.rect(bounds.size.width/2.0, bounds.size.height/2.0, 50, 20)
    activity.modalPresentationStyle = objc.enum.UIModalPresentationStyle.UIModalPresentationPopover
    
    objc._viewerContainer:presentModalViewController_animated_(activity, true)
end

function viewer.resize(width, height)
    objc._viewerContainer:resizeWithWidth_height_(width, height)
end

return viewer
