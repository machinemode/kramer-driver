local lu = require("luaunit")
local fun = require("libs.functional")

TestFunctional = {}
function TestFunctional:test_unique()
    local items = { 'A', 'B', 'A', 'A', 'C', 'C' }
    local u = fun.totable(fun.unique(items))
    lu.assertItemsEquals(u, { 'A', 'B', 'C' })
    lu.assertEquals(#u, 3)
end

function TestFunctional:test_unique_table()
    local t1 = { foo = 1, bar = 2 }
    local t2 = { cat = 'a', dog = 'b' }
    local items = { t1, t2, t1, t1, t2 }

    local u = fun.totable(fun.unique(items))

    lu.assertItemsEquals(u, { t1, t2 })
    lu.assertEquals(#u, 2)
end

function TestFunctional:test_first()
    local items = { 'A', 'B', 'C' }
    lu.assertEquals(fun.first(items), 'A')
end

function TestFunctional:test_as_array()
    lu.assertEquals(fun.as_array(), { [0]= 0 })
    lu.assertEquals(fun.as_array({}), { [0]= 0 })

    local item_array = { 'A', 'B', 'C' }
    lu.assertEquals(fun.as_array(item_array), item_array)

    local item_table = {
        ['A'] = {
            name = 'foo',
            value = 1
        },
        ['B'] = {
            name = 'bar',
            value = 2
        },
        ['C'] = {
            name = 'meh',
            value = 3
        }
    }
    lu.assertItemsEquals(fun.as_array(item_table), { 'A', 'B', 'C' })
end
