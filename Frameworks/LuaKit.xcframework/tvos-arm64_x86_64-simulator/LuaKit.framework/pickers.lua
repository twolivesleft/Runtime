UIDocumentPickerDelegate = objc.delegate("UIDocumentPickerDelegate")

function _getAssetKey(path, createBookmark)
    if not createBookmark then
        path = assets.copyToProject(path)
    end

    local assetKey = assets.key(path, createBookmark)
    return assetKey
end

function UIDocumentPickerDelegate:documentPicker_didPickDocumentsAtURLs_(objController, objUrls)
    if self.callback then
        local createBookmark = self.reference
        if self.multiple then
            local results = {}
            for i, objUrl in ipairs(objUrls) do
                local assetKey = _getAssetKey(objUrl.path, createBookmark)
                table.insert(results, assetKey)
            end
            self.callback(results)
        else
            local objUrl = objUrls[1]
            local assetKey = _getAssetKey(objUrl.path, createBookmark)
            self.callback(assetKey)
        end
    end
end

function UIDocumentPickerDelegate:documentPickerWasCancelled_(objController)
    if self.callback then
        self.callback(nil)
    end
end

UIImagePickerControllerDelegate = objc.delegate("UIImagePickerControllerDelegate")

function UIImagePickerControllerDelegate:imagePickerController_didFinishPickingMediaWithInfo_(objController, objInfo)
    objController:dismissViewControllerAnimated_completion_(true, nil)

    if self.callback then
        local createBookmark = self.reference
        local imageURL = objInfo["UIImagePickerControllerImageURL"]
        local assetKey = _getAssetKey(imageURL.path, createBookmark)

        -- Use async_queue since we are on main and the callback might need access to main as well (if we load the actual asset)
        -- Using a queue to avoid doing it on the same one as the copy operation
        self.callback(assetKey)
    end
end

function UIImagePickerControllerDelegate:imagePickerControllerDidCancel_(objController)
    objController:dismissViewControllerAnimated_completion_(true, nil)

    if self.callback then
        self.callback(nil)
    end
end

