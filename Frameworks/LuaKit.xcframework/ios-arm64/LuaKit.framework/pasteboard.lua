function _initPasteboard(objcPasteboard)
    local pasteboard = {
        objcPasteboard = objcPasteboard
    }
    local metatable = {}

    metatable.__index = function(self, key)
        if key == "name" then
            return self.objcPasteboard.name
        elseif key == "numberOfItems" then
            return math.floor(self.objcPasteboard.numberOfItems)
        elseif key == "hasStrings" then
            return self.objcPasteboard.hasStrings
        elseif key == "string" then
            return self.objcPasteboard.string
        elseif key == "strings" then
            return self.objcPasteboard.strings
        elseif key == "hasImages" then
            return self.objcPasteboard.hasImages
        elseif key == "image" then
            return self.objcPasteboard.image
        elseif key == "images" then
            return self.objcPasteboard.images
        elseif key == "hasURLs" then
            return self.objcPasteboard.hasURLs
        elseif key == "url" then
            return self.objcPasteboard.url
        elseif key == "urls" then
            return self.objcPasteboard.urls
        elseif key == "hasColors" then
            return self.objcPasteboard.hasColors
        elseif key == "color" then
            return self.objcPasteboard.color
        elseif key == "colors" then
            return self.objcPasteboard.colors
        elseif viewer.runtime == LEGACY and key == "text" then
            return self.objcPasteboard.string
        end
        return nil
    end

    metatable.__newindex = function(self, key, value)
        if key == "string" then
            self.objcPasteboard.string = value
        elseif key == "strings" then
            self.objcPasteboard.strings = value
        elseif key == "image" then
            self.objcPasteboard.image = value
        elseif key == "images" then
            self.objcPasteboard.images = value
        elseif key == "url" then
            self.objcPasteboard.url = value
        elseif key == "urls" then
            self.objcPasteboard.urls = value
        elseif key == "color" then
            self.objcPasteboard.color = value
        elseif key == "colors" then
            self.objcPasteboard.colors = value
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
            self.objcPasteboard.string = value
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

pasteboard = _initPasteboard(objc.UIPasteboard.generalPasteboard)
pasteboard.initWithName = function(name)
    return _initPasteboard(objc.UIPasteboard:pasteboardWithName_create_(name, true))
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
