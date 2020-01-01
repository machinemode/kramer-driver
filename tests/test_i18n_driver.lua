local lu = require("luaunit")
local json = require("lunajson")
local state = require("device_driver.state")
local i18n = require("src.i18n_driver")
require("device_driver.category")

TestI18NDriver = {}
function TestI18NDriver:setUp()
    initialize(i18n)
end

function TestI18NDriver:test_initialize_command()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "SYSTEM",
        "INITIALIZE",
        {}
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "LOCALE"), {
        category_id = "CONFIGURATION",
        state_id = "LOCALE",
        state_value = "en-US"
    })

    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end

function TestI18NDriver:test_set_locale_command()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "SET_LOCALE",
        { ['LOCALE'] = "en-GB" }
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "LOCALE"), {
        category_id = "CONFIGURATION",
        state_id = "LOCALE",
        state_value = "en-GB"
    })

    -- TODO: Test updated translations

    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end

function TestI18NDriver:test_set_locale_without_hyphen_command()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "SET_LOCALE",
        { ['LOCALE'] = "en_GB" }
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "LOCALE"), {
        category_id = "CONFIGURATION",
        state_id = "LOCALE",
        state_value = "en-GB"
    })
end

local function set_locale(locale)
    local _, _, state_changes = getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "SET_LOCALE",
        { ['LOCALE'] = locale }
    )
    state_changes = json.decode(state_changes).state_changes

    local locale_state = state.find_first(state_changes, "LOCALE")
    lu.assertTrue(applyStateChange(locale_state, true))
    lu.assertItemsEquals(state.find_first(GetStates(), "LOCALE"), locale_state)
end

function TestI18NDriver:test_set_translation_command()
    set_locale("en_US")

    local translation_json = [[ {
        "hello": "hi",
        "home_page": {
            "side_bar": {
                "title": "foo",
                "sub_title": "bar"
            }
        },
        "age": {
            "one": "You are one",
            "other": "You are meh"
        }
    } ]]

    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "SET_TRANSLATION",
        { ['LOCALE'] = "en_US", ['JSON'] = translation_json }
    )

    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "I18N", "hello"), {
        category_id = "CONFIGURATION",
        state_id = "I18N",
        state_key = "hello",
        state_value = "hi"
    })

    lu.assertItemsEquals(state.find_first(state_changes, "I18N", "home_page.side_bar.title"), {
        category_id = "CONFIGURATION",
        state_id = "I18N",
        state_key = "home_page.side_bar.title",
        state_value = "foo"
    })
end

function TestI18NDriver:test_set_invalid_translation()
    set_locale("en_US")

    local translation_json = [[ {
        "hello": "hi",
        "home_page": [}
    } ]]

    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "SET_TRANSLATION",
        { ['LOCALE'] = "en_US", ['JSON'] = translation_json }
    )

    lu.assertEquals(state_changes, '{"state_changes":[]}')
end

function TestI18NDriver:test_set_fallback_translations()
    set_locale("en_US")

    getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "SET_TRANSLATION",
        { ['LOCALE'] = "en_US", ['JSON'] = [[ {
                "cat": "cat",
                "dog": "dog",
                "foo": "bar"
            } ]]
        }
    )

    getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "SET_TRANSLATION",
        { ['LOCALE'] = "es_MX", ['JSON'] = [[ {
                "cat": "gato"
            } ]]
        }
    )

    local _, _, state_changes = getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "SET_LOCALE",
        { ['LOCALE'] = "es_MX" }
    )
    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "I18N", "cat"), {
        category_id = "CONFIGURATION",
        state_id = "I18N",
        state_key = "cat",
        state_value = "gato"
    })

    lu.assertItemsEquals(state.find_first(state_changes, "I18N", "dog"), {
        category_id = "CONFIGURATION",
        state_id = "I18N",
        state_key = "dog",
        state_value = "dog"
    })

    lu.assertNil(state.find_first(state_changes, "I18N", "monkey"))
end


function TestI18NDriver:test_plurize_translations()
    set_locale("en_US")

    getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "SET_TRANSLATION",
        { ['LOCALE'] = "en_US", ['JSON'] = [[ {
                "cat": {
                    "one": "one cat",
                    "other": "%{count} cats"
                }
            } ]]
        }
    )

    local _, _, state_changes = getExecutionResult(
        { "HTTP" },
        "SYSTEM_MODE",
        "PLURALIZE",
        { ['KEY'] = "cat", ['COUNT'] = 300 }
    )
    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "I18N", "cat_300"), {
        category_id = "CONFIGURATION",
        state_id = "I18N",
        state_key = "cat_300",
        state_value = "300 cats"
    })
end