-- Puts a picker on screen, or says why it could not.
--
-- Only the picker's delegate signals the semaphore that `pick` waits on, and it
-- fires on user interaction alone, so a picker that never reaches the screen
-- parks the project forever with nothing left to wake it. Both ways that can
-- happen are therefore checked before presenting, never after: a document
-- picker is a remote view controller, so it presents asynchronously and
-- `presentedViewController` is still nil on the line after the call.
--
-- Presenting over an existing modal is refused by UIKit ("which is already
-- presenting") and nothing appears. A project being torn down must not present
-- either: cancelling its waits releases it to run the rest of setup on its way
-- out, and a picker put up during that unwind outlives the state that made it
-- and blocks the next run from showing its own.
local function _presentPicker(pickerViewController)
    if objc.shuttingdown() then
        return false, "shutdown"
    end

    if objc.viewer.presentedViewController ~= nil then
        objc.warning("Cannot show the picker, something else is already on screen")
        return false, "busy"
    end

    objc.viewer:presentViewController_animated_completion_(pickerViewController, true, nil)

    return true
end

local function documentPicker(pickOptions, callback)
    local uttypes = {}
    if type(types) == "string" then
        uttypes = {objc.UTType:typeWithIdentifier_(pickOptions.uttypes)}
     else
        for i, typeString in ipairs(pickOptions.uttypes) do
            table.insert(uttypes, objc.UTType:typeWithIdentifier_(typeString))
        end
    end
    --- pickerViewController: objc.UIDocumentPickerViewController
    local asCopy = not pickOptions.asReference
    local pickerViewController = objc.UIDocumentPickerViewController:alloc():initForOpeningContentTypes_asCopy_(uttypes, asCopy)
    local delegate = UIDocumentPickerDelegate()
    delegate.callback = callback
    delegate.multiple = pickOptions.isMultiple
    delegate.reference = pickOptions.asReference
    pickerViewController.delegate = delegate
    pickerViewController.allowsMultipleSelection = pickOptions.isMultiple

    return _presentPicker(pickerViewController)
end

local function photoPicker(pickOptions, callback)
    if pickOptions.isMultiple then
        error("The photo picker does not support multiple selection")
    end
    if pickOptions.asReference then
        error("The photo picker does not support references")
    end
    if #pickOptions.uttypes > 0 then
        error("Cannot specify uttypes for photo picker")
    end
    --- pickerViewController: objc.UIImagePickerController
    local pickerViewController = objc.UIImagePickerController:alloc():init()
    local delegate = UIImagePickerControllerDelegate()
    delegate.callback = callback
    pickerViewController.delegate = delegate
    pickerViewController.sourceType = objc.enum.UIImagePickerControllerSourceType.photoLibrary

    return _presentPicker(pickerViewController)
end

-- The controller holds its delegate weakly, so the delegate lives here until
-- Image Playground calls it back.
local playgroundDelegates = {}
local ImagePlaygroundDelegate = nil

-- Only the first callback counts; the pick waiting on it is signalled once.
local function _finishPlayground(delegate, objController, path)
    if playgroundDelegates[delegate] == nil then
        return
    end
    playgroundDelegates[delegate] = nil

    objController:dismissViewControllerAnimated_completion_(true, nil)

    if path then
        delegate.callback(_getAssetKey(path, false))
    else
        delegate.callback(nil)
    end
end

-- Created on first use: the protocol only exists where ImagePlayground loads.
local function _playgroundDelegate(callback)
    if ImagePlaygroundDelegate == nil then
        ImagePlaygroundDelegate = objc.delegate("ImageGenerationViewControllerDelegate")

        function ImagePlaygroundDelegate:imagePlaygroundViewController_didCreateImageAt_(objController, objURL)
            -- The URL is temporary; the copy into the project is what keeps the image.
            _finishPlayground(self, objController, objURL.path)
        end

        function ImagePlaygroundDelegate:imagePlaygroundViewController_didCreate_(objController, objGlyph)
            _finishPlayground(self, objController, objc.CodeaImagePlayground:heicPathForAdaptiveImageGlyph_(objGlyph))
        end

        function ImagePlaygroundDelegate:imagePlaygroundViewControllerDidCancel_(objController)
            _finishPlayground(self, objController, nil)
        end
    end

    local delegate = ImagePlaygroundDelegate()
    delegate.callback = callback
    return delegate
end

local function _playgroundHelper()
    local cls = objc.getclass("CodeaImagePlayground")
    if cls then
        return wrap(cls)
    end
end

local function _playgroundAvailable()
    local helper = _playgroundHelper()
    return helper ~= nil and helper.available == true
end

local function playgroundPicker(pickOptions, callback)
    if not _playgroundAvailable() then
        objc.warning("Image Playground is not available on this device")
        return false, "unavailable"
    end

    local helper = _playgroundHelper():alloc():initWithConfiguration_(pickOptions.playground)

    local unsupported = helper.unsupported or {}
    local keys = {}
    for key in pairs(unsupported) do
        table.insert(keys, key)
    end
    table.sort(keys)
    for i, key in ipairs(keys) do
        objc.warning("pick.playground: " .. key .. " needs iOS " .. unsupported[key] .. " and was ignored")
    end

    local pickerViewController = helper.controller
    local delegate = _playgroundDelegate(callback)
    pickerViewController.delegate = delegate

    local presented, reason = _presentPicker(pickerViewController)
    if presented then
        playgroundDelegates[delegate] = true
    end
    return presented, reason
end

pick = {
    option = {
        multiple = "pick.option.multiple",
        decodeTable = "pick.option.decodeTable",
        assetKey = "pick.option.assetKey",
        reference = "pick.option.reference",
        image = { "public.image", "com.adobe.pdf" },
        text = "public.text",
        table = { "public.json", "pick.option.decodeTable" },
        json = "public.json",
        sound = "public.audio",
        pdf = "com.adobe.pdf",
    }
}

local function _isPickOption(arg)
    for key, value in pairs(pick.option) do
        if arg == value then
            return true
        end
    end
    return false
end

local function _processPickArguments(args)
    local args = table.flatten(args)

    local result = {
        uttypes = {},
        callback = nil,
        isMultiple = false,
        asReference = false,
        decodeTable = false,
        useAssetKey = false,
    }

    local uttypes = {}

    for i, arg in ipairs(args) do
        if type(arg) == "string" then
            if objc.UTType:typeWithIdentifier_(arg) then
                -- Don't add duplicate uttypes
                if not uttypes[arg] then
                    table.insert(result.uttypes, arg)
                    uttypes[arg] = true
                end
            elseif _isPickOption(arg) then
                -- If we have already seen this option, throw an error
                if arg == pick.option.multiple then
                    result.isMultiple = true
                elseif arg == pick.option.decodeTable then
                    result.decodeTable = true
                elseif arg == pick.option.assetKey then
                    result.useAssetKey = true
                elseif arg == pick.option.reference then
                    result.asReference = true
                else
                    error("Invalid option: " .. arg)
                end
            else
                error("Invalid option or uttype: " .. arg)
            end
        elseif type(arg) == "function" then
            if result.callback then
                error("Only one callback function can be passed as an argument")
            end
            result.callback = arg
        else
            error("Invalid argument type: " .. type(arg))
        end
    end

    if result.useAssetKey and result.decodeTable then
        error("Cannot use both assetKey and decodeTable options")
    end

    return result
end

local function _convertAssetKey(pickOptions, assetKey)
    local assetType = assetKey.type
    if _G[assetType] and _G[assetType].read then
        return _G[assetType].read(assetKey)
    elseif assetType == "image" and readImage then
        -- The legacy runtime loads images with readImage, not image.read
        return readImage(assetKey)
    elseif assetType == "text" then
        content = string.read(assetKey)
        if pickOptions.decodeTable then
            return json.decode(content)
        else
            return content
        end
    elseif assetType == "music" then
        return sound.read(assetKey)
    else
        print("Unknown asset type: " .. assetType)
        return assetKey
    end
end

local function _convertAssetKeys(pickOptions, assetKeys)
    local assets = {}
    if type(assetKeys) == "table" then
        for i, assetKey in ipairs(assetKeys) do
            table.insert(assets, _convertAssetKey(pickOptions, assetKey))
        end
    else
        assets = {_convertAssetKey(pickOptions, assetKeys)}
    end
    return assets
end

local function _processAssetKeys(pickOptions, assetKeys)
    local result = nil

    if pickOptions.useAssetKey then
        result = assetKeys
    elseif assetKeys ~= nil then
        result = _convertAssetKeys(pickOptions, assetKeys)
    end

    if not pickOptions.isMultiple and result ~= nil and type(result) == "table" then
        result = result[1]
    end

    if pickOptions.callback ~= nil then
        pickOptions.callback(result)
    end

    return result
end

local function _doPick(pickOptions, picker)
    if #pickOptions.uttypes == 0 and picker ~= photoPicker and picker ~= playgroundPicker then
        table.insert(pickOptions.uttypes, "public.data")
    end

    local semaphore = nil
    local result = nil

    if pickOptions.callback == nil then
        semaphore = objc.semaphore(0)
    end

    local presented, reason = picker(pickOptions, function(assetKeys)
        -- This must happen on a different background queue in case the file was copied
        -- on the main thread and needs to be read from the callback
        objc.async(objc.async.background,
            -- It is crucial that we wrap the call to _processAssetKeys in a pcall
            -- to make sure the semaphore is signaled even if an error occurs
            function()
                success, result = pcall(_processAssetKeys, pickOptions, assetKeys)

                if pickOptions.callback == nil then
                    semaphore:signal()
                end
            end)
    end)

    if not presented then
        -- Nothing went on screen, so nothing will ever signal us. Hand back an
        -- empty pick instead of parking on a picker that never appeared.
        if reason ~= "shutdown" and pickOptions.callback ~= nil then
            pickOptions.callback(nil)
        end

        return nil
    end

    if pickOptions.callback == nil then
        semaphore:wait()
    end

    if pickOptions.callback == nil then
        return result
    end
end

mt = {
    __call = function(self, ...)
        local pickOptions = _processPickArguments({...})
        return _doPick(pickOptions, documentPicker)
    end
}

setmetatable(pick, mt)

local function _pickType(pickType, picker, types, ...)
    local processedTypes = _processPickArguments(types)
    local pickOptions = _processPickArguments({types, ...})
    if types ~= nil and #types > 0 and #pickOptions.uttypes ~= #processedTypes.uttypes then
        error("Extra uttype passed to pick." .. pickType)
    end
    return _doPick(pickOptions, picker)
end

pick.image = function(...) return _pickType("image", documentPicker, pick.option.image, ...) end
pick.table = function(...) return _pickType("table", documentPicker, pick.option.table, ...) end
pick.text = function(...) return _pickType("text", documentPicker, pick.option.text, ...) end
pick.asset = function(...) return _pickType("asset", documentPicker, {}, pick.option.assetKey, ...) end
pick.photo = function(...) return _pickType("photo", photoPicker, ...) end
pick.sound = function(...) return _pickType("sound", documentPicker, pick.option.sound, ...) end

local function _playgroundConstants(...)
    local constants = {}
    for i, name in ipairs({...}) do
        constants[name] = name
    end
    return constants
end

local playgroundConstants = {
    style = _playgroundConstants("any", "animation", "illustration", "sketch", "emoji", "external"),
    personalization = _playgroundConstants("automatic", "enabled", "disabled"),
    variety = _playgroundConstants("automatic", "high", "low"),
    strategy = _playgroundConstants("automatic", "edit", "generate"),
}

-- "image" or "asset.key" on either runtime, otherwise nil. Legacy images carry
-- no Codea type name, so they are recognised by their size.
local function _playgroundImageKind(value)
    local ok, name = pcall(function() return value.__metaCodeaName end)
    if ok and (name == "image" or name == "asset.key") then
        return name
    end

    if type(value) == "userdata" then
        local ok, sized = pcall(function()
            return type(value.width) == "number" and type(value.height) == "number"
        end)
        if ok and sized then
            return "image"
        end
    end
end

local function _playgroundImage(value, what)
    local kind = _playgroundImageKind(value)
    if kind == "image" then
        return value
    elseif kind == "asset.key" then
        return value.path
    end
    error("Invalid " .. what .. ": expected an image or asset key, got " .. tostring(value))
end

local function _playgroundConcept(entry)
    if type(entry) == "string" then
        return entry
    elseif type(entry) == "table" and _playgroundImageKind(entry) == nil then
        if type(entry.text) ~= "string" then
            error("Invalid concept: a table concept needs a text string")
        end
        if entry.title ~= nil and type(entry.title) ~= "string" then
            error("Invalid concept: title must be a string")
        end
        return { extracted = entry.text, title = entry.title }
    end

    local kind = _playgroundImageKind(entry)
    if kind == "image" then
        return entry
    elseif kind == "asset.key" then
        return { path = entry.path }
    end
    error("Invalid concept: " .. tostring(entry))
end

local function _playgroundConstant(group, value)
    if type(value) ~= "string" or playgroundConstants[group][value] == nil then
        error("Invalid " .. group .. ": " .. tostring(value))
    end
    return value
end

local playgroundOptionKeys = {
    concepts = true, source = true, style = true, styles = true,
    personalization = true, variety = true, strategy = true, size = true,
}

local function _processPlaygroundOptions(options, configuration)
    for key in pairs(options) do
        if not playgroundOptionKeys[key] then
            error("Invalid option: " .. tostring(key))
        end
    end

    if type(options.concepts) == "string" then
        table.insert(configuration.concepts, options.concepts)
    elseif type(options.concepts) == "table" and _playgroundImageKind(options.concepts) == nil then
        for i, entry in ipairs(options.concepts) do
            table.insert(configuration.concepts, _playgroundConcept(entry))
        end
    elseif options.concepts ~= nil then
        error("Invalid concepts: expected a string or a table of concepts")
    end

    if options.source ~= nil then
        configuration.source = _playgroundImage(options.source, "source")
    end

    for i, group in ipairs({"style", "personalization", "variety", "strategy"}) do
        if options[group] ~= nil then
            configuration[group] = _playgroundConstant(group, options[group])
        end
    end

    if options.styles ~= nil then
        if type(options.styles) ~= "table" or #options.styles == 0 then
            error("Invalid styles: expected a table of pick.playground.style values")
        end
        configuration.styles = {}
        for i, style in ipairs(options.styles) do
            table.insert(configuration.styles, _playgroundConstant("style", style))
        end
    end

    if configuration.style and configuration.styles then
        local offered = false
        for i, style in ipairs(configuration.styles) do
            offered = offered or style == configuration.style
        end
        if not offered then
            error("Invalid style: " .. configuration.style .. " is not one of styles")
        end
    end

    if options.size ~= nil then
        local ok, width, height = pcall(function() return options.size.x, options.size.y end)
        if not ok or type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then
            error("Invalid size: expected a vec2 with a positive width and height")
        end
        configuration.size = { width, height }
    end
end

local function _processPlaygroundArguments(args)
    local result = {
        uttypes = {},
        callback = nil,
        isMultiple = false,
        asReference = false,
        decodeTable = false,
        useAssetKey = false,
    }

    local configuration = { concepts = {} }
    local options = nil

    for i = 1, args.n do
        local arg = args[i]
        if type(arg) == "string" then
            if arg == pick.option.assetKey then
                result.useAssetKey = true
            elseif arg == pick.option.multiple then
                error("Image Playground does not support multiple selection")
            elseif arg == pick.option.reference then
                error("Image Playground does not support references")
            elseif _isPickOption(arg) then
                error("Invalid option: " .. arg)
            else
                table.insert(configuration.concepts, arg)
            end
        elseif type(arg) == "function" then
            if result.callback then
                error("Only one callback function can be passed as an argument")
            end
            result.callback = arg
        elseif type(arg) == "table" then
            if options then
                error("Only one options table can be passed as an argument")
            end
            options = arg
        else
            error("Invalid argument type: " .. type(arg))
        end
    end

    if options then
        _processPlaygroundOptions(options, configuration)
    end

    if #configuration.concepts == 0 then
        configuration.concepts = nil
    end

    result.playground = configuration
    return result
end

pick.playground = setmetatable({
    style = playgroundConstants.style,
    personalization = playgroundConstants.personalization,
    variety = playgroundConstants.variety,
    strategy = playgroundConstants.strategy,
}, {
    __index = function(self, key)
        if key == "available" then
            return _playgroundAvailable()
        end
    end,
    __call = function(self, ...)
        local pickOptions = _processPlaygroundArguments(table.pack(...))
        return _doPick(pickOptions, playgroundPicker)
    end
})
