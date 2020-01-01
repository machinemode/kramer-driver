local fun = require("libs.functional")
local state = require("device_driver.state")
local command = require("device_driver.command")

local driver = {}
local states = {}
local capabilities = {}
local macros = {}
local on_state_change


function driver.initialize(injected_states, injected_capabilities, injected_macros, on_change)
    states = injected_states or {}
    capabilities = injected_capabilities or {}
    macros = injected_macros or {}
    on_state_change = on_change
end

function driver.get_macros()
    return fun.as_array(macros)
end

function driver.get_state_keys(state_id)
    return fun.as_array(
        state.keys(states, state_id)
    )
end

function driver.get_state_value(state_id, state_key)
    local s = state.find_first(states, state_id, state_key) or {}
    return s.state_value, s.state_normalized_value
end

function driver.get_execution_result(capability_id, command_id, args, protocols)
    local cmd = command.find(capabilities, capability_id, command_id)
    if cmd == nil then
        return nil
    end

    local generic_comm_type = command.find_first_comm_type(cmd, protocols)
    local codes = cmd.codes and cmd.codes(args) or {}
    local state_changes = cmd.state_changes and cmd.state_changes(args) or {}

    return generic_comm_type,
        fun.as_array(codes),
        fun.as_array(state_changes),
        cmd.linked_feedback_id,
        fun.as_array(cmd.macros)
end

function driver.apply_state_change(state_change)
    state_change = state.copy(state_change)
    local current = state.find_first(states, state_change.state_id, state_change.state_key)

    if current == nil then
        states = state.insert(states, state_change)
    else
        states = state.update(states, state_change)
    end

    local updated = state.find_first(states, state_change.state_id, state_change.state_key)
    local changed = not state.equals(updated, current)

    if changed and on_state_change then
        on_state_change(current, updated)
    end

    return changed
end

function driver.process_feedback()
    -- TODO
end

-- Used internally, not invoked by Brain
function driver.get_states()
    return fun.totable(fun.map(function(s) return s end, states))
end

return driver
