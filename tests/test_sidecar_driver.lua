local lu = require("luaunit")
local json = require("lunajson")
local state = require("device_driver.state")
local sidecar = require("sidecar_driver")
local system = require("libs.system")
require("device_driver.category")

local UPLOAD_DIR = "resources/www/bundle/"

TestSidecarDriver = {}
function TestSidecarDriver:setUp()
    initialize(sidecar)
    lu.assertTrue(system.exec("mkdir -p " .. UPLOAD_DIR))
    lu.assertTrue(system.copy("tests/sidecar.sh", UPLOAD_DIR))
    lu.assertTrue(system.copy("tests/test_folder", UPLOAD_DIR))
end

function TestSidecarDriver:tearDown()
    system.exec("rm -rf resources")
end

-- getExecutionResult("[\"HTTP\"]", "SYSTEM", "INITIALIZE", "{}")
function TestSidecarDriver:test_initialize_command()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "SYSTEM",
        "INITIALIZE",
        {}
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "LOG_LEVEL"), {
        category_id = "CUSTOM",
        state_id = "LOG_LEVEL",
        state_value = "INFO"
    })

    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end

function TestSidecarDriver:test_initialize_will_stop_all()
    local category_state = state.init("CUSTOM")
    sidecar.initial_states = {
        category_state("PID", "A")(nil),
        category_state("PID", "B")(nil),
        category_state("PID", "C")(nil),
        category_state("PID", "D")(nil)
    }
    initialize(sidecar)

    getExecutionResult(
        { "HTTP" },
        "SYSTEM",
        "SAVE_STATE",
        {}
    )

    local _, _, state_changes = getExecutionResult(
        { "HTTP" },
        "SYSTEM",
        "INITIALIZE",
        {}
    )

    state_changes = json.decode(state_changes).state_changes
    lu.assertItemsEquals(state_changes, {
        category_state("PID")(nil),
        category_state("LOG_FILE_PATH")(nil),
        category_state("PID", "A")(nil),
        category_state("LOG_FILE_PATH", "A")(nil),
        category_state("PID", "B")(nil),
        category_state("LOG_FILE_PATH", "B")(nil),
        category_state("PID", "C")(nil),
        category_state("LOG_FILE_PATH", "C")(nil),
        category_state("PID", "D")(nil),
        category_state("LOG_FILE_PATH", "D")(nil),
        {
            category_id = "CUSTOM",
            state_id = "LOG_LEVEL",
            state_value = "INFO"
        }
    })
end

function TestSidecarDriver:test_load_no_app_only_bin()
    local _, _, state_changes = getExecutionResult(
        { "HTTP" },
        "CUSTOM",
        "LOAD",
        { BINARY_PATH = "sidecar.sh", DIRECTORY_PATH = "", APP = ""}
    )

    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "BINARY_PATH", ""), {
        category_id = "CUSTOM",
        state_id = "BINARY_PATH",
        state_value = "resources/data/sidecar/bin/sidecar.sh"
    })
end

function TestSidecarDriver:test_load_only_bin()
    local _, _, state_changes = getExecutionResult(
        { "HTTP" },
        "CUSTOM",
        "LOAD",
        { BINARY_PATH = "sidecar.sh", DIRECTORY_PATH = "", APP = "app"}
    )

    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "BINARY_PATH", "app"), {
        category_id = "CUSTOM",
        state_id = "BINARY_PATH",
        state_key = "app",
        state_value = "resources/data/sidecar/bin/app/sidecar.sh"
    })
end

function TestSidecarDriver:test_load()
    local _, _, state_changes = getExecutionResult(
        { "HTTP" },
        "CUSTOM",
        "LOAD",
        { BINARY_PATH = "test_file", DIRECTORY_PATH = "test_folder", APP = "app" }
    )

    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "BINARY_PATH", "app"), {
        category_id = "CUSTOM",
        state_id = "BINARY_PATH",
        state_key = "app",
        state_value = "resources/data/sidecar/bin/app/test_folder/test_file"
    })
end

function TestSidecarDriver:test_load_no_app()
    local _, _, state_changes = getExecutionResult(
        { "HTTP" },
        "CUSTOM",
        "LOAD",
        { BINARY_PATH = "test_file", DIRECTORY_PATH = "test_folder", APP = "" }
    )

    state_changes = json.decode(state_changes).state_changes

    lu.assertItemsEquals(state.find_first(state_changes, "BINARY_PATH", ""), {
        category_id = "CUSTOM",
        state_id = "BINARY_PATH",
        state_value = "resources/data/sidecar/bin/test_folder/test_file"
    })
end

function TestSidecarDriver:test_load_nothing()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "CUSTOM",
        "LOAD",
        { BINARY_PATH = "", DIRECTORY_PATH = "" }
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    state_changes = json.decode(state_changes).state_changes

    lu.assertNil(state.find_first(state_changes, "BINARY_PATH"))

    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end

function TestSidecarDriver:test_load_invalid_bin()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "CUSTOM",
        "LOAD",
        { BINARY_PATH = "foo", DIRECTORY_PATH = "" }
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    state_changes = json.decode(state_changes).state_changes

    lu.assertNil(state.find_first(state_changes, "BINARY_PATH"))

    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end

function TestSidecarDriver:test_load_invalid_directory()
    local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
        { "HTTP" },
        "CUSTOM",
        "LOAD",
        { BINARY_PATH = "foo", DIRECTORY_PATH = "bar" }
    )

    lu.assertEquals("HTTP", comm_type)
    lu.assertEquals(codes, [[{"codes":[]}]])
    state_changes = json.decode(state_changes).state_changes

    lu.assertNil(state.find_first(state_changes, "BINARY_PATH"))

    lu.assertNil(linked_feedback_id)
    lu.assertEquals(macros, "[]")
end

-- function TestSidecarDriver:test_start_bin()
--     local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
--         { "HTTP" },
--         "CUSTOM",
--         "LOAD",
--         { BINARY_PATH = "sidecar.sh", DIRECTORY_PATH = "" }
--     )

--     state_changes = json.decode(state_changes).state_changes

--     lu.assertItemsEquals(state.find_first(state_changes, "BINARY_PATH"), {
--         category_id = "CUSTOM",
--         state_id = "BINARY_PATH",
--         state_value = "resources/data/sidecar/bin/sidecar.sh"
--     })

--     local comm_type, codes, state_changes, linked_feedback_id, macros = getExecutionResult(
--         { "HTTP" },
--         "CUSTOM",
--         "START"
--     )

--     state_changes = json.decode(state_changes).state_changes

--     lu.assertNotNil(state.find_first(state_changes, "PID"))
-- end
