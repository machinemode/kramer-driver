local lu = require("luaunit")
local comm_types = require("device_driver.comm_types")
local fun = require("libs.functional")

TestCommTypes = {}
function TestCommTypes:test_get_generic_comm_types()
    local available_protocols = { "KNX", "IR_EMITTER", "RS232", "RS485", "UDP_UNICAST" }
    local comm_types = fun.totable(comm_types.get_generic_comm_types(available_protocols))
    lu.assertItemsEquals(comm_types, { "TCP_UDP", "IR", "SERIAL", "SERIAL", "TCP_UDP" })
    lu.assertEquals(#comm_types, 5)
end

function TestCommTypes:test_get_generic_comm_types_unknowns()
    local available_protocols = { "KNX", "bar", "RS232", "RS485", "foo" }
    local comm_types = fun.totable(comm_types.get_generic_comm_types(available_protocols))
    lu.assertItemsEquals(comm_types, { "TCP_UDP", "SERIAL", "SERIAL" })
    lu.assertEquals(#comm_types, 3)
end

function TestCommTypes:test_find_comm_types()
    local available_protocols = { "KNX", "IR_EMITTER", "RS232", "RS485", "UDP_UNICAST" }
    local c = fun.totable(fun.unique(comm_types.get_generic_comm_types(available_protocols)))
    lu.assertItemsEquals(c, { "TCP_UDP", "IR", "SERIAL" })
    lu.assertEquals(#c, 3)
end
