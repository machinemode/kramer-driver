local lu = require("luaunit")
local luacheck_driver = require("luacheck_driver")
local system = require("libs.system")

local DATA_DIR = "resources/data/"
TestLuacheckDriver = {}

function TestLuacheckDriver:setUp()
    initialize(luacheck_driver)
    lu.assertTrue(system.exec("mkdir -p " .. DATA_DIR))
    lu.assertTrue(system.copy("tests/device_drivers", DATA_DIR))
end

function TestLuacheckDriver:tearDown()
    system.exec("rm -rf resources")
end

function TestLuacheckDriver:test_check_command()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "CUSTOM",
        "LUA_CHECK",
        {}
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    lu.assertEquals(state_changes, [[{"state_changes":[]}]])
    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end
