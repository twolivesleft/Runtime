function _getMetaCodeaName(obj)
    return obj.__metaCodeaName
end

function typeof(obj)
    -- Safety in case the object has a custom __index metamethod that throws an error
    local status, result = pcall(_getMetaCodeaName, obj)
    if status and result ~= nil then
        return result
    end

    return type(obj)
end
