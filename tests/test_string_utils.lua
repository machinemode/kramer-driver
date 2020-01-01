local lu = require("luaunit")
local string_utils = require("libs.string_utils")

TestStringUtils = {}

function TestStringUtils:test_trim()
    lu.assertEquals(string_utils.trim(" foo "), "foo")
    lu.assertEquals(string_utils.trim("  foo "), "foo")
    lu.assertEquals(string_utils.trim("     foo     "), "foo")
end

function TestStringUtils:test_is_empty()
    lu.assertTrue(string_utils.is_empty(""))
    lu.assertTrue(string_utils.is_empty())
    lu.assertFalse(string_utils.is_empty("foo"))
end

function TestStringUtils:test_append_if()
    lu.assertEquals(
        "food",
        string_utils.append_if("foo", "d", function(str) return string.sub(str, -2) == "oo" end)
    )

    lu.assertEquals(
        "some/path/without/slash/",
        string_utils.append_if("some/path/without/slash", "/", function(str) return string.sub(str, -1) ~= "/" end)
    )

    lu.assertEquals(
        "some/path/with/slash/",
        string_utils.append_if("some/path/with/slash/", "/", function(str) return string.sub(str, -1) ~= "/" end)
    )
end

function TestStringUtils:test_replace_specials()
    lu.assertEquals(string_utils.replace_special_chars("foo.sh", "_"), "foo_sh")
    lu.assertEquals(string_utils.replace_special_chars(".foo..sh", "_"), "_foo__sh")
    lu.assertEquals(string_utils.replace_special_chars("/root/proc/foo", "_"), "_root_proc_foo")
    lu.assertEquals(string_utils.replace_special_chars("This is fun!", "_"), "This_is_fun_")
end
