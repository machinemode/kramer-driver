local lu = require("luaunit")
local state = require("device_driver.state")
local fun = require("libs.functional")

TestState = {}

function TestState:test_to_boolean()
    lu.assertTrue(state.to_boolean('ON'))
    lu.assertTrue(state.to_boolean('true'))
    lu.assertFalse(state.to_boolean('OFF'))
    lu.assertFalse(state.to_boolean('false'))
    lu.assertFalse(state.to_boolean(''))
end

function TestState:test_create_state()
    local category_state = state.init('TEST')
    local s = category_state('A', 'foo')(10, 0.10)
    lu.assertItemsEquals(s, {
        category_id = 'TEST',
        state_id = 'A',
        state_key = 'foo',
        state_value = 10,
        state_normalized_value = 0.10
    })
end

function TestState:test_create_state_without_key()
    local category_state = state.init('TEST')
    local s = category_state('A')(10)
    lu.assertEquals(s.category_id, 'TEST')
    lu.assertEquals(s.state_id, 'A')
    lu.assertNil(s.state_key)
    lu.assertEquals(s.state_value, 10)
    lu.assertNil(s.state_normalized_value)
end

function TestState:test_create_state_with_key()
    local category_state = state.init('TEST')
    local s = category_state('A', 'foo')(10)
    lu.assertEquals(s.category_id, 'TEST')
    lu.assertEquals(s.state_id, 'A')
    lu.assertEquals(s.state_key, 'foo')
    lu.assertEquals(s.state_value, 10)
    lu.assertNil(s.state_normalized_value)
end

function TestState:test_create_state_normalized_value()
    local category_state = state.init('TEST')
    local s = category_state('A')(10, 0.1)

    lu.assertEquals(s.state_value, 10)
    lu.assertEquals(s.state_normalized_value, 0.1)
end

function TestState:test_get_state_keys()
    local category_state = state.init('TEST')
    local states = {
        category_state('foo', 'A')(1),
        category_state('foo', 'B')(2),
        category_state('bar', 'W')(3),
        category_state('foo', 'C')(3),
        category_state('bar', 'X')(3),
        category_state('bar', 'Y')(3),
        category_state('bar', 'Z')(3)
    }

    lu.assertItemsEquals(state.keys(states, 'foo'), { 'A', 'B', 'C' })
    lu.assertItemsEquals(state.keys(states, 'test'), { })
end

function TestState:test_find_one_state_by_state_id()
    local category_state = state.init('TEST')
    local states = {
        category_state('foo', 'A')(1),
        category_state('foo', 'B')(2),
        category_state('bar', 'W')(3),
        category_state('foo')(3),
        category_state('bar', 'X')(3),
        category_state('bar', 'Y')(3),
        category_state('bar', 'Z')(3)
    }

    lu.assertItemsEquals(state.find_first(states, 'foo'), category_state('foo')(3))
end

function TestState:test_find_all_states_by_state_id()
    local category_state = state.init('TEST')
    local states = {
        category_state('foo', 'A')(1),
        category_state('foo', 'B')(2),
        category_state('bar', 'W')(3),
        category_state('foo')(3),
        category_state('bar', 'X')(3),
        category_state('bar', 'Y')(3),
        category_state('bar', 'Z')(3)
    }

    lu.assertItemsEquals(state.find_all(states, 'foo'), {
        category_state('foo', 'A')(1),
        category_state('foo', 'B')(2),
        category_state('foo')(3)
    })
end

function TestState:test_find_state_by_state_id_and_key()
    function test_get_state_by_state_id()
        local category_state = state.init('TEST')
        local states = {
            category_state('foo', 'A')(1),
            category_state('foo', 'B')(2),
            category_state('bar', 'W')(3),
            category_state('foo', 'C')(3),
            category_state('bar', 'X')(3),
            category_state('bar', 'Y')(3),
            category_state('bar', 'Z')(3)
        }

        lu.assertItemsEquals(state.find_first(states, 'foo', 'C'), category_state('foo', 'C')(3))
    end
end

function TestState:test_copy()
    lu.assertItemsEquals(state.copy(), {})
    lu.assertItemsEquals(state.copy({}), {})

    local a = {
        category_id = "A",
        state_id = "B",
        state_key = "C",
        state_value = "D",
        state_normalized_value = "E"
    }
    lu.assertItemsEquals(state.copy(a), a)

    local b = {
        category_id = "A",
        state_id = "B",
        state_value = "D"
    }
    lu.assertItemsEquals(state.copy(b), b)

    local c = {
        category_id = "A",
        state_id = "B",
        state_key = "",
        state_value = "D",
        state_normalized_value = ""
    }
    lu.assertItemsEquals(state.copy(c), {
        category_id = "A",
        state_id = "B",
        state_value = "D"
    })

    local category_state = state.init('TEST')

    lu.assertItemsEquals(state.copy(category_state("FOO")("")), {
        category_id = "TEST",
        state_id = "FOO",
        state_value = ""
    })
end

function TestState:test_update_state()
    local category_state = state.init('TEST')
    local states = {
        category_state('A')(1),
        category_state('B')(2),
        category_state('C')(3)
    }

    local updated = state.update(states, category_state('B')(10))

    lu.assertItemsEquals(updated, {
        category_state('A')(1),
        category_state('B')(10),
        category_state('C')(3)
    })

    lu.assertItemsEquals(states, {
        category_state('A')(1),
        category_state('B')(2),
        category_state('C')(3)
    })
end

function TestState:test_state_equality()
    local category_state = state.init('TEST')
    local s1 = category_state('foo', 'A')(1, 0.1)

    lu.assertTrue(state.equals(s1, category_state('foo', 'A')(1, 0.1)))

    lu.assertTrue(state.equals(s1, {
        category_id = 'TEST',
        state_id = 'foo',
        state_key = 'A',
        state_value = 1,
        state_normalized_value = 0.1
    }))

    lu.assertFalse(state.equals(s1, {
        category_id = 'TEST',
        state_id = 'bar',
        state_key = 'A',
        state_value = 1,
        state_normalized_value = 0.1
    }))
end

function TestState:test_nil_state_equality()
    lu.assertFalse(state.equals(nil, {
        category_id = 'TEST',
        state_id = 'foo',
        state_key = 'A',
        state_value = 1,
        state_normalized_value = 0.1
    }))

    lu.assertFalse(state.equals({
        category_id = 'TEST',
        state_id = 'bar',
        state_key = 'A',
        state_value = 1,
        state_normalized_value = 0.1
    }, nil))
end

function TestState:test_merge()
    local category_state = state.init('TEST')
    local states = {
        category_state('A')(1),
        category_state('B')(2),
        category_state('C')(3)
    }
    lu.assertItemsEquals(
        state.merge(states, {
            category_state('B')(10),
            category_state('D')(4),
        }),
        {
            category_state('A')(1),
            category_state('B')(10),
            category_state('C')(3),
            category_state('D')(4),
        }
    )
end
