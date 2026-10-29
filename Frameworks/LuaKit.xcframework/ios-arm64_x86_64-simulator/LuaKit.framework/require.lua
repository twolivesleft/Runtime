local _defaultRequire = require

local _baseAsset = {
    current = asset.current,
    builtin = asset.builtin,
    documents = asset.documents,
}
if asset.icloud then _baseAsset.icloud = asset.icloud end
if asset.Dependencies then _baseAsset.Dependencies = asset.Dependencies end

local _requireEnvStack = { _ENV }

-- This is used to detect circular require calls and prevent making the editor unresponsive
local _requireQueue = {}

-- Platform detection
local _isAndroid = (device and device.platform == "android")
local _isApple = not _isAndroid

-- Platform-specific file loading

local _coordinatedRequire
local _listDirectory
local _isDirectory
local _encodeUrl
local _getChunkNameForPath

if _isApple then
    -- iOS: use NSFileCoordinator for iCloud-safe file access
    _encodeUrl = function(text)
        local textString = objc.string(text)
        local characterSet = objc.NSCharacterSet.URLPathAllowedCharacterSet
        return textString:stringByAddingPercentEncodingWithAllowedCharacters_(characterSet)
    end

    _getChunkNameForPath = function(path)
        local pathString = objc.string(path)

        local bufferName = pathString:lastPathComponent_()

        local withoutFilename = objc.string(pathString:stringByDeletingLastPathComponent_())
        local projectFolder = objc.string(withoutFilename:lastPathComponent_())
        local projectName = projectFolder:stringByReplacingOccurrencesOfString_withString_(".codea", "")

        local withoutProject = objc.string(withoutFilename:stringByDeletingLastPathComponent_())
        local collectionName = withoutProject:lastPathComponent_()

        local chunkName = "@" .. collectionName .. "/" .. projectName .. "/" .. bufferName
        return _encodeUrl(chunkName)
    end

    local function assetKeyLoader(path)
        if not string.match(path, "^assetKey/") then
            return nil
        end

        path = string.match(path, "assetKey/(.*)")

        local env = _requireEnvStack[#_requireEnvStack]
        local chunkName = _getChunkNameForPath(path)
        local pathString = objc.string(path)
        local content = objc.NSString:stringWithContentsOfFile_encoding_error_(pathString, objc.enum.NSUTF8StringEncoding, nil)
        local file, err = load(content, chunkName, "t", env)

        if file then
            return file, chunkName
        else
            return "\n\tCannot load " .. path .. ": " .. err
        end
    end

    -- Don't replace the first searcher since it will take care of the package.preload table
    table.insert(package.searchers, 2, assetKeyLoader)

    _coordinatedRequire = function(directory, filename)
        local result = nil
        local coordinator = objc.NSFileCoordinator:alloc():initWithFilePresenter_(nil)
        local path = directory .. "/" .. filename .. ".lua"

        if _requireQueue[path] then
            warning("\n\tCircular require detected:\n" .. filename)
            return "\n\tCircular require detected:\n" .. filename
        end

        _requireQueue[path] = true

        local url = objc.NSURL:fileURLWithPath_(path)

        local readingIntent = objc.NSFileAccessIntent:readingIntentWithURL_options_(url, 2) -- NSFileCoordinatorReadingWithoutChanges

        local queue = objc.NSOperationQueue()
        queue.maxConcurrentOperationCount = 1

        local semaphore = objc.semaphore(0)

        coordinator:coordinateAccessWithIntents_queue_byAccessor_(
            { readingIntent },
                queue,
            function(objError)
                if objError == nil then
                    status, result = pcall(_defaultRequire, "assetKey/" .. readingIntent.URL.path)
                    if status == false then
                        warning("\n\tError loading " .. filename .. " error: " .. result)
                        result = "\n\tError loading " .. filename .. " error: " .. result
                    end
                    semaphore:signal()
                else
                    result = "\n\tCould not load " .. path
                    semaphore:signal()
                end
            end)

        semaphore:wait()

        _requireQueue[path] = nil

        return result
    end

    _listDirectory = function(dirPath)
        local fileManager = objc.NSFileManager.defaultManager
        local enumerator = fileManager:enumeratorAtPath_(dirPath)
        if enumerator == nil then return {} end
        local files = enumerator.allObjects
        if files == nil then return {} end
        local result = {}
        for i = 1, #files do
            table.insert(result, files[i])
        end
        return result
    end

    _isDirectory = function(path)
        local fileManager = objc.NSFileManager.defaultManager
        local enumerator = fileManager:enumeratorAtPath_(path)
        if enumerator == nil then return false end
        -- enumeratorAtPath_ hands back a non-nil enumerator for a plain file
        -- too, it just yields nothing - so the emptiness check is what actually
        -- separates a file from a directory. Without it every .lua file looks
        -- like a directory and require() loads nothing from it.
        local files = enumerator.allObjects
        return files ~= nil and #files > 0
    end

else
    -- Android / generic: direct file I/O (no iCloud coordination)
    local function readFile(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local content = f:read("*a")
        f:close()
        return content
    end

    _coordinatedRequire = function(directory, filename)
        local path = directory .. "/" .. filename .. ".lua"

        if _requireQueue[path] then
            warning("\n\tCircular require detected:\n" .. filename)
            return "\n\tCircular require detected:\n" .. filename
        end

        _requireQueue[path] = true

        local env = _requireEnvStack[#_requireEnvStack]
        local content = readFile(path)
        if not content then
            _requireQueue[path] = nil
            return "\n\tCould not load " .. path
        end

        local chunkName = "@" .. filename .. ".lua"
        local file, err = load(content, chunkName, "t", env)
        if file then
            local status, result = pcall(file)
            if not status then
                warning("\n\tError loading " .. filename .. " error: " .. result)
                _requireQueue[path] = nil
                return "\n\tError loading " .. filename .. " error: " .. result
            end
            _requireQueue[path] = nil
            return result
        else
            warning("\n\tCannot load " .. path .. ": " .. err)
            _requireQueue[path] = nil
            return "\n\tCannot load " .. path .. ": " .. err
        end
    end

    _listDirectory = function(dirPath)
        local files = {}
        local ok, lfs = pcall(_defaultRequire, "lfs")
        if not ok then return files end
        local iter, dir_obj = lfs.dir(dirPath)
        if not iter then return files end
        for entry in iter, dir_obj do
            if entry ~= "." and entry ~= ".." then
                table.insert(files, entry)
            end
        end
        return files
    end

    _isDirectory = function(path)
        local ok, lfs = pcall(_defaultRequire, "lfs")
        if not ok then return false end
        local attr = lfs.attributes(path)
        return attr and attr.mode == "directory"
    end
end

-- Shared logic

local function pushRequireEnvironment(root, callingEnvironment)
    local env = nil

    if root ~= nil then
        -- New root asset for the required project
        local newAsset = setmetatable({}, {
            __index = function(_, k)
                return _baseAsset[k] or root[k]
            end,
            __concat = function(_, v)
                return root .. v
            end,
            __tostring = function()
                return tostring(root)
            end
        })

        -- Passthrough to the calling environment
        env = setmetatable({
            asset = newAsset -- Redirect root asset to the required project's root
        }, {
            __index = callingEnvironment
        })
    else
        -- Passthrough to the calling environment
        env = setmetatable({},
            {
                __index = callingEnvironment
            }
        )
    end

    -- Push new environment
    table.insert(_requireEnvStack, env)
end

local function popRequireEnvironment()
    -- Return the top environment
    return table.remove(_requireEnvStack)
end

local function normalizeBufferOrderEntry(entry)
    if type(entry) ~= "string" or entry == "" then
        return nil
    end

    -- Folder placeholders are valid in project metadata but cannot be required.
    if string.sub(entry, -1) == "/" or string.sub(entry, -1) == "\\" then
        return nil
    end

    local lowerEntry = string.lower(entry)
    if string.match(lowerEntry, "%.lua$") then
        return string.gsub(entry, "%.[Ll][Uu][Aa]$", "")
    end

    if string.find(entry, "/", 1, true) or string.find(entry, "\\", 1, true) or string.match(entry, "%.[^/\\]+$") then
        return nil
    end

    -- Legacy fallback: top-level tab names without an extension.
    return entry
end

-- Get the path from an asset key (works with both userdata and table asset keys)
local function getAssetPath(name)
    if type(name) == "userdata" and name.path ~= nil then
        return name.path
    elseif type(name) == "table" then
        if name.path then return name.path end
        if name._path then return name._path end
        local s = tostring(name)
        if s and s ~= "" and not s:match("^table:") then
            return s:gsub("/$", "")
        end
    end
    return nil
end

-- Parse Buffer Order from Info.plist
-- iOS: use NSDictionary plist loading; Android: simple XML pattern matching
local function getBufferOrder(dirPath, files)
    local bufferOrder = {}

    local hasPlist = false
    for _, file in ipairs(files) do
        if file == "Info.plist" then hasPlist = true break end
    end
    if not hasPlist then return bufferOrder end

    if _isApple then
        local plist = objc.NSDictionary:dictionaryWithContentsOfFile_(dirPath .. "/Info.plist")
        if plist then
            local bo = plist["Buffer Order"]
            if bo then
                for i = 1, #bo do
                    table.insert(bufferOrder, bo[i])
                end
            end
        end
    else
        local f = io.open(dirPath .. "/Info.plist", "r")
        if f then
            local content = f:read("*a")
            f:close()
            local arrayContent = content:match("<key>Buffer Order</key>%s*<array>(.-)</array>")
            if arrayContent then
                for name in arrayContent:gmatch("<string>(.-)</string>") do
                    table.insert(bufferOrder, name)
                end
            end
        end
    end

    return bufferOrder
end

require = {
    option = {
        loadMain = "require.option.loadMain",
        noImport = "require.option.noImport"
    }
}

-- Implement the below function as a __call on require

_require_mt = {
    __call = function(self, name, ...)
        local assetPath = getAssetPath(name)

        if assetPath ~= nil then

            -- Parse ... for require.option and set locals accordingly
            local options = {
                loadMain = false,
                import = true,
            }
            for _, option in ipairs({...}) do
                if option == require.option.loadMain then
                    options.loadMain = true
                elseif option == require.option.noImport then
                    options.import = false
                else
                    error("Invalid option: " .. option)
                end
            end

            local result = nil
            local extension = string.match(assetPath, ".*%.(.*)")
            local didStartAccessing = false
            if type(name.startAccessing) == "function" then
                didStartAccessing = name:startAccessing()
            end

            local callingEnvironment = nil
            do -- Obtain the environment of the caller
                local info = debug.getinfo(2, 'f')
                local upName, value = debug.getupvalue(info.func, 1)
                if upName ~= "_ENV" then
                    error("Unable to require from current location!", 2)
                end
                callingEnvironment = value
            end

            -- Test if it's a directory
            if _isDirectory(assetPath) then
                local files = _listDirectory(assetPath)

                local bufferOrder = getBufferOrder(assetPath, files)

                local luaFiles = {}
                for _, file in ipairs(files) do
                    if string.match(file, "%.lua$") then
                        table.insert(luaFiles, file)
                    end
                end

                if #bufferOrder > 0 then
                    local remainingFiles = {}
                    for i = 1, #luaFiles do
                        remainingFiles[luaFiles[i]] = true
                    end

                    local orderedLuaFiles = {}
                    for _, bufferName in ipairs(bufferOrder) do
                        local normalizedName = normalizeBufferOrderEntry(bufferName)
                        if normalizedName ~= nil then
                            local file = normalizedName .. ".lua"
                            if remainingFiles[file] then
                                table.insert(orderedLuaFiles, file)
                                remainingFiles[file] = nil
                            end
                        end
                    end

                    for i = 1, #luaFiles do
                        local file = luaFiles[i]
                        if remainingFiles[file] then
                            table.insert(orderedLuaFiles, file)
                        end
                    end

                    luaFiles = orderedLuaFiles
                end

                -- Only load Main.lua if we've been explicitly told to do so.
                local loadMain = options.loadMain

                -- Push a new environment
                pushRequireEnvironment(name, callingEnvironment)

                for i = 1, #luaFiles do
                    local file = luaFiles[i]
                    if loadMain or file ~= "Main.lua" then
                        local filename = string.gsub(file, "%.lua$", "")
                        _coordinatedRequire(assetPath, filename)
                    end
                end

                -- Pop the new environment
                result = popRequireEnvironment()

                -- Import into the calling environment
                if options.import then
                    for k,v in pairs(result) do
                        if k ~= "asset" then
                            callingEnvironment[k] = v
                        end
                    end
                end

            elseif extension == "lua" then
                -- Extract the filename without extension from assetPath
                local filename = string.match(assetPath, ".*/(.*)%..*")

                -- Extract the directory from assetPath
                local directory = string.match(assetPath, "(.*)/")

                -- Check if the file is under a .codea bundle
                local bundle = assetPath:match("(.*%.codea)")

                local fromBundle = bundle ~= nil
                local assetLibrary = nil

                if fromBundle and type(assets) == "function" then
                    assetLibrary = assets(bundle)
                end

                -- Push a new environment
                pushRequireEnvironment(assetLibrary, callingEnvironment)

                result = _coordinatedRequire(directory, filename)

                -- Pop the new environment
                local poppedEnvironment = popRequireEnvironment()

                -- Import into the calling environment
                if options.import then
                    for k,v in pairs(poppedEnvironment) do
                        if k ~= "asset" then
                            callingEnvironment[k] = v
                        end
                    end
                end
            else
                warning("When used with an AssetKey, require() only supports folders and lua files.")
            end

            if didStartAccessing then
                name:stopAccessing()
            end

            if _debuggee ~= nil and _debuggee.refreshBreakpoints ~= nil then
                _debuggee.refreshBreakpoints()
            end

            return result
        end

        return _defaultRequire(name)
    end
}

setmetatable(require, _require_mt)
