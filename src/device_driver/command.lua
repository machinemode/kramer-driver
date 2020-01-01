local fun = require("libs.functional")
local comm_types = require("device_driver.comm_types")

local command = {}

local function get_generic_comm_types(protocols)
    return fun.unique(
        comm_types.get_generic_comm_types(protocols)
    )
end

local function has_generic_comm_type(comm_type, comm_types)
    return fun.any(
        function(c) return c == comm_type end,
        comm_types
    )
end

local function find_possible_comm_types(generic_comm_types, protocols)
    local available_comm_types = get_generic_comm_types(protocols)

    return fun.filter(
        function(comm_type) return has_generic_comm_type(comm_type, available_comm_types) end,
        generic_comm_types
    )
end

function command.find_first_comm_type(cmd, protocols)
    return fun.first(
        find_possible_comm_types(cmd.generic_comm_types, protocols)
    )
end

function command.find(capabilities, capability_id, command_id)
    local capability = capabilities[capability_id]
    return capability and capability[command_id]
end

return command
