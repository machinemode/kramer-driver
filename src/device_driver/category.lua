local json = require("lunajson")
local log = require("libs.logger").defaultLogger()
local driver = require("device_driver.driver")

---Called when this device driver is created.
---Used to set up initial values of global variables and other initial tasks.
---@param config table config to inject for testing
function initialize(config)
    if not config then
        config = require("config")
        log = require("libs.logger").defaultLogger()
    end

    config.initialize()
    driver.initialize(config.initial_states, config.capabilities, config.macros, config.on_state_change)
end

---Called to get any additional macros created in lua. This only happens once when the device driver is created.
---@return string macros JSON object containing an array of macros representing any additional macros for this category
function getMacros()
    return json.encode({
        macros = driver.get_macros()
    })
end

---Used to obtain the possible keys for a given state.
---@param state_id string the id of the state for which to query keys
---@return string keys JSON object containing an array of keys representing the keys of the state
function queryAllKeys(state_id)
    return json.encode({
        keys = driver.get_state_keys(state_id)
    })
end

---Used to obtain the value of a specific state at a specific key.
---@param state_id string id of the state to query
---@param state_key string|nil key the state to query (empty if the state is not an array)
---@return string|nil actual the actual value of the state
---@return string|nil normalized the normalized value of the state (on a scale of 0 - 1 for numeric states)
function queryStateValue(state_id, state_key)
    return driver.get_state_value(state_id, state_key)
end

---Take the capability/command ids and arguments for a command and return the code to send to the device.
---@param protocols table array of strings representing the protocols available on which to send this command
---@param capability_id string id of the capability to use for this command
---@param command_id string id of command to use for this command
---@param args table|nil table of argument/value pairs for this command
---@return string genericCommType (TCP_UDP, SERIAL, HTTP, IR) to use to send this command
---@return string codes JSON object containing an array codes representing to send to the device for this command
---@return string state_changes JSON object containing an array of virtual state changes caused by this command
---@return string|nil id of the linked feedback if this command must be linked to a feedback (nil if none)
---@return string macros JSON object representing the macro, if any, to be executed as a result of this feedback
function getExecutionResult(protocols, capability_id, command_id, args)
    local generic_comm_type,
        codes,
        state_changes,
        linked_feedback_id,
        macros = driver.get_execution_result(capability_id, command_id, args, protocols)

    local state_changes = json.encode({ state_changes = state_changes })
    return generic_comm_type,
        json.encode({ codes = codes }),
        state_changes,
        linked_feedback_id,
        json.encode(macros)
end

---Apply a specified state change and return whether or not this change actually changed the state's value.
---@param state_change table a table containing the state change information
---@param virtual boolean a boolean indicating if this is a virtual state change (applied when sending the command) or not (applied when receiving feedback)
---@return boolean changed a boolean indicating if the state's value actually changed as a result of this state change
function applyStateChange(state_change, virtual)
    return virtual and driver.apply_state_change(state_change)
end

---Take a list of feedback messages and determine the state changes that result.
---@param feedbacks table array of strings representing the feedback codes received
---@param protocol string the protocol used to receive this feedback
---@param linked_feedback table information on exactly which feedback id to use to process these messages, along with parameter values from the linked command (contains `category_id`, `capability_id`, `feedback_id`, and all parameter name/value pairs)
---@return string matches JSON object containing an array of booleans indicating which feedback codes matched
---@return string state_changes JSON object containing an array representing the state changes caused by these feedback codes
---@return string|nil macros JSON object representing the macros, if any, to be executed as a result of this feedback
function processFeedback(feedbacks, protocol, linked_feedback)
    local matches = json.encode({ matches = {} })
    local state_changes = json.encode({ state_changes = {} })
    local macros = nil
    return matches, state_changes, macros
end

---Get a copy of the current states. Not invoked by Brain.
---@return table states
function GetStates()
    return driver.get_states()
end
