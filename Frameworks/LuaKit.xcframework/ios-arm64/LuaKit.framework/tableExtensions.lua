table.flatten = function(t)
    if type(t) ~= "table" then
        return {t}
    end

    local result = {}

    for i, v in ipairs(t) do
        if type(v) == "table" then
            local subResult = table.flatten(v)
            for i, subV in ipairs(subResult) do
                table.insert(result, subV)
            end
        else
            table.insert(result, v)
        end
    end

    return result
end
