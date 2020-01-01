local lu = require("luaunit")
local json = require("lunajson")
local state = require("device_driver.state")
local extras = require("src.extras_driver")
require("device_driver.category")

TestExtrasDriver = {}
function TestExtrasDriver:setUp()
    initialize(extras)
end

-- getExecutionResult("[\"HTTP\"]", "SYSTEM", "INITIALIZE", "{}")
function TestExtrasDriver:test_initialize_command()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "SYSTEM",
        "INITIALIZE",
        {}
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "LUA_VERSION"), {
        category_id = "CUSTOM",
        state_id = "LUA_VERSION",
        state_value = "Lua 5.3"
    })

    -- TODO...

    -- Lua 5.3 does not convert boolean and nil with string.format using %q :(
    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end

-- getExecutionResult("[\"HTTP\"]", "NETWORK", "MULTICAST_IDENTITY", "{}")
function TestExtrasDriver:test_multicast_command()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "NETWORK",
        "MULTICAST_IDENTITY",
        {}
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    lu.assertEquals(state_changes, [[{"state_changes":[]}]])

    -- Lua 5.3 does not convert boolean and nil with string.format using %q :(
    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end
