local lu = require("luaunit")
local system = require("libs.system")
local fun = require("libs.functional")
local json = require("lunajson")

TestSystem = {}

local BASE_DIR = "resources/data/test/"
local STATE_DIR = BASE_DIR .. "state/"
local BIN_DIR = BASE_DIR .. "bin/"
local UPLOAD_DIR = "resources/www/bundle/"

function TestSystem:setUp()
    print(BASE_DIR)
    system.init(BASE_DIR, STATE_DIR, BIN_DIR, UPLOAD_DIR)

    system.exec("cp tests/sidecar.sh " .. UPLOAD_DIR)
    system.exec("cp -r tests/test_folder " .. UPLOAD_DIR)
    lu.assertTrue(system.exec("ls " .. UPLOAD_DIR .. "sidecar.sh"))
    lu.assertTrue(system.exec("ls " .. UPLOAD_DIR .. "test_folder/test_file"))
end

function TestSystem:tearDown()
    system.exec("rm -rf resources")
end

function TestSystem:init_created_base_dir()
    lu.assertTrue(system.exec("ls " .. BASE_DIR))
end

function TestSystem:test_get_os_values()
    lu.assertNotNil(system.get_kernel_name())
    lu.assertNotNil(system.get_kernel_release())
    lu.assertNotNil(system.get_kernel_version())
    lu.assertEquals("x86_64", system.get_machine_name())
    lu.assertNotNil(system.get_os())
    lu.assertNotNil(system.get_hostname())
    lu.assertNotNil(system.get_pwd())
    lu.assertNotNil(system.get_whoami())
end

function TestSystem:test_save()
    lu.assertTrue(system.backup(STATE_DIR, {}, json.encode))
end

function TestSystem:test_save_and_load()
    lu.assertTrue(system.backup(STATE_DIR, {
        { name = "foo", value = 1 },
        { name = "bar", value = 2 },
        { name = "meh", value = 3 },
    }, json.encode))
    lu.assertItemsEquals(system.load(STATE_DIR .. "current.json", json.decode), {
        { name = "foo", value = 1 },
        { name = "bar", value = 2 },
        { name = "meh", value = 3 },
    })
end

function TestSystem:test_big_save()
    local data = fun.totable(
        fun.map(
            function (x)
                return {
                    category_id = "TEST" .. tostring(x),
                    state_id = "foo"  .. tostring(x),
                    state_key = "A"  .. tostring(x),
                    state_value = x,
                    state_normalized_value = nil
                }
            end,
            fun.range(100000)
        )
    )
    lu.assertTrue(system.backup(STATE_DIR, data, json.encode))
end

function TestSystem:test_clear_backups()
    lu.assertTrue(system.backup(STATE_DIR, {
        { name = "foo", value = 1 },
        { name = "bar", value = 2 },
        { name = "meh", value = 3 },
    }, json.encode))

    lu.assertTrue(system.backup(STATE_DIR, {
        { name = "foo", value = 10 },
        { name = "bar", value = 20 },
        { name = "meh", value = 30 },
    }, json.encode))

   system.remove_backups(STATE_DIR)
   lu.assertNil(system.load(STATE_DIR .. "current.json", json.decode))
   lu.assertNil(system.load(STATE_DIR .. "previous.json", json.decode))
end

function TestSystem:test_move_file()
    lu.assertTrue(system.move(UPLOAD_DIR .. "sidecar.sh", BIN_DIR .. "sidecar.sh"))
    lu.assertFalse(system.file_exists(UPLOAD_DIR .. "sidecar.sh"))
    lu.assertTrue(system.file_exists(BIN_DIR .. "sidecar.sh"))
end

function TestSystem:test_copy_directory()
    lu.assertTrue(system.copy(UPLOAD_DIR .. "test_folder", BIN_DIR))
    lu.assertTrue(system.directory_exists(BIN_DIR .. "test_folder"))
    lu.assertTrue(system.file_exists(BIN_DIR .. "test_folder/test_file"))
    lu.assertTrue(system.directory_exists(UPLOAD_DIR .. "test_folder"))
    lu.assertTrue(system.file_exists(UPLOAD_DIR .. "test_folder/test_file"))
end

function TestSystem:test_copy_file()
    lu.assertTrue(system.copy(UPLOAD_DIR .. "test_folder/test_file", BIN_DIR))
    lu.assertTrue(system.file_exists(BIN_DIR .. "test_file"))
    lu.assertTrue(system.file_exists(UPLOAD_DIR .. "test_folder/test_file"))
end

function TestSystem:test_copy_unknown_directory()
    lu.assertFalse(system.copy(UPLOAD_DIR .. "foo", BIN_DIR))
end

function TestSystem:test_copy_unknown_file()
    lu.assertFalse(system.copy(UPLOAD_DIR .. "foo", BIN_DIR))
end

function TestSystem:test_fork_process()
    lu.assertTrue(system.copy(UPLOAD_DIR .. "sidecar.sh", BIN_DIR .. "sidecar.sh"))
    local pid = system.fork(BIN_DIR .. "sidecar.sh")
    lu.assertTrue(system.is_running(pid))

    lu.assertTrue(system.try_kill(pid))
    lu.assertFalse(system.is_running(pid))
end

function TestSystem:test_fork_process_nohup()
    lu.assertTrue(system.copy(UPLOAD_DIR .. "sidecar.sh", BIN_DIR .. "sidecar.sh"))
    local pid = system.fork(BIN_DIR .. "sidecar.sh", nil, true)
    lu.assertTrue(system.is_running(pid))

    lu.assertTrue(system.try_kill(pid))
    lu.assertFalse(system.is_running(pid))
end

function TestSystem:test_logged_fork_process()
    lu.assertTrue(system.copy(UPLOAD_DIR .. "sidecar.sh", BIN_DIR .. "sidecar.sh"))
    local pid = system.fork(BIN_DIR .. "sidecar.sh", BIN_DIR .. "sidecar.log")
    lu.assertTrue(system.is_running(pid))
    lu.assertTrue(system.file_exists(BIN_DIR .. "sidecar.log"))

    system.sleep(7)
    lu.assertTrue(system.try_kill(pid))
    lu.assertFalse(system.is_running(pid))
    lu.assertTrue(system.file_exists(BIN_DIR .. "sidecar.log"))
end

function TestSystem:test_fork_unknown_process()
    local pid = system.fork(BIN_DIR .. "foo.sh")
    lu.assertNil(pid)
end

function TestSystem:test_kill_unknown_process()
    lu.assertFalse(system.try_kill(nil))
end

function TestSystem:test_find_files()
    local filepaths = system.list_files("tests/device_drivers")
    lu.assertEquals(#filepaths, 12)
end

function TestSystem:test_epoch_datetime_ms()
    local timestamp = system.get_epoch_datetime_ms()
    lu.assertTrue(type(timestamp) == "number")
end
