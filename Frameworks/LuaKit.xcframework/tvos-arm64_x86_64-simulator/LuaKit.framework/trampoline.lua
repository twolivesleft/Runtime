-- The trampoline functions are used for the debuggee to be able to see the top-level function name.
-- Local result variables are used to avoid tail-call optimizations.

function __touched(...)
    local result = touched(...)
    return result
end

function __setup()
    local result = setup()
    return result
end

function __draw()
    local result = draw()
    return result
end

function __sizeChanged(...)
    local result = sizeChanged(...)
    return result
end

function __keyPressed(...)
    local result = keyPressed(...)
    return result
end

function __keyReleased(...)
    local result = keyReleased(...)
    return result
end

function __scroll(...)
    local result = scroll(...)
    return result
end

function __hover(...)
    local result = hover(...)
    return result
end

function __fixedUpdate(...)
    local result = fixedUpdate(...)
    return result
end

function __update(...)
    local result = update(...)
    return result
end
