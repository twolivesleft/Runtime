------------------------------------------------
-- Import common libraries into global namespace
------------------------------------------------

json = require("codea.dkjson").use_lpeg()
class = require("codea.middleclass")
lustache = require("codea.lustache")
legacy = require("codea.legacy")

function is(thing, t)
    if type(t) == 'string' then
        return type(thing) == t
    elseif type(thing) == 'userdata' and type(t) == 'table' and t.__type then
        return t.__type.is(thing)
    elseif type(thing) == 'table' and thing.class then
        return thing.class == t
    end
    return false
end

------------------------------------------------
-- Block out any dangerous or insecure functions
------------------------------------------------

arg=nil

os.execute=nil
os.exit=nil

------------------------------------------------
-- Export legacy functions
------------------------------------------------

legacy:export()
