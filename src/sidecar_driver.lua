local name = "sidecar"
local log = require("libs.logger").defaultLogger(name, "INFO")
local json = require("lunajson")
local state = require("device_driver.state")
local common = require("common")

local fun = require("libs.functional")
local sidecar = require("libs.sidecar")
local system = require("libs.system")
local string_utils = require("libs.string_utils")

local STATE_BACKUP_DIR = string.format("resources/data/%s/state/", name)
local UPLOAD_DIR = "resources/www/bundle/"
local BIN_DIR = string.format("resources/data/%s/bin/", name)

local config = {}
local category_state = state.init("CUSTOM")
local generic_comm_types = { "HTTP" }

local function append_trailing_slash(str)
    return str and string_utils.append_if(
        str,
        '/',
        function(s) return string.sub(s, -1) ~= "/" end
    ) or ""
end

local function stop(states, sidecar_name)
    local pid = state.get_value(states, "PID", sidecar_name)
    return not sidecar.is_running(pid) or sidecar.stop(pid)
end

local function stop_all(states, sidecars)
    local state_changes = {}

    -- Stop root sidecar, if any
    if stop(states, nil) then
        table.insert(state_changes, category_state("PID")(nil))
        table.insert(state_changes, category_state("LOG_FILE_PATH")(nil))
    end

    -- Stop keyed sidecars
    fun.each(
        function(sidecar_name)
            if stop(states, sidecar_name) then
                table.insert(state_changes, category_state("PID", sidecar_name)(nil))
                table.insert(state_changes, category_state("LOG_FILE_PATH", sidecar_name)(nil))
            end
        end,
        sidecars
    )

    return state_changes
end

local function get_stopped_state(sidecar_name)
    local pid = state.get_value(GetStates(), "PID", sidecar_name)

    return not sidecar.is_running(pid) and {
        category_state("PID", sidecar_name)(nil),
        category_state("LOG_FILE_PATH", sidecar_name)(nil)
    } or {}
end

local function sanitize_name(str)
    local sidecar_name = string_utils.replace_special_chars(
        string_utils.trim(str),
        "_"
    )

    return not string_utils.is_empty(sidecar_name) and sidecar_name or nil
end

config.initial_states = {}

config.capabilities = {
    ['SYSTEM'] = common.common_commands(generic_comm_types, STATE_BACKUP_DIR, category_state, log),
    ['CUSTOM'] = {
        ['LOAD'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                local binary_path = string_utils.trim(args['BINARY_PATH'])
                local directory_path = string_utils.trim(args['DIRECTORY_PATH'])
                local sidecar_name = sanitize_name(args['APP'])

                if string_utils.is_empty(binary_path) then
                    log:warn("Unable to load empty BINARY_PATH")
                    return {}
                end

                local updated_state = stop(GetStates(), sidecar_name) and get_stopped_state(sidecar_name) or {}

                local bin_dir = string.format(
                    "%s%s",
                    BIN_DIR,
                    append_trailing_slash(sidecar_name)
                )

                system.remove(bin_dir)
                if not system.mkdir(bin_dir) then
                    return {}
                end

                if string_utils.is_empty(directory_path) then
                    if system.copy(UPLOAD_DIR .. binary_path, bin_dir .. binary_path) then
                        return fun.chain(updated_state, {
                            category_state("BINARY_PATH", sidecar_name)(bin_dir .. binary_path)
                        })
                    end
                else
                    directory_path = append_trailing_slash(directory_path)
                    if system.copy(UPLOAD_DIR .. directory_path, bin_dir .. directory_path) then
                        return fun.chain(updated_state, {
                            category_state("BINARY_PATH", sidecar_name)(bin_dir .. directory_path .. binary_path)
                        })
                    end
                end

                return updated_state
            end
        },
        ['START'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                local sidecar_name = sanitize_name(args['APP'])
                local log_file = string_utils.trim(args['LOG_FILE_PATH'])

                local pid = state.get_value(GetStates(), "PID", sidecar_name)
                local path = state.get_value(GetStates(), "BINARY_PATH", sidecar_name)

                if string_utils.is_empty(path) then
                    log:error("BINARY_PATH not found for key " .. (sidecar_name or "nil"))
                    return {}
                else
                    pid = sidecar.restart(path, pid, log_file, args['KEEP_ALIVE'])
                    return {
                        category_state("PID", sidecar_name)(pid),
                        category_state("LOG_FILE_PATH", sidecar_name)(pid and log_file)
                    }
                end
            end
        },
        ['STOP'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                local sidecar_name = sanitize_name(args['APP'])
                return stop(GetStates(), sidecar_name) and get_stopped_state(sidecar_name) or {}
            end
        },
        ['CLEAR_LOG'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                local sidecar_name = sanitize_name(args['APP'])
                local log_file = state.get_value(GetStates(), "LOG_FILE_PATH", sidecar_name)

                if not string_utils.is_empty(log_file) then
                    system.clear(log_file)
                end

                return {}
            end
        },
        ['CHECK'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                return get_stopped_state(sanitize_name(args['APP']))
            end
        }
    }
}

-- Override INITIALIZE from common
config.capabilities['SYSTEM']['INITIALIZE'] = {
    generic_comm_types = generic_comm_types,
    state_changes = function()
        local previous_states = system.restore(STATE_BACKUP_DIR, json.decode)
        local current_states = stop_all(previous_states, state.keys(previous_states, "PID"))

        local default_states = {
            category_state("LOG_LEVEL")(log.level)
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

function config.on_state_change()
    if can_auto_save() then
        system.backup(STATE_BACKUP_DIR, GetStates(), json.encode)
    end
end

function config.initialize()
    system.init(STATE_BACKUP_DIR, BIN_DIR)
end

return config
