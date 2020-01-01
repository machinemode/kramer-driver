local name = "extras"
local log = require("libs.logger").defaultLogger(name, "INFO")
local common = require("common")

local json = require("lunajson")
local state = require("device_driver.state")

local beacon = require("libs.beacon")
local brain_api = require("libs.brain_api")
local system = require("libs.system")
local time_utils = require("libs.time_utils")

local STATE_BACKUP_DIR = string.format("resources/data/%s/state/", name)

local config = {}
local category_state = state.init("CUSTOM")
local generic_comm_types = { "HTTP" }

config.initial_states = {}

config.capabilities = {
    ['SYSTEM'] = common.common_commands(generic_comm_types, STATE_BACKUP_DIR, category_state, log),
    ['CLOCK'] = {
        ['GET_FORMATTED_DATE'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                return {
                    category_state("FORMATTED_DATE", args['KEY'])(time_utils.get_formatted_time(args['FORMAT']))
                }
            end
        }
    },
    ['CUSTOM'] = {
        ['SET_BOOLEAN'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                return {
                    category_state("BOOLEANS", args['KEY'])(args['VALUE'])
                }
            end
        },
        ['SET_NUMBER'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                return {
                    category_state("NUMBERS", args['KEY'])(args['VALUE'])
                }
            end
        },
        ['SET_STRING'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                return {
                    category_state("STRINGS", args['KEY'])(args['VALUE'])
                }
            end
        },
        ['SET_TIMESTAMP'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                return {
                    category_state("TIMESTAMPS", args['KEY'])(tostring(system.get_epoch_datetime_ms()))
                }
            end
        }
    },
    ['NETWORK'] = {
        ['UNICAST_IDENTITY'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                local address = args['DESTINATION_ADDRESS']
                local brain = brain_api.get_brain_data()

                beacon.unicast(address, brain.udp_port, {
                    beacon_type = "brain_identify",
                    brain_version = brain.version,
                    port = tonumber(brain.tcp_port),
                    space_id = brain.space_id
                })

                return { }
            end
        },
        ['MULTICAST_IDENTITY'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function()
                local brain = brain_api.get_brain_data()

                beacon.multicast(brain.udp_port, {
                    beacon_type = "brain_identify",
                    brain_version = brain.version,
                    port = tonumber(brain.tcp_port),
                    space_id = brain.space_id
                })

                return { }
            end
        }
    }
}

-- Override INITIALIZE from common
config.capabilities['SYSTEM']['INITIALIZE'] = {
    generic_comm_types = generic_comm_types,
    state_changes = function()
        local brain = brain_api.get_brain_data()
        local project = brain_api.get_project_data()
        local space = brain_api.get_space_data()

        local default_states = {
            category_state("LOG_LEVEL")(log.level)
        }

        local previous_states = system.restore(STATE_BACKUP_DIR, json.decode)

        local current_states = {
            category_state("LUA_VERSION")(_VERSION),
            category_state("OS", "KERNEL_NAME")(system.get_kernel_name()),
            category_state("OS", "KERNEL_RELEASE")(system.get_kernel_release()),
            category_state("OS", "KERNEL_VERSION")(system.get_kernel_version()),
            category_state("OS", "MACHINE")(system.get_machine_name()),
            category_state("OS", "OPERATING_SYSTEM")(system.get_os()),
            category_state("OS", "HOSTNAME")(system.get_hostname()),
            category_state("OS", "USER")(system.get_whoami()),
            category_state("OS", "WORKING_DIR")(system.get_pwd()),

            category_state("BRAIN", "BRAIN_ID")(brain.brain_id),
            category_state("BRAIN", "VERSION")(brain.version),
            category_state("BRAIN", "TCP_PORT")(tostring(brain.tcp_port)),
            category_state("BRAIN", "UDP_PORT")(tostring(brain.udp_port)),

            category_state("PROJECT", "ID")(project.id),
            category_state("PROJECT", "NAME")(project.name),
            category_state("PROJECT", "LOCALE")(project.locale),
            category_state("PROJECT", "LOCATION")(project.location),
            category_state("PROJECT", "TIMEZONE_ID")(project.timezone_id),

            category_state("SPACE", "ID")(space.id),
            category_state("SPACE", "NAME")(space.name),
            category_state("SPACE", "TYPE")(space.type)
        }

        return state.merge(
            state.merge(default_states, previous_states),
            current_states
        )
    end
}

config.macros = {}

local function can_auto_save()
    local auto_save_state = state.find_first(GetStates(), "AUTO_SAVE_STATE")
    return auto_save_state == nil or state.to_boolean(auto_save_state.state_value)
end

config.on_state_change = function()
    if can_auto_save() then
        system.backup(STATE_BACKUP_DIR, GetStates(), json.encode)
    end
end

function config.initialize()
    system.init(STATE_BACKUP_DIR)
end

return config
