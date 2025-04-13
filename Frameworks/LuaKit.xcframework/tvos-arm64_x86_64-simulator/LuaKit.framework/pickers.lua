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
    objc.viewer:presentViewController_animated_completion_(pickerViewController, true, nil)
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
    objc.viewer:presentViewController_animated_completion_(pickerViewController, true, nil)
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
    if #pickOptions.uttypes == 0 and picker ~= photoPicker then
        table.insert(pickOptions.uttypes, "public.data")
    end

    local semaphore = nil
    local result = nil

    if pickOptions.callback == nil then
        semaphore = objc.semaphore(0)
    end

    picker(pickOptions, function(assetKeys)
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
