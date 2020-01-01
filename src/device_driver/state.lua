local state = {}
local fun = require("libs.functional")

local bool_value = {
    ['ON'] = true,
    ['OFF'] = false,
    ['true'] = true,
    ['false'] = false,
    [''] = false
}

function state.to_boolean(value)
    return bool_value[value]
end

local function sanitize_key(state_key)
    return state_key ~= "" and state_key or nil
end

function state.init(category_id)
    return function(state_id, state_key)
        return function(state_value, state_normalized_value)
            -- All values must be strings when returning to Brain
            -- Brain sends "" for emtpy/nil values
            return {
                category_id = category_id,
                state_id = state_id,
                state_key = state_key,
                state_value = state_value,
                state_normalized_value = state_normalized_value
            }
        end
    end
end

function state.keys(states, state_id)
    return fun.totable(
        fun.map(
            function(s) return s.state_key end,
            fun.filter(
                function(s) return s.state_id == state_id end,
                states
            )
        )
    )
end

local function has_key(state_change, state_id, state_key)
    -- TODO: Do we care about category_id?
    return state_change.state_id == state_id and state_change.state_key == sanitize_key(state_key)
end

local function find(states, state_id, state_key)
    return fun.filter(
        function(s) return has_key(s, state_id, sanitize_key(state_key)) end,
        states
    )
end

function state.find_all(states, state_id)
    return fun.totable(
            fun.filter(
            function(s) return s.state_id == state_id end,
            states
        )
    )
end

function state.find_first(states, state_id, state_key)
    return fun.first(find(states, state_id, sanitize_key(state_key)))
end

function state.copy(state_change)
    -- Brain sends "" for emtpy/nil values
    return state_change and {
        category_id = state_change.category_id,
        state_id = state_change.state_id,
        state_key = sanitize_key(state_change.state_key),
        state_value = state_change.state_value,
        state_normalized_value = state_change.state_normalized_value ~= "" and state_change.state_normalized_value or nil
    } or {}
end

function state.insert(states, state_change)
    return fun.totable(
            fun.chain(
            states,
            { state_change }
        )
    )
end

function state.update(states, state_change)
    return fun.totable(
            fun.withShallowCopy(
            function(s)
                return has_key(s, state_change.state_id, state_change.state_key)
                    and state_change
                    or s
                end,
                states
            )
        )
end

function state.merge(states, updated)
    return fun.totable(
        fun.chain(
            fun.filter(
                function(s)
                    return not state.find_first(updated, s.state_id, s.state_key)
                end,
                states
            ),
            updated
        )
    )
end

function state.equals(s1, s2)
    return  s1 ~= nil and s2 ~= nil
        and s1.category_id == s2.category_id
        and s1.state_id == s2.state_id
        and s1.state_key == s2.state_key
        and s1.state_value == s2.state_value
        and s1.state_normalized_value == s2.state_normalized_value
end

function state.get_value(states, state_id, state_key)
    return (state.find_first(states, state_id, state_key) or {}).state_value
end

return state
