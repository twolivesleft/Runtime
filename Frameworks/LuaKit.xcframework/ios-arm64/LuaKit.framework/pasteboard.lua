function _initPasteboard(backend)
    local pasteboard = {
        backend = backend
    }
    local metatable = {}

    metatable.__index = function(self, key)
        if key == "name" then
            return self.backend.name
        elseif key == "numberOfItems" then
            return math.floor(self.backend.numberOfItems)
        elseif key == "hasStrings" then
            return self.backend.hasStrings
        elseif key == "string" then
            return self.backend.string
        elseif key == "strings" then
            return self.backend.strings
        elseif key == "hasImages" then
            return self.backend.hasImages
        elseif key == "image" then
            return self.backend.image
        elseif key == "images" then
            return self.backend.images
        elseif key == "hasURLs" then
            return self.backend.hasURLs
        elseif key == "url" then
            return self.backend.url
        elseif key == "urls" then
            return self.backend.urls
        elseif key == "hasColors" then
            return self.backend.hasColors
        elseif key == "color" then
            return self.backend.color
        elseif key == "colors" then
            return self.backend.colors
        elseif viewer.runtime == LEGACY and key == "text" then
            return self.backend.string
        end
        return nil
    end

    metatable.__newindex = function(self, key, value)
        if key == "string" then
            self.backend.string = value
        elseif key == "strings" then
            self.backend.strings = value
        elseif key == "image" then
            self.backend.image = value
        elseif key == "images" then
            self.backend.images = value
        elseif key == "url" then
            self.backend.url = value
        elseif key == "urls" then
            self.backend.urls = value
        elseif key == "color" then
            self.backend.color = value
        elseif key == "colors" then
            self.backend.colors = value
        elseif key == "name" then
            error("Cannot change the name of a pasteboard")
        elseif key == "numberOfItems" then
            error("Cannot change the number of items in a pasteboard")
        elseif key == "hasStrings" then
            error("Cannot change the hasStrings property of a pasteboard")
        elseif key == "hasImages" then
            error("Cannot change the hasImages property of a pasteboard")
        elseif key == "hasURLs" then
            error("Cannot change the hasURLs property of a pasteboard")
        elseif key == "hasColors" then
            error("Cannot change the hasColors property of a pasteboard")
        elseif viewer.runtime == LEGACY and key == "text" then
            self.backend.string = value
        else
            rawset(self, key, value)
        end
    end

    metatable.__tostring = function(self)
        return "Pasteboard(" .. self.name .. ")"
    end

    setmetatable(pasteboard, metatable)

    return pasteboard
end

if device and device.platform == "android" then
    -- Android: bridge object matching backend's interface,
    -- backed by _android_clipboard JNI calls
    local bridge = {}
    local bridge_mt = {}
    bridge_mt.__index = function(self, key)
        if key == "name" then return "general"
        elseif key == "string" then return _android_clipboard.getString()
        elseif key == "strings" then
            local s = _android_clipboard.getString()
            return s and {s} or {}
        elseif key == "hasStrings" then return _android_clipboard.hasString()
        elseif key == "image" then return _android_clipboard.getImage()
        elseif key == "images" then
            local img = _android_clipboard.getImage()
            return img and {img} or {}
        elseif key == "hasImages" then return _android_clipboard.hasImage()
        elseif key == "url" then return _android_clipboard.getUrl()
        elseif key == "urls" then
            local u = _android_clipboard.getUrl()
            return u and {u} or {}
        elseif key == "hasURLs" then return _android_clipboard.hasUrl()
        elseif key == "color" then return _android_clipboard.getColor()
        elseif key == "colors" then
            local c = _android_clipboard.getColor()
            return c and {c} or {}
        elseif key == "hasColors" then return _android_clipboard.hasColor()
        elseif key == "numberOfItems" then
            if _android_clipboard.hasString() or _android_clipboard.hasImage() or _android_clipboard.hasUrl() then
                return 1
            end
            return 0
        end
    end
    bridge_mt.__newindex = function(self, key, value)
        if key == "string" then _android_clipboard.setString(tostring(value))
        elseif key == "image" then _android_clipboard.setImage(value)
        elseif key == "url" then _android_clipboard.setUrl(tostring(value))
        elseif key == "color" then _android_clipboard.setColor(value)
        end
    end
    setmetatable(bridge, bridge_mt)

    pasteboard = _initPasteboard(bridge)
    pasteboard.initWithName = function(name)
        return pasteboard
    end
else
    pasteboard = _initPasteboard(objc.UIPasteboard.generalPasteboard)
    pasteboard.initWithName = function(name)
        return _initPasteboard(objc.UIPasteboard:pasteboardWithName_create_(name, true))
    end
end

if viewer.runtime == LEGACY then
    pasteboard.copy = function(data)
        if type(data) == "userdata" then
            local mt = getmetatable(data)
            if mt.__name == "codeaimage" then
                pasteboard.image = data
            end
        elseif type(data) == "string" then
            pasteboard.string = data
        end
    end
end
