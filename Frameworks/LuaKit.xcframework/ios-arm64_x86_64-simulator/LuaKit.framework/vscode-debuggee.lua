local debuggee = {}
local json
local handlers = {}
--- @TWOLIVESLEFT-BEGIN sim: removed sockets
-- local sock
--- @TWOLIVESLEFT-END sim: removed sockets
local directorySeparator = package.config:sub(1,1)
local sourceBasePath = '.'
local storedVariables = {}
local nextVarRef = 1
local baseDepth
local breaker
local sendEvent
local dumpCommunication = false
local ignoreFirstFrameInC = false
local debugTargetCo = nil
local redirectedPrintFunction = nil

--- @TWOLIVESLEFT-BEGIN
local DebuggerStates = {
    disconnected = 1,
    attached = 2
}
local debuggerState = DebuggerStates.disconnected
local breakpointsPerChunk
local nextBreakpointId = 1
local setUserdataVar = nil
local startGlobals = {}
--- @TWOLIVESLEFT-END

local onError = nil
local addUserdataVar = nil

local function defaultOnError(e)
    print('****************************************************')
    print(e)
    print('****************************************************')
end

local function valueToString(value, depth)
    local str = ''
    depth = depth or 0
    local t = type(value)
    if t == 'table' then
        str = str .. '{\n'
        for k, v in pairs(value) do
            str = str .. string.rep('  ', depth + 1) .. '[' .. valueToString(k) ..']' .. ' = ' .. valueToString(v, depth + 1) .. ',\n'
        end
        str = str .. string.rep('  ', depth) .. '}'
    elseif t == 'string' then
        str = str .. '"' .. tostring(value) .. '"'
    else
        str = str .. tostring(value)
    end
    return str
end

-------------------------------------------------------------------------------
local sethook = debug.sethook
debug.sethook = nil

local cocreate = coroutine.create
coroutine.create = function(f)
    local c = cocreate(f)
    debuggee.addCoroutine(c)
    return c
end

-------------------------------------------------------------------------------
local function debug_getinfo(depth, what)
    if debugTargetCo then
        return debug.getinfo(debugTargetCo, depth, what)
    else
        return debug.getinfo(depth + 1, what)
    end
end

-------------------------------------------------------------------------------
local function debug_getlocal(depth, i)
    if debugTargetCo then
        return debug.getlocal(debugTargetCo, depth, i)
    else
        return debug.getlocal(depth + 1, i)
    end
end

--- @TWOLIVESLEFT-BEGIN
-------------------------------------------------------------------------------
local function debug_setlocal(depth, i, value)
    if debugTargetCo then
        return debug.setlocal(debugTargetCo, depth, i, value)
    else
        return debug.setlocal(depth + 1, i, value)
    end
end
--- @TWOLIVESLEFT-END

-------------------------------------------------------------------------------
local DO_TEST = false

