local lu = require("luaunit")
local time_utils = require("libs.time_utils")

TestTimeUtils = {}
function TestTimeUtils:test_simple_time_format()
    local result = time_utils.get_formatted_time()
    lu.assertTrue(type(result) == "string")
end

function TestTimeUtils:test_time_format_newlines()
    local result = time_utils.get_formatted_time("%A \r %B \n %H \n\r")
    lu.assertNotStrContains(result, "\r")
end

function TestTimeUtils:test_time_format_escape_quotes()
    local result = time_utils.get_formatted_time([[%A "foo" 'bar']])
    lu.assertStrContains(result, '\\"foo\\"')
    lu.assertStrContains(result, "\\'bar\\'")
end
