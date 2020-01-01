local name = "luacheck"
local log = require("libs.logger").defaultLogger(name, "INFO")
local luacheck = require("luacheck.init")
local json = require("lunajson")
local system = require("libs.system")

local DRIVER_DIR = "resources/data/device_drivers/"

local config = {}
local generic_comm_types = { "HTTP" }

---Recursively find all keys matching key and return the values in a table using the table path as the key
---@param t table to search
---@param key string key to match
---@param path string initial table path using dot notation (usually nil to start)
---@param results table initial results set (usually nil to start)
---@return table result containing the key path to value for matched keys
local function get_keys(t, key, path, results)
    results = results or {}
    path = path or nil

    for k, v in pairs(t) do
        local parent_path = path and string.format("%s.%s", path, k) or k
        if type(t[k]) == "table" then
            results = get_keys(t[k], key, parent_path, results)
        elseif k == key then
            results[parent_path] = v
        end
    end

    return results
end

---Find lua chunks in a driver
---@param driver table that was originally json decoded
---@return table result of dot notated paths to lua code found
local function find_lua_chunks(driver)
    local res = get_keys(driver, "lua_code")

    for k, v in pairs(get_keys(driver, "lua_checksum_code")) do
        res[k] = v
    end

    for k, v in pairs(get_keys(driver, "lua_postprocess_code")) do
        res[k] = v
    end

    return res
end

---Run luacheck on a lua chunk and log errors for any found
---@param label string Driver info, since a driver json can contain many lua chunks
---@param chunk_name string file or chunk name
---@param chunk string lua code to check
local function check(label, chunk_name, chunk)
    local issues = luacheck.check_strings({chunk})

    if issues[1] and (issues.errors > 0 or issues.fatals > 0) then
        for _, issue in ipairs(issues[1]) do
            local msg = luacheck.get_message(issue)
            log:error(
                string.format(
                    "%s [%s]:%i:%i %s %s",
                    label,
                    chunk_name,
                    issue.line,
                    issue.column,
                    msg,
                    issue.name or ""
                )
            )
        end
    end
end

config.initial_states = {}

config.capabilities = {
    ['CUSTOM'] = {
        ['LUA_CHECK'] = {
            generic_comm_types = generic_comm_types,
            state_changes = function()
                local filepaths = system.list_files(DRIVER_DIR)
                for _, filepath in ipairs(filepaths) do
                    log:info("Checking " .. filepath)
                    local driver = system.load(filepath, json.decode) or {}
                    local label = string.format(
                        "%s %s v%s (%s)",
                        driver.device_manufacturer,
                        driver.device_type,
                        driver.version,
                        driver.id
                    )

                    local lua_chunks = find_lua_chunks(driver)
                    for k, v in pairs(lua_chunks) do
                        check(label, k, v)
                    end
                end

                log:info("Done")
                return {}
            end
        }
    }
}

config.macros = {}

function config.initialize()
    -- Do nothing
end

return config
