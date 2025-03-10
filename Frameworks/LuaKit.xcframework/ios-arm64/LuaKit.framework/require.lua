local _defaultRequire = require

local _baseAsset = {
    builtin = asset.builtin,
    documents = asset.documents,
    icloud = asset.icloud
}
local _requireEnvStack = { _ENV }

-- This is used to detect circular require calls and prevent making the editor unresponsive
local _requireQueue = {}

local _coordinatedRequire = function(directory, filename)
    local result = nil
    local coordinator = objc.NSFileCoordinator:alloc():initWithFilePresenter_(nil)
    local path = directory .. "/" .. filename .. ".lua"
    
    if _requireQueue[path] then
        warning("\n\tCircular require detected:\n" .. filename)
        return "\n\tCircular require detected:\n" .. filename
    end
    
    _requireQueue[path] = true

    local url = objc.NSURL:fileURLWithPath_(path)
    
    local readingIntent = objc.NSFileAccessIntent:readingIntentWithURL_options_(url, 0)

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
                    warning("\n\tError loading " .. filename)
                    result = "\n\tError loading " .. filename
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

local function encodeUrl(text)
    local textString = objc.string(text)
    local characterSet = objc.NSCharacterSet.URLPathAllowedCharacterSet
    return textString:stringByAddingPercentEncodingWithAllowedCharacters_(characterSet)
end

local function getChunkNameForPath(path)
    local pathString = objc.string(path)
    
    local bufferName = pathString:lastPathComponent_()

    local withoutFilename = objc.string(pathString:stringByDeletingLastPathComponent_())
    local projectFolder = objc.string(withoutFilename:lastPathComponent_())
    local projectName = projectFolder:stringByReplacingOccurrencesOfString_withString_(".codea", "")
    
    local withoutProject = objc.string(withoutFilename:stringByDeletingLastPathComponent_())
    local collectionName = withoutProject:lastPathComponent_()
    
    local chunkName = "@" .. collectionName .. "/" .. projectName .. "/" .. bufferName
    return encodeUrl(chunkName)
end

local function assetKeyLoader(path)
    -- if path does not start with "assetKey/", return nil
    if not string.match(path, "^assetKey/") then
        return nil
    end
    
    -- Extract the path after assetKey/
    path = string.match(path, "assetKey/(.*)")
    
    local env = _requireEnvStack[#_requireEnvStack]
    local chunkName = getChunkNameForPath(path)
    local pathString = objc.string(path)
    local content = objc.NSString:stringWithContentsOfFile_encoding_error_(pathString, objc.enum.NSUTF8StringEncoding, nil)
    local file, err = load(content, chunkName, "t", env)
    
    if file then
        return file, chunkName
    else
        return "\n\tCannot load " .. path .. ": " .. err
    end
end

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

-- Don't replace the first searcher since it will take care of the package.preload table
table.insert(package.searchers, 2, assetKeyLoader)

require = {
    option = {
        loadMain = "require.option.loadMain",
        noImport = "require.option.noImport"
    }
}

-- Implement the below function as a __call on require

_require_mt = {
    __call = function(self, name, ...)
        if type(name) == "userdata" and name.path ~= nil then
        
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
            local extension = string.match(name.path, ".*%.(.*)")
            local didStartAccessing = false
            if type(name.startAccessing) == "function" then
                didStartAccessing = name:startAccessing()
            end
            
            local callingEnvironment = nil
            do -- Obtain the environment of the caller
                local info = debug.getinfo(2, 'f')
                local name, value = debug.getupvalue(info.func, 1)
                if name ~= "_ENV" then
                    error("Unable to require from current location!", 2)
                end
                callingEnvironment = value
            end
            
            -- Test if it's a directory
            local fileManager = objc.NSFileManager.defaultManager
            local files = fileManager:contentsOfDirectoryAtPath_error_(name.path, nil)
            if files ~= nil then
                
                local bufferOrder = {}
                for i = 1, #files do
                    if files[i] == "Info.plist" then
                        local plist = objc.NSDictionary:dictionaryWithContentsOfFile_(name.path .. "/Info.plist")
                        bufferOrder = plist["Buffer Order"]
                    end
                end
                
                if #bufferOrder > 0 then
                    local orderMap = {}
                    for i, name in ipairs(bufferOrder) do
                        orderMap[name .. ".lua"] = i
                    end

                    table.sort(files, function(a, b)
                        -- Use the mapped order, defaulting to a high value to sort unmatched files last
                        local aOrder = orderMap[a] or #bufferOrder + 1
                        local bOrder = orderMap[b] or #bufferOrder + 1
                        return aOrder < bOrder
                    end)
                end
                
                -- Only load Main.lua if we've been explicitly told to do so.
                local loadMain = options.loadMain
                
                -- Push a new environment
                pushRequireEnvironment(name, callingEnvironment)
                
                for i = 1, #files do
                    --- file: objc.NSString
                    local file = files[i]

                    if string.match(file, ".*%.lua") and (loadMain or file ~= "Main.lua") then
                        -- Extract the filename without extenssion from name.path
                        local filename = string.match(file, "(.*)%..*")
                        _coordinatedRequire(name.path, filename)
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
                -- Extract the filename without extension from name.path
                local filename = string.match(name.path, ".*/(.*)%..*")
                
                -- Extract the directory from name.path
                local directory = string.match(name.path, ".*/")

                -- Check if the file is under a .codea bundle
                local bundle = name.path:match("(.*%.codea)")

                local fromBundle = bundle ~= nil
                local assetLibrary = nil

                if fromBundle then
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
