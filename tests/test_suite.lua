require("../set_paths")
local lu = require("luaunit")
require("libs.logger").defaultLogger("Test", "DEBUG")

require("tests.test_functional")

require("tests.test_driver")
require("tests.test_state")
require("tests.test_comm_types")
require("tests.test_command")

require("tests.test_beacon")
require("tests.test_brain_api")
require("tests.test_system")
require("tests.test_string_utils")
require("tests.test_time_utils")

require("tests.test_category")
require("tests.test_extras_driver")
require("tests.test_i18n_driver")
require("tests.test_sidecar_driver")
require("tests.test_luacheck_driver")

os.exit(lu.LuaUnit.run())
