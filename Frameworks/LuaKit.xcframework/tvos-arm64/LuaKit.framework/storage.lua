
-- storage.lua
--
-- Simple key/value storage for Carbide (Modern Codea).
--
-- Backed by JSON and the built-in string.read / string.save functions.
-- Scopes:
--   - storage (default) / storage.project : per-project storage under `asset`
--   - storage.global                      : device-wide storage under `asset.documents`
--
-- Files are stored using reserved, low-collision names:
--   - Project: asset .. ".carbide_storage.json"
--   - Global : asset.documents .. ".carbide_storage.global.json"
--
-- API:
--   storage:get(key [, default])
--   storage:set(key, value)       -- value == nil deletes key
--   storage:has(key)
--   storage:delete(key)
--   storage:keys()                -- sorted array of keys
--   storage:clear()
--   storage:asset()               -- returns underlying asset key
--   storage:namespace(prefix)     -- returns view that prefixes keys (e.g. "prefs.")
--
-- Notes:
-- - Keys must be strings.
-- - Values must be JSON-encodable (nil/boolean/number/string/table).
-- - Writing is immediate.

local json = json  -- David Kolf JSON module v2.5 (provided by Carbide)

local Storage = {}
Storage.__index = function(self, key)
    local value = Storage[key]
    if value ~= nil then
        return value
    end
    if type(key) ~= "string" then
        return nil
    end
    if key:sub(1, 1) == "_" then
        return rawget(self, key)
    end
    if self:has(key) then
        return self:get(key)
    end
    local warned = rawget(self, "_warnedMissingKeys")
    if warned and not warned[key] then
        print("storage: missing key '" .. tostring(key) .. "'")
        warned[key] = true
    end
    return nil
end

Storage.__newindex = function(self, key, value)
    if Storage[key] ~= nil then
        rawset(self, key, value)
        return
    end
    if type(key) ~= "string" then
        rawset(self, key, value)
        return
    end
    if key:sub(1, 1) == "_" then
        rawset(self, key, value)
        return
    end
    self:set(key, value)
end

-- --------- configuration (naming convention) ---------
-- Use dot-prefixed filenames to reduce collisions with user files.
-- Still not "impossible" to collide, but extremely unlikely and clearly reserved.

-- local PROJECT_FILENAME = ".carbide_storage.json"
-- local GLOBAL_FILENAME  = ".carbide_storage.global.json"
local STORE_PREFIX = ".carbide_store_"
local STORE_SUFFIX = ".json"

-- Optional: versioning inside the store (for future migrations)
local STORE_VERSION = 1

local _projectStores = {}
local _globalStores  = {}

-- --------- utilities ---------

local function sanitizeStoreName(name)
    if type(name) ~= "string" then
        error("storage: store name must be a string", 3)
    end
    if name == "" then
        error("storage: store name cannot be empty", 3)
    end

    -- Keep only safe filename chars; replace others with "_"
    -- Also prevents path traversal like "../"
    local safe = name:gsub("[^%w%._%-]", "_")

    -- Avoid accidental leading dots beyond our own prefix semantics
    safe = safe:gsub("^%.*", "")

    return safe
end

local function storeFilename(name)
    return STORE_PREFIX .. sanitizeStoreName(name) .. STORE_SUFFIX
end

local function newStore(rootAsset, filename)
    return setmetatable({
        rootAsset = rootAsset,
        filename = filename,
        _cache = nil,
        _dirty = false,
        _warnedMissingKeys = {},
    }, Storage)
end

local function getOrCreateStore(name, scope)
    local filename = storeFilename(name)

    if scope == "global" then
        local existing = _globalStores[filename]
        if existing then return existing end
        local s = newStore(asset.documents, filename)
        _globalStores[filename] = s
        return s
    else
        -- default: project scope
        local existing = _projectStores[filename]
        if existing then return existing end
        local s = newStore(asset, filename)
        _projectStores[filename] = s
        return s
    end
end

local function assertStringKey(key)
    if type(key) ~= "string" then
        error("storage: key must be a string", 3)
    end
end

