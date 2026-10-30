function string.substitute(str, vars)
    -- Allow string.substitute{str, vars} syntax as well as string.substitute(str, {vars})
    if not vars then
        vars = str
        str = vars[1]
    end
    return (string.gsub(str, "({([^}]+)})",
        function(whole,i)
            return vars[i] or whole
        end))
end

function string.split (s, sep)
    sep = lpeg.P(sep)
    local elem = lpeg.C((1 - sep)^0)
    local p = elem * (sep * elem)^0
    return lpeg.match(p, s)
end
