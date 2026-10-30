-- symbols.lua
--
-- SF Symbols as Codea images, without making users reach for objc.
--
--     image.symbol("globe")                                    -- white template
--     image.symbol("globe", color(255, 0, 0))                  -- monochrome
--     image.symbol("cloud.sun.fill", image.symbol.multicolor)
--     image.symbol("gauge", image.symbol.weight.bold, 64)
--
-- Argument style follows pick: options are order-independent, self-describing
-- string constants, so a typo produces a readable error rather than a silent
-- nil. The symbol name is the exception -- it is required, so it is always the
-- first argument.
--
-- iOS-only (uses objc); required from common.lua under pcall so Android and
-- other platforms simply do not get the API.

-- UIImageSymbolWeight / UIImageSymbolScale. These are stable UIKit enum values;
-- objc.enum does not carry them.
local WEIGHT_VALUES = {
    ultralight = 1,
    thin       = 2,
    light      = 3,
    regular    = 4,
    medium     = 5,
    semibold   = 6,
    bold       = 7,
    heavy      = 8,
    black      = 9,
}

local SCALE_VALUES = {
    small  = 1,
    medium = 2,
    large  = 3,
}

-- Options come in two shapes. A flag with no value of its own is a plain string,
-- the way pick.option works. An option that carries values is a call that
-- returns them bundled together -- so nothing depends on argument order, and a
-- value can never be mistaken for an unrelated one. A bare number is the point
-- size, the one scalar with a single unambiguous meaning.
local symbol = {
    -- flags
    monochrome = "image.symbol.monochrome",
    multicolor = "image.symbol.multicolor",

    weight = {},
    scale  = {},
}

local MODES = {
    [symbol.monochrome] = "monochrome",
    [symbol.multicolor] = "multicolor",
}

--- Marks a table as an option carrying values, so the parser can tell one from
--- an arbitrary table passed by mistake.
local OPTION_TAG = "image.symbol.option"

local function _option(kind, values)
    return { [OPTION_TAG] = kind, values = values }
end

--- image.symbol.hierarchical(color) -- one colour at several opacities
symbol.hierarchical = function(tint)
    return _option("hierarchical", { tint })
end

--- image.symbol.palette(color, ...) -- two or three explicit colours, in order
symbol.palette = function(...)
    return _option("palette", { ... })
end

--- image.symbol.variable(value) -- fill level from 0 to 1
symbol.variable = function(value)
    if type(value) ~= "number" then
        error("image.symbol.variable expects a number from 0 to 1, got " .. type(value))
    end

    if value < 0 or value > 1 then
        error("image.symbol.variable expects a value from 0 to 1, got " .. tostring(value))
    end

    return _option("variable", { value })
end

-- Weight and scale both have a "medium", so they are namespaced rather than
-- flattened alongside the modes.
local WEIGHTS_BY_CONSTANT = {}
for name, value in pairs(WEIGHT_VALUES) do
    local constant = "image.symbol.weight." .. name
    symbol.weight[name] = constant
    WEIGHTS_BY_CONSTANT[constant] = value
end

local SCALES_BY_CONSTANT = {}
for name, value in pairs(SCALE_VALUES) do
    local constant = "image.symbol.scale." .. name
    symbol.scale[name] = constant
    SCALES_BY_CONSTANT[constant] = value
end

local function _isColor(value)
    -- Works on both runtimes without depending on typeof().
    local ok, result = pcall(function()
        return value.r ~= nil and value.g ~= nil and value.b ~= nil
    end)
    return ok and result == true
end

local function _processSymbolArguments(args)
    local result = {
        mode          = nil,
        colors        = {},
        pointSize     = nil,
        weight        = nil,
        scale         = nil,
        variableValue = nil,
    }

    local function setMode(mode)
        if result.mode then
            error("Only one rendering mode can be given, got " .. mode)
        end
        result.mode = mode
    end

    -- table.flatten would splice an option's own values into the argument list,
    -- so options are checked before it is applied.
    for _, arg in ipairs(args) do
        if type(arg) == "table" and arg[OPTION_TAG] then
            local kind = arg[OPTION_TAG]

            if kind == "variable" then
                result.variableValue = arg.values[1]
            else
                setMode(kind)

                for _, value in ipairs(arg.values) do
                    if not _isColor(value) then
                        error("image.symbol." .. kind .. " expects colors, got " .. type(value))
                    end
                    table.insert(result.colors, value)
                end
            end
        else
            for _, flat in ipairs(table.flatten({ arg })) do
                local flatType = type(flat)

                if flatType == "string" then
                    if MODES[flat] then
                        setMode(MODES[flat])
                    elseif WEIGHTS_BY_CONSTANT[flat] then
                        result.weight = WEIGHTS_BY_CONSTANT[flat]
                    elseif SCALES_BY_CONSTANT[flat] then
                        result.scale = SCALES_BY_CONSTANT[flat]
                    else
                        error("Invalid option: " .. flat)
                    end
                elseif flatType == "number" then
                    result.pointSize = flat
                elseif _isColor(flat) then
                    table.insert(result.colors, flat)
                else
                    error("Invalid argument type: " .. flatType)
                end
            end
        end
    end

    if result.mode == "palette" and #result.colors == 0 then
        error("image.symbol.palette needs at least one color")
    end

    return result
