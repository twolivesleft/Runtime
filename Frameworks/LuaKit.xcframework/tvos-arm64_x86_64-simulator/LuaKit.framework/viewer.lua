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
    paused = propertyAccess("paused"),
    isPresenting = function(obj)
        if device and device.platform == "android" then
            return false -- TODO: wire up dialog tracking via JNI
        else
            return obj.presentedViewController ~= nil
        end
    end
}

-- Resolve the platform backend on every access. On iOS, `objc._viewerContainer`
-- is a dynamic accessor that walks the live UIKit hierarchy (see LuaBridge.lua),
-- so it returns nil while this module is being required during Runtime init and
-- only becomes valid once the view controller is attached. Caching the result
-- once at load time would capture nil permanently. Android's `_android_viewer`
-- is a plain global registered before Lua loads, so re-resolving is a no-op.
local function getBackend()
    if device and device.platform == "android" then
        return _android_viewer
    elseif objc then
        return objc._viewerContainer
    end
end

local mt = {
    __newindex = function(self, key, value)
        if props[key] then
            local backend = getBackend()
            if backend then
                props[key](backend, value)
            end
        else
            rawset(self, key, value)
        end
    end,
    __index = function(self, key)
        if props[key] then
            local backend = getBackend()
            if backend then
                return props[key](backend)
            end
        else
            return rawget(self, key)
        end
    end
}

setmetatable(viewer, mt)

function viewer.close()
    getBackend():close()
end

function viewer.restart()
    getBackend():restart()
end

function viewer.snapshot()
    return getBackend().snapshot
end

function viewer.alert(message, title)
    if device and device.platform == "android" then
        getBackend().alert(title or "Alert", message or "No Message")
    elseif objc then
        --- alert: objc.UIAlertController
        local alert = objc.UIAlertController:alertControllerWithTitle_message_preferredStyle_(title or "Alert", message or "No Message", objc.enum.UIAlertControllerStyle.alert)

        --- action: objc.UIAlertAction
        local action = objc.UIAlertAction:actionWithTitle_style_handler_("OK", objc.enum.UIAlertActionStyle.default, nil)

        alert:addAction_(action)

        objc._viewerContainer:presentModalViewController_animated_(alert, true)
    end
end

function viewer.share(data)
    if device and device.platform == "android" then
        getBackend().share(data)
    elseif objc then
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
end

function viewer.resize(width, height)
    if device and device.platform == "android" then
        warning("viewer.resize() is not supported on Android")
    elseif objc and objc._viewerContainer then
        objc._viewerContainer:resizeWithWidth_height_(width, height)
    end
end

return viewer
