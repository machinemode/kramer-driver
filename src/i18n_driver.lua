local name = "i18n"
local log = require("libs.logger").defaultLogger(name, "INFO")
local common = require("common")

local fun = require("libs.functional")
local json = require("lunajson")
local i18n = require("i18n.init")

local state = require("device_driver.state")

local brain_api = require("libs.brain_api")
local system = require("libs.system")

local STATE_BACKUP_DIR = string.format("resources/data/%s/state/", name)

local config = {}
local category_state = state.init("CONFIGURATION")
local generic_comm_types = { "HTTP" }

local function hyphenate_subtags(value)
    local subtag = string.gsub(value, "_", "-")
    return subtag
end

local function get_translations()
    return fun.map(
        function(key)
            return category_state("I18N", key)(i18n.translate(key))
        end,
        i18n.getKeys()
    )
end

local function load_translation(locale, data)
    local data = string.format([[ { "%s": %s } ]], locale, data)
    local success, translation_result = pcall(function() return json.decode(data) end)

    if not success then
        log:error(string.format("Failed to set translation for %s due to invalid json", locale))
    else
        i18n.load(translation_result)
    end

    return success
end

config.initial_states = {}

config.capabilities = {
    ['SYSTEM'] = common.common_commands(generic_comm_types, STATE_BACKUP_DIR, category_state, log),
    ['SYSTEM_MODE'] = {
        ['SET_LOCALE'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                i18n.setLocale(hyphenate_subtags(args['LOCALE']))

                return fun.chain(
                    get_translations(),
                    { category_state("LOCALE")(i18n.getLocale()) }
                )
            end
        },
        ['SET_TRANSLATION'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                local locale = hyphenate_subtags(args['LOCALE'])
                local current_locale = state.find_first(GetStates(), "LOCALE") or {}
                local loaded = load_translation(locale, args['JSON'])

                if loaded and locale == current_locale.state_value then
                    return get_translations()
                else
                    return {}
                end
            end
        },
        ['PLURALIZE'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function(args)
                local key = args['KEY']
                local count = args['COUNT']
                -- WIP: Not sure how this fits in Kramer Control
                return {
                    category_state(
                        "I18N",
                        string.format(
                            "%s_%s",
                            key,
                            tostring(count)
                        )
                    )(i18n.translate(key, { count = count }))
                }
            end
        }
    }
}

-- Override INITIALIZE from common
config.capabilities['SYSTEM']['INITIALIZE'] = {
    generic_comm_types = generic_comm_types,
    state_changes = function()
        local project = brain_api.get_project_data()
        local previous_states = system.restore(STATE_BACKUP_DIR, json.decode)
        local locale_state = state.find_first(previous_states, "LOCALE")

        if locale_state and locale_state.state_value then
            i18n.setLocale(locale_state.state_value)
        else
            i18n.setLocale(hyphenate_subtags(project.locale or "en_US"))
        end

        local default_states = {
            category_state("LOG_LEVEL")(log.level),
            category_state("LOCALE")(i18n.getLocale())
        }

        return state.merge(default_states, previous_states)
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
    system.init(STATE_BACKUP_DIR)
end

return config