local function sortedKeys(t)
    local out = {}
    for k, _ in pairs(t) do
        if k ~= "__version" and k ~= "__meta" then
            out[#out + 1] = k
        end
    end
    table.sort(out)
    return out
end

-- --------- core storage implementation ---------

function Storage:_asset()
    -- Asset keys are built by concatenation: asset .. "file.json"
    return self.rootAsset .. self.filename
end

function Storage:asset()
    return self:_asset()
end

function Storage:_loadIfNeeded()
    if self._cache ~= nil then return end

    local asset = self:_asset()
    
    local text = string.read(asset)
    if not text or text == "" then
        self._cache = { __version = STORE_VERSION }
        self._dirty = false
        return
    end

    local ok, decoded = pcall(json.decode, text)
    if ok and type(decoded) == "table" then
        if decoded.__version == nil then
            decoded.__version = STORE_VERSION
        end
        self._cache = decoded
        self._dirty = false
    else
        -- If the file is corrupted, don't blow up every access.
        -- Start fresh but keep a hint in meta.
        self._cache = {
            __version = STORE_VERSION,
            __meta = {
                corrupted = true,
            }
        }
        self._dirty = true
    end
end

function Storage:_writeNow()
    self:_loadIfNeeded()
    if not self._dirty then return end

    local asset = self:_asset()
    local ok, encoded = pcall(json.encode, self._cache)
    if not ok then
        error("storage: failed to encode JSON (value not JSON-encodable?)", 3)
    end

    string.save(asset, encoded, function(ok, err)
        self._dirty = false
    end)
end

-- --------- public API ---------

function Storage:get(key, default)
    assertStringKey(key)
    self:_loadIfNeeded()

    local v = self._cache[key]
    if v == nil then return default end
    return v
end

function Storage:has(key)
    assertStringKey(key)
    self:_loadIfNeeded()
    return self._cache[key] ~= nil
end

function Storage:set(key, value)
    assertStringKey(key)
    self:_loadIfNeeded()

    if value == nil then
        self._cache[key] = nil
    else
        self._cache[key] = value
    end

    self._dirty = true
    -- Immediate persistence
    self:_writeNow()
end

function Storage:delete(key)
    return self:set(key, nil)
end

function Storage:keys()
    self:_loadIfNeeded()
    return sortedKeys(self._cache)
end

function Storage:clear()
    self:_loadIfNeeded()
    self._cache = { __version = STORE_VERSION }
    self._dirty = true
    self:_writeNow()
end

function Storage:flush()
    self:_loadIfNeeded()
    if not self._dirty then return end

    local asset = self:_asset()
    local ok, encoded = pcall(json.encode, self._cache)
    if not ok then
        error("storage: failed to encode JSON (value not JSON-encodable?)", 3)
    end

    string.save(asset, encoded)
    self._dirty = false
end

-- Namespace view: prefixes keys with "prefix."
-- Example:
--   local prefs = storage.global:namespace("prefs")
--   prefs:set("audioMuted", true) -> sets "prefs.audioMuted"
function Storage:namespace(prefix)
    if type(prefix) ~= "string" then
        error("storage: namespace prefix must be a string", 2)
    end
    if prefix ~= "" and prefix:sub(-1) ~= "." then
        prefix = prefix .. "."
    end

    local parent = self
    local view = {}

    function view:get(key, default)
        assertStringKey(key)
        return parent:get(prefix .. key, default)
    end

    function view:set(key, value)
        assertStringKey(key)
        return parent:set(prefix .. key, value)
    end

    function view:has(key)
        assertStringKey(key)
        return parent:has(prefix .. key)
    end

    function view:delete(key)
        assertStringKey(key)
        return parent:delete(prefix .. key)
    end

    function view:keys()
        local all = parent:keys()
        local out = {}
        for i = 1, #all do
            local k = all[i]
            if k:sub(1, #prefix) == prefix then
                out[#out + 1] = k:sub(#prefix + 1)
            end
        end
        table.sort(out)
        return out
    end

    function view:clear()
        -- Remove only keys under the namespace
        parent:_loadIfNeeded()
        local changed = false
        for k, _ in pairs(parent._cache) do
            if type(k) == "string" and k:sub(1, #prefix) == prefix then
                parent._cache[k] = nil
                changed = true
            end
        end
        if changed then
            parent._dirty = true
            parent:_writeNow()
        end
    end

    function view:flush()
        parent:flush()
    end

    function view:asset()
        return parent:asset()
    end

    function view:namespace(sub)
        if type(sub) ~= "string" then
            error("storage: namespace prefix must be a string", 2)
        end
        return parent:namespace(prefix .. sub)
    end

    return view
end

-- --------- factory ---------

local defaultProject = newStore(asset, storeFilename("default"))
local defaultGlobal  = newStore(asset.documents, storeFilename("default_global"))

-- Module table M
local M = {}

-- Keep backwards-compatible behavior:
-- M.<method> proxies to defaultProject
local function proxyToDefault(methodName)
    M[methodName] = function(_, ...)
        return defaultProject[methodName](defaultProject, ...)
    end
end

proxyToDefault("get")
proxyToDefault("set")
proxyToDefault("has")
proxyToDefault("delete")
proxyToDefault("keys")
proxyToDefault("clear")
proxyToDefault("flush")
proxyToDefault("asset")
proxyToDefault("namespace")

-- Expose default stores explicitly
M.project = defaultProject
M.global  = defaultGlobal

-- Factory APIs
function M.store(name, scope)
    if scope ~= nil and scope ~= "project" and scope ~= "global" then
        error("storage: scope must be 'project' or 'global'", 2)
    end
    return getOrCreateStore(name, scope == "global" and "global" or "project")
end

function M.projectStore(name)
    return getOrCreateStore(name, "project")
end

function M.globalStore(name)
    return getOrCreateStore(name, "global")
end

setmetatable(M, {
    __call = function(_, name, scope)
        return M.store(name, scope)
    end,
    __index = function(_, key)
        local value = rawget(M, key)
        if value ~= nil then
            return value
        end
        return Storage.__index(defaultProject, key)
    end,
    __newindex = function(_, key, value)
        Storage.__newindex(defaultProject, key, value)
    end
})

return M
