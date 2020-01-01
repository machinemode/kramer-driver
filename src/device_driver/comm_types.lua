local comm_types = {}
local fun = require("libs.functional")

--- protocol -> comm_type -> generic_comm_type
local generic_comm_type = {
    ["IR_EMITTER"] = "IR",
    ["RS232"] = "SERIAL",
    ["RS422"] = "SERIAL",
    ["RS485"] = "SERIAL",
    ["TCP"] = "TCP_UDP",
    ["TELNET"] = "TCP_UDP",
    ["SSH"] = "TCP_UDP",
    ["UDP_UNICAST"] = "TCP_UDP",
    ["UDP_MULTICAST"] = "TCP_UDP",
    ["UDP_BROADCAST"] = "TCP_UDP",
    ["UDP"] = "TCP_UDP",
    ["KNX_TUNNELING"] = "TCP_UDP",
    ["KNX_ROUTING"] = "TCP_UDP",
    ["KNX"] = "TCP_UDP",
    ["HTTP"] = "HTTP",
    ["RELAY"] = "RELAY",
    ["GPIO"] = "GPIO",
    ["USB"] = "SERIAL"
}

function comm_types.get_generic_comm_types(protocols)
    return fun.map(function(protocol) return generic_comm_type[protocol] end, protocols)
end


return comm_types
