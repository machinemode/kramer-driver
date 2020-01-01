local lu = require("luaunit")
local driver = require("device_driver.driver")
local fun = require("libs.functional")

TestDriver = {}
function TestDriver:test_hide_data()
    lu.assertNil(driver.states)
    lu.assertNil(driver.capabilities)
    lu.assertNil(driver.macros)

    driver.initialize()
    lu.assertNil(driver.states)
    lu.assertNil(driver.capabilities)
    lu.assertNil(driver.macros)
end

function TestDriver:test_get_macros()
    local macros = {
        {
            reference_id = "MACRO_1",
            name = "Macro1",
            elements = {}
        },
        {
            reference_id = "MACRO_2",
            name = "Macro2",
            elements = {}
        },
        {
            reference_id = "MACRO_3",
            name = "Macro3",
            elements = {}
        }
    }

    driver.initialize(nil, nil, macros)

    lu.assertEquals(driver.get_macros(), macros, "Macros are all returned in order")
end

function TestDriver:test_get_state_keys()
    local states = {
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "A",
            state_value = 1
        },
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "B",
            state_value = 2
        },
        {
            category_id = "TEST",
            state_id = "bar",
            state_value = 3
        }
    }

    driver.initialize(states)
    lu.assertItemsEquals(driver.get_state_keys('foo'), { 'A', 'B' })
end

function TestDriver:test_get_unknown_state_keys()
    driver.initialize({})
    lu.assertEquals(driver.get_state_keys('foo'), fun.as_array({}))
end

function TestDriver:test_get_state_value()
    local states = {
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "A",
            state_value = 1,
            state_normalized_value = 0.1
        },
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "B",
            state_value = 2,
            state_normalized_value = 0.2
        },
        {
            category_id = "TEST",
            state_id = "bar",
            state_value = 3,
            state_normalized_value = 0.3
        }
    }

    driver.initialize(states)

    local value, normalized = driver.get_state_value('foo', 'B')
    lu.assertEquals(value, 2)
    lu.assertEquals(normalized, 0.2)

    value, normalized = driver.get_state_value('bar')
    lu.assertEquals(value, 3)
    lu.assertEquals(normalized, 0.3)
end

function TestDriver:test_get_unknown_state_values()
    driver.initialize({})
    local value, normalized = driver.get_state_value('bar')
    lu.assertNil(value)
    lu.assertNil(normalized)
end

function TestDriver:test_get_execution_result()
    local states = {
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "A",
            state_value = 1,
            state_normalized_value = 0.1
        },
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "B",
            state_value = 2,
            state_normalized_value = 0.2
        },
        {
            category_id = "TEST",
            state_id = "bar",
            state_value = 3,
            state_normalized_value = 0.3
        }
    }

    local capabilities = {
        ['TEST'] = {
            ['COMMAND_1'] = {
                generic_comm_types = { "HTTP", "SERIAL" },
                linked_feedback_id = "foo",
                macros = {
                    {
                        trigger_macro = {
                            category_id = "CUSTOM",
                            macro_id = "MACRO_1"
                        }
                    },
                    {
                        delay = 5.0
                    }
                },
                codes = function(args)
                    return { "test", "foo", "bah" }
                end,
                state_changes = function(args)
                    return {
                        {
                            category_id = "TEST",
                            state_id = "foo",
                            state_key = "B",
                            state_value = 10,
                            state_normalized_value = 1
                        },
                        {
                            category_id = "TEST",
                            state_id = "bar",
                            state_value = 5,
                            state_normalized_value = 0.5
                        }
                    }
                end
            }
        }
    }

    driver.initialize(states, capabilities)
    local generic_comm_type,
        codes,
        state_changes,
        linked_feedback_id,
        macros = driver.get_execution_result('TEST', 'COMMAND_1', nil, { "RS422", "GPIO", "KNX" })

        lu.assertEquals(generic_comm_type, "SERIAL")
        lu.assertItemsEquals(codes, { "test", "foo", "bah" })
        lu.assertItemsEquals(state_changes, {
            {
                category_id = "TEST",
                state_id = "foo",
                state_key = "B",
                state_value = 10,
                state_normalized_value = 1
            },
            {
                category_id = "TEST",
                state_id = "bar",
                state_value = 5,
                state_normalized_value = 0.5
            }
        })
        lu.assertEquals(linked_feedback_id, "foo")
        lu.assertItemsEquals(macros, {
            {
                trigger_macro = {
                    category_id = "CUSTOM",
                    macro_id = "MACRO_1"
                }
            },
            {
                delay = 5.0
            }
        })

end

function TestDriver:test_get_execution_result_unknown_cmd()
    driver.initialize(nil, {})
    local generic_comm_type,
        codes,
        state_changes,
        linked_feedback_id,
        macros = driver.get_execution_result('foo', 'bar', nil, { "HTTP" })

    lu.assertNil(generic_comm_type)
    lu.assertNil(codes)
    lu.assertNil(state_changes)
    lu.assertNil(linked_feedback_id)
    lu.assertNil(macros)
end

function TestDriver:test_apply_state_change()
    local states = {
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "A",
            state_value = 1,
            state_normalized_value = 0.1
        },
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "B",
            state_value = 2,
            state_normalized_value = 0.2
        },
        {
            category_id = "TEST",
            state_id = "bar",
            state_value = 3,
            state_normalized_value = 0.3
        }
    }

    driver.initialize(states)
    local changed = driver.apply_state_change({
        category_id = "TEST",
        state_id = "foo",
        state_key = "A",
        state_value = 5,
        state_normalized_value = 0.5
    })

    lu.assertTrue(changed)

    local value, normalized = driver.get_state_value('foo', 'A')
    lu.assertEquals(value, 5)
    lu.assertEquals(normalized, 0.5)
end

function TestDriver:test_apply_unknown_state_change()
    local states = {
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "A",
            state_value = 1,
            state_normalized_value = 0.1
        },
        {
            category_id = "TEST",
            state_id = "foo",
            state_key = "B",
            state_value = 2,
            state_normalized_value = 0.2
        },
        {
            category_id = "TEST",
            state_id = "bar",
            state_value = 3,
            state_normalized_value = 0.3
        }
    }

    driver.initialize(states)
    local changed = driver.apply_state_change({
        category_id = "TEST",
        state_id = "bah",
        state_key = "C",
        state_value = 5,
        state_normalized_value = 0.5
    })

    lu.assertTrue(changed, "Unknown states should be added")

    local value, normalized = driver.get_state_value('bah', 'C')
    lu.assertEquals(value, 5)
    lu.assertEquals(normalized, 0.5)
end

function TestDriver:test_on_change()
    local state_change = {
        category_id = "CUSTOM",
        state_id = "AUTO_SAVE_STATE",
        state_value = 1
    }

    driver.initialize(nil, nil, nil, function (a, b)
        lu.assertNil(a)
        lu.assertItemsEquals(b, state_change)
    end)
    lu.assertTrue(driver.apply_state_change(state_change))
end
