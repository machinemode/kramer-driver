local string_utils = {}

function string_utils.trim(str)
    local trimmed = str and string.gsub(str, "^%s*(.-)%s*$", "%1") or ""
    return trimmed
end

function string_utils.is_empty(str)
    return str == nil or str == ""
end

function string_utils.append_if(str, append, predicate)
    return string.format(
        "%s%s",
        str,
        predicate(str) and append or ""
    )
end

function string_utils.replace_special_chars(str, replacement)
    local updated_str = str and string.gsub(str, "[%p%c%s]", replacement) or ""
    return updated_str
end

return string_utils
