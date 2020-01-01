local lu = require("luaunit")
local json = require("lunajson")
local time_utils = require("libs.time_utils")
require("device_driver.category")

TestCategory = {}
function TestCategory:setUp()
    initialize({
        capabilities = {
            ['CLOCK'] = {
                ['GET_FORMATTED_DATE'] = {
                    generic_comm_types = { "HTTP" },
                    state_changes = function(args)
                        return {
                            {
                                category_id = "CUSTOM",
                                state_id = "FORMATTED_DATE",
                                state_key = args['KEY'],
                                state_value = time_utils.get_formatted_time(args['FORMAT'])
                            }
                        }
                    end
                }
            }
        },
        initialize = function ()
            -- Do nothing
        end
    })
end

function TestCategory:test_get_macros()
    lu.assertIsString(getMacros(), "Is a string")
    lu.assertEquals(getMacros(), [[{"macros":[]}]], "Return an empty array")
end

function TestCategory:test_get_state_keys()
    lu.assertIsString(queryAllKeys(), "Is a string")

    lu.assertEquals(queryAllKeys(), [[{"keys":[]}]], "Return an empty array when nil")
    lu.assertEquals(queryAllKeys("FOO"), [[{"keys":[]}]], "Return an empty array when nil")

    -- lu.assertEquals(queryAllKeys("STATE_1"), [[{"keys":["1","2","bar","foo"]}]])
    -- lu.assertEquals(queryAllKeys("STATE_2"), [[{"keys":["2","bar"]}]])
end

function TestCategory:test_get_state_values()
    local actual, normalized = queryStateValue()
    lu.assertEquals(actual, nil, "nil state id results in nil value")
    lu.assertEquals(normalized, nil, "nil state id results in nil value")

    local actual, normalized = queryStateValue("foo")
    lu.assertEquals(actual, nil, "Unknown state id results in nil value")
    lu.assertEquals(normalized, nil, "Unknown state id results in nil value")

    local actual, normalized = queryStateValue("LUA_VERSION", "test")
    lu.assertEquals(actual, nil, "Unknown state key results in nil value")
    lu.assertEquals(normalized, nil, "Unknown state key results in nil value")

    -- local actual, normalized = queryStateValue("LUA_VERSION", nil)
    -- lu.assertEquals(actual, _VERSION, "Access a state value (nil key)")
    -- lu.assertNil(normalized, "Access a state value (nil key)")

    local actual, normalized = queryStateValue("LUA_VERSION", "")
    lu.assertEquals(actual, nil, "Access a state value (empty string key)")
    lu.assertEquals(normalized, nil, "Access a state value (empty string key)")

    local actual, normalized = queryStateValue("LUA_VERSION", "1")
    lu.assertEquals(actual, nil, "Access a keyed state value")
    lu.assertEquals(normalized, nil, "Access a keyed state value")
end

function TestCategory:test_get_execution_result()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "CLOCK",
        "GET_FORMATTED_DATE",
        {
            ["FORMAT"] = "%c",
            ["KEY"] = "TEST"
        }
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])

    local state_change = json.decode(state_changes).state_changes[1]
    lu.assertEquals(state_change.category_id, "CUSTOM")
    lu.assertEquals(state_change.state_id, "FORMATTED_DATE")
    lu.assertEquals(state_change.state_key, "TEST")
    lu.assertIsString(state_change.state_value)
    lu.assertNil(state_change.state_normalized_value)

    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end

function TestCategory:test_apply_state_change()
    local state_change = {
        device_id = "",
        state_key = "test",
        state_value = "Wednesday is November",
        state_id = "FORMATTED_DATE",
        category_id = "CUSTOM",
        state_normalized_value = ""
    }

    lu.assertTrue(applyStateChange(state_change, true))
end