end

--- Builds the UIImageSymbolConfiguration for the requested options, or nil when
--- no configuration is needed. Must be called with bridging disabled so the
--- configuration objects stay as Objective-C objects.
local function _configuration(options)
    local configuration = nil

    local function apply(other)
        if other == nil then
            return
        end

        if configuration == nil then
            configuration = other
        else
            configuration = configuration:configurationByApplyingConfiguration_(other)
        end
    end

    if options.pointSize and options.weight then
        apply(objc.UIImageSymbolConfiguration:configurationWithPointSize_weight_(options.pointSize, options.weight))
    elseif options.pointSize then
        apply(objc.UIImageSymbolConfiguration:configurationWithPointSize_(options.pointSize))
    elseif options.weight then
        apply(objc.UIImageSymbolConfiguration:configurationWithWeight_(options.weight))
    end

    if options.scale then
        apply(objc.UIImageSymbolConfiguration:configurationWithScale_(options.scale))
    end

    -- Note the trailing underscore on the parameterless selectors -- without it
    -- the bridge silently returns nil for a class method.
    if options.mode == "multicolor" then
        apply(objc.UIImageSymbolConfiguration:configurationPreferringMulticolor_())
    elseif options.mode == "hierarchical" then
        apply(objc.UIImageSymbolConfiguration:configurationWithHierarchicalColor_(options.colors[1] or color(255)))
    elseif options.mode == "palette" then
        apply(objc.UIImageSymbolConfiguration:configurationWithPaletteColors_(options.colors))
    end

    return configuration
end

--- image.symbol(name, options...)
---
--- Returns a Codea image for the named SF Symbol, or nil when no such symbol
--- exists. Monochrome symbols are rendered white rather than UIKit's black, so
--- the existing tint() idiom works:
---
---     img = image.symbol("globe")
---     tint(255, 0, 0)
---     sprite(img, WIDTH/2, HEIGHT/2)
---
--- Multicolour and palette symbols carry their own colours -- draw those with
--- tint(255), since tint multiplies.
---
--- image.symbol.variable takes the number after it as a fill level from 0 to 1,
--- for symbols that support variable rendering (wifi, speaker, battery). Symbols
--- without it ignore the value.
---
---     img = image.symbol("wifi", image.symbol.variable, 0.66)
local function systemSymbol(name, ...)
    if type(name) ~= "string" then
        error("image.symbol expects a symbol name as its first argument, got " .. type(name))
    end

    local options = _processSymbolArguments({...})

    local native = objc.withoutBridging(function()
        local configuration = _configuration(options)

        local uiImage
        if options.variableValue then
            -- Takes the configuration directly, nil included, so there is no
            -- separate no-configuration form to handle here.
            uiImage = objc.UIImage:systemImageNamed_variableValue_withConfiguration_(
                name, options.variableValue, configuration)
        elseif configuration then
            uiImage = objc.UIImage:systemImageNamed_withConfiguration_(name, configuration)
        else
            uiImage = objc.UIImage:systemImageNamed_(name)
        end

        if uiImage == nil then
            return nil
        end

        -- A template symbol renders black, and black multiplied by any tint is
        -- still black, which is what makes an untinted symbol impossible to
        -- recolour. Render it in the requested colour (white by default) so
        -- both the explicit colour and draw-time tint() work.
        if options.mode == nil or options.mode == "monochrome" then
            uiImage = uiImage:imageWithTintColor_(options.colors[1] or color(255))
        end

        return uiImage
    end)

    if native == nil then
        return nil
    end

    return objc.bridge(native)
end

setmetatable(symbol, {
    __call = function(self, name, ...)
        return systemSymbol(name, ...)
    end
})

-- rawset, not assignment: image is a sol2 usertype, and a plain assignment
-- registers a static member that also shows up on every image instance (the
-- same collision that image.filter / image.wrap hit).
rawset(image, "symbol", symbol)
