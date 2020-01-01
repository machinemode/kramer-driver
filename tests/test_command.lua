local lu = require("luaunit")
local command = require("device_driver.command")

TestCommand = {}
function TestCommand:test_get_generic_comm_type()
    local c = {
        generic_comm_types = { "HTTP", "SERIAL" }
    }

    local available_protocols = { "KNX", "IR_EMITTER", "RS232", "RS485", "UDP_UNICAST" }
    local generic_comm_type = command.find_first_comm_type(c, available_protocols)
    lu.assertEquals(generic_comm_type, "SERIAL")
end

function TestCommand:test_get_generic_comm_type_order()
    local c = {
        generic_comm_types = { "SERIAL", "TCP_UDP" }
    }

    local available_protocols = { "KNX", "IR_EMITTER", "RS232", "RS485", "UDP_UNICAST" }
    local generic_comm_type = command.find_first_comm_type(c, available_protocols)
    lu.assertEquals(generic_comm_type, "SERIAL")

    c = {
        generic_comm_types = { "TCP_UDP", "SERIAL" }
    }

    local available_protocols = { "KNX", "IR_EMITTER", "RS232", "RS485", "UDP_UNICAST" }
    local generic_comm_type = command.find_first_comm_type(c, available_protocols)
    lu.assertEquals(generic_comm_type, "TCP_UDP")
end

function TestCommand:test_find_command()
    local capabilities = {
        ['TEST'] = {
            ['COMMAND_1'] = {

            },
            ['COMMAND_2'] = {

            },
        }
    }

    lu.assertNotNil(command.find(capabilities, 'TEST', 'COMMAND_1'))
end

function TestCommand:test_find_unknown_command()
    lu.assertNil(command.find({}, 'TEST', 'COMMAND_1'))

    local capabilities = {
        ['TEST'] = {
            ['COMMAND_1'] = {

            },
            ['COMMAND_2'] = {

            },
        }
    }

    lu.assertNil(command.find(capabilities, 'TEST', 'foo'))
end
