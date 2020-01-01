local json = require("lunajson")
local state = require("device_driver.state")
local system = require("libs.system")

local common = {}

function common.common_commands(generic_comm_types, state_backup_dir, category_state, log)
    return {
        ['INITIALIZE'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function()
                local previous_states = system.restore(state_backup_dir, json.decode)

                local default_states = {
                    category_state("LOG_LEVEL")(log.level),
                }

                return state.merge(default_states, previous_states)
            end
        },
        ['SET_LOG_LEVEL'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                local level = args['LOG_LEVEL']
                log:setLevel(level)
                local level_msg = "log level set to " .. level

                log:debug(level_msg)
                log:info(level_msg)
                log:warn(level_msg)
                log:error(level_msg)

                return {
                    category_state("LOG_LEVEL")(level)
                }
            end
        },
        ['SET_AUTO_SAVE_STATE'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                return {
                    category_state("AUTO_SAVE_STATE")(args['AUTO_SAVE_STATE'])
                }
            end
        },
        ['SAVE_STATE'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function()
                system.backup(state_backup_dir, GetStates(), json.encode)
                return { }
            end
        },
        ['CLEAR_STATE_BACKUPS'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function()
                system.remove_backups(state_backup_dir)
                return { }
            end
        },
    }
end

return common