-------------------------------------------------------------------------------
-- chunkname matching {{{
local function getMatchCount(a, b)
    local n = math.min(#a, #b)
    for i = 0, n - 1 do
        if a[#a - i] == b[#b - i] then
            -- pass
        else
            return i
        end
    end
    return n
end
if DO_TEST then
    assert(getMatchCount({'a','b','c'}, {'a','b','c'}) == 3)
    assert(getMatchCount({'b','c'}, {'a','b','c'}) == 2)
    assert(getMatchCount({'a','b','c'}, {'b','c'}) == 2)
    assert(getMatchCount({}, {'a','b','c'}) == 0)
    assert(getMatchCount({'a','b','c'}, {}) == 0)
    assert(getMatchCount({'a','b','c'}, {'a','b','c','d'}) == 0)
end

local function splitChunkName(s)
    if string.sub(s, 1, 1) == '@' then
        s = string.sub(s, 2)
    end

    local a = {}
    for word in string.gmatch(s, '[^/\\]+') do
        a[#a + 1] = string.lower(word)
    end
    return a
end
if DO_TEST then
    local a = splitChunkName('@.\\vscode-debuggee.lua')
    assert(#a == 2)
    assert(a[1] == '.')
    assert(a[2] == 'vscode-debuggee.lua')

    local a = splitChunkName('@C:\\dev\\VSCodeLuaDebug\\debuggee/lua\\socket.lua')
    assert(#a == 6)
    assert(a[1] == 'c:')
    assert(a[2] == 'dev')
    assert(a[3] == 'vscodeluadebug')
    assert(a[4] == 'debuggee')
    assert(a[5] == 'lua')
    assert(a[6] == 'socket.lua')

    local a = splitChunkName('@main.lua')
    assert(#a == 1)
    assert(a[1] == 'main.lua')
end
-- chunkname matching }}}

-- path control {{{
local Path = {}

function Path.isAbsolute(a)
    local firstChar = string.sub(a, 1, 1)
    if firstChar == '/' or firstChar == '\\' then
        return true
    end

    if string.match(a, '^%a%:[/\\]') then
        return true
    end

    return false
end

local np_pat1, np_pat2 = ('[^SEP:]+SEP%.%.SEP?'):gsub('SEP', directorySeparator), ('SEP+%.?SEP'):gsub('SEP', directorySeparator)
function Path.normpath(path)
    path = path:gsub('[/\\]', directorySeparator)

    if directorySeparator == '\\' then
        local unc = ('SEPSEP'):gsub('SEP', directorySeparator) -- UNC
        if path:match('^'..unc) then
            return unc..Path.normpath(path:sub(3))
        end
    end
 
    --- @TWOLIVESLEFT-BEGIN jfperusse: fix normalization of URIs
    if directorySeparator == '/' then
        local schema = path:match('^%a+://')
        if schema then
            return schema..Path.normpath(path:sub(schema:len()+1))
        end
    end
    --- @TWOLIVESLEFT-END jfperusse: fix normalization of URIs

    local k
    repeat -- /./ -> /
        path,k = path:gsub(np_pat2, directorySeparator)
    until k == 0
    repeat -- A/../ -> (empty)
        path,k = path:gsub(np_pat1, '', 1)
    until k == 0
    if path == '' then
        path = '.'
    end
    return path
end

function Path.concat(a, b)
    -- normalize a
    local lastChar = string.sub(a, #a, #a)
    if not (lastChar == '/' or lastChar == '\\') then
        a = a .. directorySeparator
    end

    -- normalize b
    if string.match(b, '^%.%\\') or string.match(b, '^%.%/') then
        b = string.sub(b, 3)
    end

    return a .. b
end

function Path.toAbsolute(base, sub)
    if Path.isAbsolute(sub) then
        return Path.normpath(sub)
    else
        return Path.normpath(Path.concat(base, sub))
    end
end

if DO_TEST then
    assert(Path.isAbsolute('c:\\asdf\\afsd'))
    assert(Path.isAbsolute('c:/asdf/afsd'))
    if directorySeparator == '\\' then
        assert(Path.toAbsolute('c:\\asdf', 'fdsf') == 'c:\\asdf\\fdsf')
        assert(Path.toAbsolute('c:\\asdf', '.\\fdsf') == 'c:\\asdf\\fdsf')
        assert(Path.toAbsolute('c:\\asdf', '..\\fdsf') == 'c:\\fdsf')
        assert(Path.toAbsolute('c:\\asdf', 'c:\\fdsf') == 'c:\\fdsf')
        assert(Path.toAbsolute('c:/asdf', '../fdsf') == 'c:\\fdsf')
        assert(Path.toAbsolute('\\\\HOST\\asdf', '..\\fdsf') == '\\\\HOST\\fdsf')
    elseif directorySeparator == '/' then
        assert(Path.toAbsolute('/usr/bin/asdf', 'fdsf') == '/usr/bin/asdf/fdsf')
        assert(Path.toAbsolute('/usr/bin/asdf', './fdsf') == '/usr/bin/asdf/fdsf')
        assert(Path.toAbsolute('/usr/bin/asdf', '../fdsf') == '/usr/bin/fdsf')
        assert(Path.toAbsolute('/usr/bin/asdf', '/usr/bin/fdsf') == '/usr/bin/fdsf')
        assert(Path.toAbsolute('\\usr\\bin\\asdf', '..\\fdsf') == '/usr/bin/fdsf')
    end
end
-- path control }}}

local coroutineSet = {}
setmetatable(coroutineSet, { __mode = 'v' })

-------------------------------------------------------------------------------
-- network utility {{{
--- @TWOLIVESLEFT-BEGIN sim: use Air Code for this
-- local function sendFully(str)
--     local first = 1
--     while first <= #str do
--         --- @TWOLIVESLEFT-BEGIN jfperusse: handle disconnection
--         if sock == nil then return end
--         --- @TWOLIVESLEFT-END jfperusse: handle disconnection
--         local sent = sock:send(str, first)
--         if sent and sent > 0 then
--             first = first + sent;
--         else
--             error('sock:send() returned < 0')
--         end
--     end
-- end
--- @TWOLIVESLEFT-END sim: use Air Code for this

-- send log to debug console
local function logToDebugConsole(output, category)
    local dumpMsg = {
        event = 'output',
        type = 'event',
        body = {
            category = category or 'console',
            output = output
        }
    }
    local dumpBody = json.encode(dumpMsg)
    
    --- @TWOLIVESLEFT-BEGIN sim: use Air Code
    airCode.send(dumpBody)
    --- sendFully('#' .. #dumpBody .. '\n' .. dumpBody)
    --- @TWOLIVESLEFT-END sim: use Air Code
end

-------------------------------------------------------------------------------
local function getTempG(depth)
    local tempG = {}
    local declared = {}
    local function set(k, v)
        tempG[k] = v
        declared[k] = true
    end

    for name, value in pairs(_G) do
        set(name, value)
    end

    if depth then
        local info = debug_getinfo(depth, 'f')
        if info and info.func then
            local index = 1
            while true do
                local name, value = debug.getupvalue(info.func, index)
                if name == nil then break end
                set(name, value)
                index = index + 1
            end
        end

        local index = 1
        while true do
            local name, value = debug_getlocal(depth, index)
            if name == nil then break end
            set(name, value)
            index = index + 1
        end
    else
        -- VSCode가 depth를 안 보낼 수도 있다.
        -- 특정 스택 프레임을 선택하지 않은, 전역 이름만 조회하는 경우이다.
        -- In English:
        --  VSCode may not send depth.
        --  This is the case where only global names are searched without selecting a specific stack frame.
    end
    local mt = {
        __newindex = function() error('assignment not allowed', 2) end,
        __index = function(t, k) end
    }
    setmetatable(tempG, mt)
    
    return tempG
end

-------------------------------------------------------------------------------
local function matchesCondition(condition)
    if condition == nil or condition == "" then
        return true
    end
    
    local tempG = getTempG(4)
    local fn, err = load(condition, 'X', nil, tempG)
    if fn == nil then
        return true
    end
    
    local success, aux = pcall(fn)
    return success and aux == true
end

-------------------------------------------------------------------------------
-- pure mode {{{
local function createHaltBreaker()
    breakpointsPerChunk = {}
    
    -- chunkname matching {
    local loadedChunkNameMap = {}
    local function doRefreshLoadedChunkNameMap()
        loadedChunkNameMap = {}
        for chunkname, _ in pairs(debug.getchunknames()) do
            loadedChunkNameMap[chunkname] = splitChunkName(chunkname)
        end
    end
    doRefreshLoadedChunkNameMap()

    local function hasChunkName(chunkNameToFind)
        for chunkName, splitted in pairs(loadedChunkNameMap) do
            if chunkName == chunkNameToFind then
                return true
            end
        end
        return false
    end
    -- chunkname matching }

    local lineBreakCallback = nil
    local function updateCoroutineHook(c)
        if lineBreakCallback then
            sethook(c, lineBreakCallback, 'l')
        else
            sethook(c)
        end
    end
    local function sethalt(cname, ln)
        for i = ln, ln + 10 do
            if debug.sethalt(cname, i) then
                return i
            end
        end
        return nil
    end
    local function doRefreshBreakpoints()
        doRefreshLoadedChunkNameMap()
        
        for chunkName, breakpointsPerLine in pairs(breakpointsPerChunk) do
            local foundChunkName = hasChunkName(chunkName)
            for line, breakpoint in pairs(breakpointsPerLine) do
                local verifiedLine = foundChunkName and sethalt(chunkName, line) or nil
                local verified = foundChunkName and verifiedLine ~= nil
                if verified ~= breakpoint.verified or verifiedLine ~= breakpoint.verifiedLine then
                    sendEvent('breakpoint',
                        {
                            reason = 'changed',
                            breakpoint = {
                                id = breakpoint.id,
                                verified = verified,
                                line = verifiedLine
                            }
                        })
                end
            end
        end
    end
    return {
        refreshBreakpoints = doRefreshBreakpoints,
        setBreakpoints = function(path, breakpoints)
            local chunkName = "@" .. string.match(path, "/Codea/(.*)")
            local foundChunkName = hasChunkName(chunkName)
            local verifiedLines = {}
            breakpointsPerChunk[chunkName] = {}

            if foundChunkName then
                debug.clearhalt(chunkName)
            end
            
            for i, bp in ipairs(breakpoints) do
                local ln = bp.line
                local condition = bp.condition
                local logMessage = bp.logMessage
                if foundChunkName then
                    verifiedLines[ln] = sethalt(chunkName, ln)
                end
                local isVerified = foundChunkName and verifiedLines[ln] ~= nil
                breakpointsPerChunk[chunkName][ln] = {
                    id = nextBreakpointId,
                    verified = isVerified,
                    verifiedLine = verifiedLines[ln]
                }
                nextBreakpointId = nextBreakpointId + 1
                if condition ~= nil and condition ~= "" then
                    breakpointsPerChunk[chunkName][ln].condition = "return (" .. condition .. ")"
                end
                if logMessage ~= nil and logMessage ~= "" then
                    breakpointsPerChunk[chunkName][ln].logMessage = logMessage
                end
            end

            return breakpointsPerChunk[chunkName]
        end,

        setLineBreak = function(callback)
            if callback then
                sethook(callback, 'l')
            else
                sethook()
            end

            lineBreakCallback = callback
            for cid, c in pairs(coroutineSet) do
                updateCoroutineHook(c)
            end
        end,

        coroutineAdded = function(c)
            updateCoroutineHook(c)
        end,

        stackOffset =
        {
            enterDebugLoop = 6,
            halt = 6,
            step = 4,
            stepDebugLoop = 6
        }
    }
end

local function createPureBreaker()
    local lineBreakCallback = nil
    local breakpointsPerPath = {}
    local chunknameToPathCache = {}

    local function chunkNameToPath(chunkname)
        local cached = chunknameToPathCache[chunkname]
        if cached then
            return cached
        end

        local splitedReqPath = splitChunkName(chunkname)
        local maxMatchCount = 0
        local foundPath = nil
        for path, _ in pairs(breakpointsPerPath) do
            local splitted = splitChunkName(path)
            local count = getMatchCount(splitedReqPath, splitted)
            if (count > maxMatchCount) then
                maxMatchCount = count
                foundPath = path
            end
        end

        if foundPath then
            chunknameToPathCache[chunkname] = foundPath
        end
        return foundPath
    end

    local entered = false
    local function hookfunc()
        if entered then return false end
        entered = true

        if lineBreakCallback then
            lineBreakCallback()
        end

        local info = debug_getinfo(2, 'Sl')
        if info then
            local path = chunkNameToPath(info.source)
            if path then
                path = string.lower(path)
            end
            local bpSet = breakpointsPerPath[path]
            if bpSet and bpSet[info.currentline] then
                local condition = bpSet[info.currentline].condition
                if matchesCondition(condition) then
                    _G.__halt__()
                end
            end
        end

        entered = false
    end
    sethook(hookfunc, 'l')

    return {
        setBreakpoints = function(path, breakpoints)
            local t = {}
            local verifiedLines = {}
            for i, bp in ipairs(breakpoints) do
                local ln = bp.line
                local condition = bp.condition
                --- @TWOLIVESLEFT-BEGIN jfperusse
                --- t[ln] = true
                t[ln] = {
                    condition = "return (" .. condition .. ")"
                }
                verifiedLines[ln] = ln
                --- @TWOLIVESLEFT-END jfperusse
            end
            if path then
                path = string.lower(path)
            end
            breakpointsPerPath[path] = t

            return verifiedLines
        end,

        setLineBreak = function(callback)
            lineBreakCallback = callback
        end,

        coroutineAdded = function(c)
            sethook(c, hookfunc, 'l')
        end,

        stackOffset =
        {
            enterDebugLoop = 6,
            halt = 7,
            step = 4,
            stepDebugLoop = 7
        }
    }
end
-- pure mode }}}


-- 센드는 블럭이어도 됨.
local function sendMessage(msg)
    local body = json.encode(msg)

    if dumpCommunication then
        logToDebugConsole('[SENDING] ' .. valueToString(msg))
    end

    --- @TWOLIVESLEFT-BEGIN sim: use airCode.send instead
    airCode.send(body)
    -- sendFully('#' .. #body .. '\n' .. body)
    --- @TWOLIVESLEFT-END sim: use airCode.send instead    
end

local function receiveMessage()
    local body = airCode.receive()

    if body ~= nil then
        return json.decode(body)
    end 
    
    return nil
end
-- network utility }}}

-------------------------------------------------------------------------------
local function debugLoop()
    storedVariables = {}
    nextVarRef = 1
    while true do
        local msg = receiveMessage()
        if msg then
            if dumpCommunication then
                logToDebugConsole('[RECEIVED] ' .. valueToString(msg), 'stderr')
            end

            local fn = handlers[msg.command]
            if fn then
                local rv = fn(msg)

                -- continue인데 break하는 게 역설적으로 느껴지지만
                -- 디버그 루프를 탈출(break)해야 정상 실행 흐름을 계속(continue)할 수 있지..
                if (rv == 'CONTINUE') then
                    break
                end
            else
                --print('UNKNOWN DEBUG COMMAND: ' .. tostring(msg.command))
            end
        else
            -- 디버그 중에 디버거가 떨어졌다.
            -- print펑션을 리다이렉트 한경우에는 원래대로 돌려놓는다
            if redirectedPrintFunction then
                _G.print = redirectedPrintFunction
            end
            break
        end
    end
    storedVariables = {}
    nextVarRef = 1
end

-------------------------------------------------------------------------------
--- @TWOLIVESLEFT-BEGIN sim: use Air Code
--- local sockArray = {}
--- @TWOLIVESLEFT-END sim: use Air Code
function debuggee.start(jsonLib, config)
    json = jsonLib
    assert(jsonLib)

    config = config or {}
    local controllerHost = config.controllerHost or 'localhost'
    local controllerPort = config.controllerPort or 56789
    onError              = config.onError or defaultOnError
    addUserdataVar         = config.addUserdataVar or function() return end
    --- @TWOLIVESLEFT-BEGIN jfperusse
    setUserdataVar       = config.setUserdataVar or function() return end
    --- @TWOLIVESLEFT-END jfperusse
    local redirectPrint  = config.redirectPrint or false
    dumpCommunication    = config.dumpCommunication or false
    ignoreFirstFrameInC  = config.ignoreFirstFrameInC or false
    --- @TWOLIVESLEFT-BEGIN jfperusse
    local enableHalt     = config.enableHalt == nil or config.enableHalt
    --- @TWOLIVESLEFT-END jfperusse
    if not config.luaStyleLog then
        valueToString = function(value) return json.encode(value) end
    end

    local breakerType
    if enableHalt and debug.sethalt then
        --- @TWOLIVESLEFT-BEGIN jfperusse: create breaker after a successful connection
        --- breaker = createHaltBreaker()
        --- @TWOLIVESLEFT-END jfperusse: create breaker after a successful connection
        breakerType = 'halt'
    else
        --- @TWOLIVESLEFT-BEGIN jfperusse: create breaker after a successful connection
        --- breaker = createPureBreaker()
        --- @TWOLIVESLEFT-END jfperusse: create breaker after a successful connection
        breakerType = 'pure'
    end

    --- @TWOLIVESLEFT-BEGIN sim: disable socket stuff for now
    -- local err
    -- sock, err = socket.tcp()
    -- if not sock then error(err) end
    -- sockArray = { sock }
    -- if sock.settimeout then sock:settimeout(connectTimeout) end
    -- local res, err = sock:connect(controllerHost, tostring(controllerPort))
    -- if not res then
    --     sock:close()
    --     sock = nil
    --     return false, breakerType
    -- end
    --- @TWOLIVESLEFT-END sim: disable socket stuff for now
 
    --- @TWOLIVESLEFT-BEGIN jfperusse: create breaker after a successful connection
    if enableHalt and debug.sethalt then
        breaker = createHaltBreaker()
    else
        breaker = createPureBreaker()
    end
    --- @TWOLIVESLEFT-END jfperusse: create breaker after a successful connection    

    if redirectPrint then
        redirectedPrintFunction = _G.print -- 디버거가 떨어질때를 대비해서 보관한다 (In English: Save the print function in case the debugger disconnects.)
        _G.print = function(...)
            local t = { n = select("#", ...), ... }
            for i = 1, #t do
                t[i] = tostring(t[i])
            end
            sendEvent(
                'output',
                {
                    category = 'stdout',
                    output = table.concat(t, '\t') .. '\n' -- Same as default "print" output end new line.
                })
        end
    end

    --- @TWOLIVESLEFT-BEGIN
    -- debugLoop()
    --- @TWOLIVESLEFT-END
     
    return true, breakerType
end

-------------------------------------------------------------------------------
function debuggee.poll()
    -- TODO-AIRCODE: ensure we are not disconnected

    -- Processes commands in the queue.    
    while true do        
        -- Immediately returns when the queue is/became empty.
        if airCode.messageCount == 0 then 
            return
        end

        local msg = receiveMessage()
        if msg then
            if dumpCommunication then
                logToDebugConsole('[POLL-RECEIVED] ' .. valueToString(msg), 'stderr')
            end

            if msg.command == 'pause' then
                handlers.pause(msg)
                return
            end

            local fn = handlers[msg.command]
            if fn then
                local rv = fn(msg)
                -- Ignores rv, because this loop never blocks except explicit pause command.
            else
                --print('POLL-UNKNOWN DEBUG COMMAND: ' .. tostring(msg.command))
            end
        else
            break
        end
    end
end

-------------------------------------------------------------------------------
local function getCoroutineId(c)
    -- 'thread: 011DD5B0'
    --  12345678^
    local threadIdHex = string.sub(tostring(c), 9)
    return tonumber(threadIdHex, 16)
end

-------------------------------------------------------------------------------
function debuggee.addCoroutine(c)
    local cid = getCoroutineId(c)
 
    if cid then
        coroutineSet[cid] = c
        breaker.coroutineAdded(c)
    end
end

-------------------------------------------------------------------------------
local function sendSuccess(req, body)
    sendMessage({
        command = req.command,
        success = true,
        request_seq = req.seq,
        type = "response",
        body = body
    })
end

-------------------------------------------------------------------------------
local function sendFailure(req, msg)
    sendMessage({
        command = req.command,
        success = false,
        request_seq = req.seq,
        type = "response",
        message = msg
    })
end

-------------------------------------------------------------------------------
sendEvent = function(eventName, body)
    sendMessage({
        event = eventName,
        type = "event",
        body = body
    })
end

-------------------------------------------------------------------------------
local function currentThreadId()
--[[
    local threadId = 0
    if coroutine.running() then
    end
    return threadId
]]
    return 0
end

-------------------------------------------------------------------------------
local function startDebugLoop()
    if debuggerState ~= DebuggerStates.attached then
        return
    end

    sendEvent(
        'stopped',
        {
            reason = 'breakpoint',
            threadId = currentThreadId(),
            allThreadsStopped = true
        })

    local status, err = pcall(debugLoop)
    if not status then
        onError(err)
    end
end

-------------------------------------------------------------------------------
local function registerVar(varNameCount, name_, value, noQuote)
    local ty = type(value)
    local name
    if type(name_) == 'number' then
        name = '[' .. name_ .. ']'
    else
        name = tostring(name_)
    end
    if varNameCount[name] then
        varNameCount[name] = varNameCount[name] + 1
        name = name .. ' (' .. varNameCount[name] .. ')'
    else
        varNameCount[name] = 1
    end

    local item = {
        name = name,
        type = ty
    }

    if (ty == 'string' and (not noQuote)) then
        item.value = '"' .. value .. '"'
    else
        item.value = tostring(value)
    end

    if (ty == 'table') or
        (ty == 'function') or
         (ty == 'userdata') then
        storedVariables[nextVarRef] = value
        item.variablesReference = nextVarRef
        nextVarRef = nextVarRef + 1
    else
        item.variablesReference = -1
    end

    return item
end

-------------------------------------------------------------------------------
local function evaluateExpression(sourceCode, tempG)
    -- 파싱 (In English: Parsing)
    -- loadstring for Lua 5.1
    -- load for Lua 5.2 and 5.3(supports the private environment's load function)
    local fn, err
    if tempG == nil then
        fn, err = (loadstring or load)(sourceCode, 'X')
    else
        fn, err = (loadstring or load)(sourceCode, 'X', nil, tempG)
    end
    
    if fn == nil then
        return nil, string.gsub(err, '^%[string %"X%"%]%:%d+%: ', '')
    end

    -- 실행하고 결과 송신 (In English: Run and send the result)
    if setfenv ~= nil then
        -- Only for Lua 5.1
        setfenv(fn, tempG)
    end

    local success, aux = pcall(fn)
    if not success then
        aux = aux or '' -- Execution of 'error()' returns nil as aux
        return nil, string.gsub(aux, '^%[string %"X%"%]%:%d+%: ', '')
    end
    
    local varNameCount = {}
    return registerVar(varNameCount, '', aux)
end

-------------------------------------------------------------------------------
local function getChunkConditionLogMessage()
    if breakpointsPerChunk == nil then
        return nil
    end
    
    local info = debug_getinfo(3, 'Sl')
    local bp = breakpointsPerChunk[info.source]
    if bp == nil then
        return nil
    end

    local bpLine = bp[info.currentline]
    if bpLine == nil then
        return nil
    end

    return bpLine.condition, bpLine.logMessage
end

local function handleLogMessage(logMessage)
    -- We must replace all {...} with the actual value by calling the content as lua
    
    -- Use a temporary environment so logPoints don't affect the global environment
    local tempG = getTempG(3)

    logMessage = logMessage:gsub('{(.-)}', function(chunk)
        local sourceCode = 'return (' .. chunk .. ')'
        
        local item, err = evaluateExpression(sourceCode, tempG)
        
        if err then
            return "<error: " .. err .. ">"
        end
        
        return item.value
    end)
    
    sendEvent(
        'output',
        {
            category = 'stdout',
            output = logMessage .. '\n'
        })
end

_G.__halt__ = function()
    local chunkCondition, logMessage = getChunkConditionLogMessage()
    if chunkCondition ~= nil and not matchesCondition(chunkCondition) then
        return
    end
    
    if logMessage ~= nil then
        handleLogMessage(logMessage)
        -- Do not break here
        return
    end

    baseDepth = breaker.stackOffset.halt
    startDebugLoop()
end

-------------------------------------------------------------------------------
function debuggee.enterDebugLoop(depthOrCo, what)
    if debuggerState ~= DebuggerStates.attached then
        return
    end

    if what then
        sendEvent(
            'output',
            {
                category = 'stderr',
                output = what,
            })
    end

    if type(depthOrCo) == 'thread' then
        baseDepth = 0
        debugTargetCo = depthOrCo
    elseif type(depthOrCo) == 'table' then
        baseDepth = (depthOrCo.depth or 0)
        debugTargetCo = depthOrCo.co
    else
        baseDepth = (depthOrCo or 0) + breaker.stackOffset.enterDebugLoop
        debugTargetCo = nil
    end
    startDebugLoop()
    return true
end

-------------------------------------------------------------------------------
-- Function for printing on vscode debug console
-- First parameter 'category' can colorizes print text
function debuggee.print(category, ...)
    --- @TWOLIVESLEFT-BEGIN sim: disable socket stuff for now
    -- if sock == nil then
    --     return false
    -- end
    --- @TWOLIVESLEFT-END sim: disable socket stuff for now

    local t = { ... }
    for i = 1, #t do
        t[i] = tostring(t[i])
    end

    local categoryVscodeConsole = 'stdout'
    if category == 'warning' then
        categoryVscodeConsole = 'console' -- yellow
    elseif category == 'error' then
        categoryVscodeConsole = 'stderr' -- red
    elseif category == 'log' then
        categoryVscodeConsole = 'stdout' -- white
    end

    sendEvent(
        'output',
        {
            category = categoryVscodeConsole,
            output =  table.concat(t, '\t') .. '\n'  -- Same as default "print" output end new line.
        })
end

-------------------------------------------------------------------------------
function debuggee.refreshBreakpoints()
    if breaker then
        breaker.refreshBreakpoints()
    end
end

-------------------------------------------------------------------------------
-- ★★★ https://github.com/Microsoft/vscode-debugadapter-node/blob/master/protocol/src/debugProtocol.ts
-------------------------------------------------------------------------------

--- @TWOLIVESLEFT-BEGIN sim: additional DebugAdapter implementation
function handlers.initialize(req)
    sendSuccess(req, {
        supportsConfigurationDoneRequest = true;
        supportsFunctionBreakpoints = false;
        supportsConditionalBreakpoints = true;
        supportsLogPoints = true;
        supportsSetVariable = true;
        supportsSetExpression = true;
        supportsEvaluateForHovers = false;
        exceptionBreakpointFilters = {};
    })

    sendEvent('initialized')
end

function handlers.attach(req) 
    directorySeparator = "/"
    sourceBasePath = req.arguments.sourceBasePath ..
                     directorySeparator

    debuggerState = DebuggerStates.attached

    sendSuccess(req, {})
end

function handlers.disconnect(req)
    stepTargetHeight = nil
    breaker.setLineBreak(nil)

    debuggerState = DebuggerStates.disconnected

    sendSuccess(req, {})

    return 'CONTINUE'
end
--- @TWOLIVESLEFT-END sim: additional DebugAdapter implementation

-------------------------------------------------------------------------------
function handlers.setBreakpoints(req)
    local breakerBreakpoints = breaker.setBreakpoints(
        req.arguments.source.path,
        req.arguments.breakpoints)

    local breakpoints = {}
    for i, bp in ipairs(req.arguments.breakpoints) do
        local ln = bp.line
        local breakpoint = breakerBreakpoints[ln]
        breakpoints[i] = {
            id = breakpoint.id,
            verified = breakpoint.verified,
            line = breakpoint.verifiedLine
        }
    end

    sendSuccess(req, {
        breakpoints = breakpoints
    })
end

-------------------------------------------------------------------------------
function handlers.configurationDone(req)
    sendSuccess(req, {})
    return 'CONTINUE'
end

-------------------------------------------------------------------------------
function handlers.threads(req)
    local c = coroutine.running()

    local mainThread = {
        id = currentThreadId(),
        name = (c and tostring(c)) or "main"
    }

    sendSuccess(req, {
        threads = { mainThread }
    })
end

-------------------------------------------------------------------------------
function handlers.stackTrace(req)
    assert(req.arguments.threadId == 0)

    local stackFrames = {}
    local firstFrame = (req.arguments.startFrame or 0) + baseDepth
    local lastFrame = (req.arguments.levels and (req.arguments.levels ~= 0))
        and (firstFrame + req.arguments.levels - 1)
        or (9999)

    -- if firstframe function of stack is C function, ignore it.
    if ignoreFirstFrameInC then
        local info = debug_getinfo(firstFrame, 'lnS')
        if info and info.what == "C" then
            firstFrame = firstFrame + 1
        end
    end

    for i = firstFrame, lastFrame do
        local info = debug_getinfo(i, 'lnS')
        if (info == nil) then break end
        --print(json.encode(info))

        local src = info.source
        if string.sub(src, 1, 1) == '@' then
            src = string.sub(src, 2) -- 앞의 '@' 떼어내기 (In english: remove the '@' at the front)
        end

        local name
        if info.name then
            name = info.name .. ' (' .. (info.namewhat or '?') .. ')'
        else
            name = '?'
        end

        local sframe = {
            name = name,
            source = {
                name = nil,
                path = Path.toAbsolute(sourceBasePath, src)
            },
            column = 1,
            line = info.currentline or 1,
            id = i,
        }
        stackFrames[#stackFrames + 1] = sframe
    end

    sendSuccess(req, {
        stackFrames = stackFrames
    })
end

-------------------------------------------------------------------------------
local scopeTypes = {
    Locals = 1,
    Upvalues = 2,
    Globals = 3,
    Project = 4,
}
function handlers.scopes(req)
    local depth = req.arguments.frameId

    local scopes = {}
    local function addScope(name)
        scopes[#scopes + 1] = {
            name = name,
            expensive = false,
            variablesReference = depth * 1000000 + scopeTypes[name]
        }
    end

    addScope('Locals')
    addScope('Upvalues')
    addScope('Project')
    addScope('Globals')

    sendSuccess(req, {
        scopes = scopes
    })
end

-------------------------------------------------------------------------------
local function addGlobals(user, addVar)
    local globals = {}
    local keys = {}
    
    for k, v in pairs(_G) do
        local isStartGlobals = startGlobals[k] == true
        if isStartGlobals ~= user then
                globals[k] = v
            table.insert(keys, k)
        end
    end
    
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    
    for i, k in ipairs(keys) do
        addVar(k, globals[k])
    end
end

-------------------------------------------------------------------------------
function handlers.variables(req)
    local varRef = req.arguments.variablesReference
    local variables = {}
    local varNameCount = {}
    local function addVar(name, value, noQuote)
        variables[#variables + 1] = registerVar(varNameCount, name, value, noQuote)
    end

    if (varRef >= 1000000) then
        -- Scope.
        local depth = math.floor(varRef / 1000000)
        local scopeType = varRef % 1000000
        if scopeType == scopeTypes.Locals then
            local index = 1
            while true do
                local name, value = debug_getlocal(depth, index)
                if name == nil then break end
                addVar(name, value, nil)
                index = index + 1
            end
        elseif scopeType == scopeTypes.Upvalues then
            local info = debug_getinfo(depth, 'f')
            if info and info.func then
                local index = 1
                while true do
                    local name, value = debug.getupvalue(info.func, index)
                    if name == nil then break end
                    addVar(name, value, nil)
                    index = index + 1
                end
            end
        elseif scopeType == scopeTypes.Globals then
            --- @TWOLIVESLEFT-BEGIN
            -- for name, value in pairs(_G) do
            --    addVar(name, value)
            --end
            --table.sort(variables, function(a, b) return a.name < b.name end)

            addGlobals(false, addVar)

            --- @TWOLIVESLEFT-END
        elseif scopeType == scopeTypes.Project then --- @TWOLIVESLEFT
            addGlobals(true, addVar)
        end
    else
        -- Expansion.
        local var = storedVariables[varRef]
        if type(var) == 'table' then
            for k, v in pairs(var) do
                addVar(k, v)
            end
            table.sort(variables, function(a, b)
                local aNum, aMatched = string.gsub(a.name, '^%[(%d+)%]$', '%1')
                local bNum, bMatched = string.gsub(b.name, '^%[(%d+)%]$', '%1')

                if (aMatched == 1) and (bMatched == 1) then
                    -- both are numbers. compare numerically.
                    return tonumber(aNum) < tonumber(bNum)
                elseif aMatched == bMatched then
                    -- both are strings. compare alphabetically.
                    return a.name < b.name
                else
                    -- string comes first.
                    return aMatched < bMatched
                end
            end)
        elseif type(var) == 'function' then
            local info = debug.getinfo(var, 'S')
            addVar('(source)', tostring(info.short_src), true)
            addVar('(line)', info.linedefined)

            local index = 1
            while true do
                local name, value = debug.getupvalue(var, index)
                if name == nil then break end
                addVar(name, value)
                index = index + 1
            end
        elseif type(var) == 'userdata' then
            addUserdataVar(var, addVar)
        end

        local mt = getmetatable(var)
        if mt then
            addVar("(metatable)", mt)
        end
    end

    sendSuccess(req, {
        variables = variables
    })
end

--- @TWOLIVESLEFT-BEGIN jfperusse
-------------------------------------------------------------------------------
function handlers.setVariable(req)
    local varRef = req.arguments.variablesReference
    local varName = req.arguments.name
    local varValue = req.arguments.value

    if varValue == "true" then
        varValue = true
    elseif varValue == "false" then
        varValue = false
    else
        local num = tonumber(varValue)
        if num then
            varValue = num
        end
    end
    
    if (varRef >= 1000000) then
        -- Scope.
        local depth = math.floor(varRef / 1000000)
        local scopeType = varRef % 1000000
        if scopeType == scopeTypes.Locals then
            local index = 1
            while true do
                local name, value = debug_getlocal(depth, index)
                if name == nil then break end
                if name == varName then
                    debug_setlocal(depth, index, varValue)
                    break
                end
                index = index + 1
            end
        elseif scopeType == scopeTypes.Upvalues then
            local info = debug_getinfo(depth, 'f')
            if info and info.func then
                local index = 1
                while true do
                    local name, value = debug.getupvalue(info.func, index)
                    if name == nil then break end
                    if name == varName then
                        debug.setupvalue(info.func, index, varValue)
                        break
                    end
                    index = index + 1
                end
            end
        elseif scopeType == scopeTypes.Globals or scopeType == scopeTypes.Project then
            _G[varName] = varValue
        end
    else
        -- Expansion.
        local var = storedVariables[varRef]
        if type(var) == 'table' then
            var[varName] = varValue
        elseif type(var) == 'function' then
            local index = 1
            while true do
                local name, value = debug.getupvalue(var, index)
                if name == nil then break end
                if name == varName then
                    debug.setupvalue(var, index, varValue)
                    break
                end
                index = index + 1
            end
        elseif type(var) == 'userdata' then
            varValue = setUserdataVar(var, varName, varValue)
        end
    end
    
    sendSuccess(req, {
        value = tostring(varValue)
    })
end

-------------------------------------------------------------------------------
function handlers.setExpression(req)
    local varValue = req.arguments.value
    local expression = req.arguments.expression
    local depth = req.arguments.frameId
    
    sourceCode =               "value = (" .. varValue .. ")\n"
    sourceCode = sourceCode .. expression .. " = value\n"
    sourceCode = sourceCode .. "return value"
    
    local item, err = evaluateExpression(sourceCode)
    
    if item == nil then
        sendFailure(req, err)
        return
    end
    
    sendSuccess(req, {
        value = item.value,
        type = item.type,
        variablesReference = item.variablesReference
    })
end
--- @TWOLIVESLEFT-END jfperusse

-------------------------------------------------------------------------------
function handlers.continue(req)
    --- @TWOLIVESLEFT-BEGIN jfperusse: clear line break when resuming
    stepTargetHeight = nil
    breaker.setLineBreak(nil)
    --- @TWOLIVESLEFT-END jfperusse: clear line break when resuming
    sendSuccess(req, {})
    return 'CONTINUE'
end

-------------------------------------------------------------------------------
local function stackHeight()
    local index = 1
    while true do
        if (debug_getinfo(index, '') == nil) then
            return index
        end
        index = index + 1
    end
end

-------------------------------------------------------------------------------
local stepTargetHeight = nil
local function step()
    if (stepTargetHeight == nil) or (stackHeight() <= stepTargetHeight) then
        breaker.setLineBreak(nil)
        baseDepth = breaker.stackOffset.stepDebugLoop
        startDebugLoop()
    end
end

-------------------------------------------------------------------------------
local stopDelay = 0
local function delayedStop()
    if stopDelay > 0 then
        stopDelay = stopDelay - 1
        if stopDelay == 0 then
            breaker.setLineBreak(nil)
            baseDepth = breaker.stackOffset.stepDebugLoop
            startDebugLoop()
        end
    end
end

-------------------------------------------------------------------------------
function handlers.pause(req)
    stepTargetHeight = nil
    stopDelay = 7
    breaker.setLineBreak(delayedStop)
end

-------------------------------------------------------------------------------
function handlers.next(req)
    stepTargetHeight = stackHeight() - breaker.stackOffset.step
    breaker.setLineBreak(step)
    sendSuccess(req, {})
    return 'CONTINUE'
end

-------------------------------------------------------------------------------
function handlers.stepIn(req)
    stepTargetHeight = nil
    breaker.setLineBreak(step)
    sendSuccess(req, {})
    return 'CONTINUE'
end

-------------------------------------------------------------------------------
function handlers.stepOut(req)
    stepTargetHeight = stackHeight() - (breaker.stackOffset.step + 1)
    breaker.setLineBreak(step)
    sendSuccess(req, {})
    return 'CONTINUE'
end

-------------------------------------------------------------------------------
function handlers.evaluate(req)
    -- 실행할 소스 코드 준비 (In English: Prepare the source code to execute)
    local sourceCode = req.arguments.expression
    local depth = req.arguments.frameId
    local context = req.arguments.context
    
    local writeable = context == 'repl'
    
    if string.sub(sourceCode, 1, 1) == '!' then
        sourceCode = string.sub(sourceCode, 2)
    else
        sourceCode = 'return (' .. sourceCode .. ')'
    end
    
    -- 환경 준비.
    -- 뭘 요구할지 모르니까 로컬, 업밸류, 글로벌을 죄다 복사해둔다.
    -- 우선순위는 글로벌-업밸류-로컬 순서니까
    -- 그 반대로 갖다놓아서 나중 것이 앞의 것을 덮어쓰게 한다.
    -- In english:
    -- Prepare the environment.
    -- I don't know what to demand, so I'll just copy the local, upvalue, and global.
    -- The priority is global-upvalue-local order, so
    -- Put it in reverse order so that the later one overwrites the previous one.
    
    local tempG
    if not writeable then
        tempG = getTempG(depth)
    end

    local item, err = evaluateExpression(sourceCode, tempG)
    
    -- In case of error, try using the original expression as it might not generate a value.
    if err and writeable then
        item, err = evaluateExpression(req.arguments.expression)
    end
    
    if err then
        sendFailure(req, err)
        return
    end

    sendSuccess(req, {
        result = item.value,
        type = item.type,
        variablesReference = item.variablesReference
    })
end

--- @TWOLIVESLEFT-BEGIN
-------------------------------------------------------------------------------
-- Initialize this when imported, it must be the last imported file before loading the project
for name, value in pairs(_G) do
    startGlobals[name] = true
end
--- @TWOLIVESLEFT-END

-------------------------------------------------------------------------------
return debuggee
