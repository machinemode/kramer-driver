local time_utils = {}

function time_utils.get_formatted_time(format)
    local content = os.date(format)

    if type(content) == "string" then
        content = string.gsub(content, "[\n\r]", "\\n")
        content = string.gsub(content, '"', '\\"')
        content = string.gsub(content, "'", "\\'")
        return content
    else
        -- TODO: log to console
        return ""
    end
end

return time_utils
