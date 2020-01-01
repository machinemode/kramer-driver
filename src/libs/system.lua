local log = require("libs.logger").defaultLogger()
local string_utils = require("libs.string_utils")
local system = {}
local silent_redirection = " >/dev/null 2>&1"

local function remove_newlines(handle)
    local str = string.gsub(handle:read("a"), "\n", "")
    return str
end

function system.exec(cmd)
    local _, _, code = os.execute(cmd .. silent_redirection)
    return code == 0
end

function system.mkdir(path)
    return system.exec("mkdir -p " .. path)
end

function system.init(...)
    for _, path in ipairs({...}) do
        if not system.mkdir(path) then
            log:warn("Failed to create " .. path)
        end
    end
end

function system.read(cmd, formatter)
    local handle = io.popen(cmd)
    local res = nil

    if handle then
        res = formatter and formatter(handle) or handle:read("a")
    end
    return res ~= "" and res or nil
end

function system.move(source, destination)
    local success, err = os.rename(source, destination)

    if not success then
        log:warn(
            string.format(
                "Unable to copy %s to %s: %s",
                source,
                destination,
                err
            )
        )
    end

    return success
end

function system.remove(path)
    return system.exec("rm -rf " .. path)
end

function system.copy(source, destination)
    local success = system.exec("cp -rf " .. source .. " " .. destination)

    if not success then
        log:warn(
            string.format(
                "Unable to copy %s to %s",
                source,
                destination
            )
        )
    end

    return success
end

function system.file_exists(filepath)
    return system.exec("test -f " .. filepath)
end

function system.directory_exists(path)
    return system.exec("test -d " .. path)
end

function system.list_files(path)
    local result = system.read("find " .. path .. " -maxdepth 1 -type f") or ""
    local filepaths = {}

    for filepath in string.gmatch(result, "%S+") do
        filepaths[#filepaths + 1] = filepath
    end

    return filepaths
end

function system.sleep(seconds)
    system.exec("sleep " .. tostring(seconds))
end

-- No ps on docker. Need `kill -0 $PID`
function system.is_running(pid)
    return system.exec("kill -0 " .. tostring(pid))
end

function system.try_kill(pid)
    local killed = false

    if not string_utils.is_empty(pid) then
        killed = system.exec("kill " .. pid)
        if not killed then
            log:error("Unable to stop process " .. pid)
        end
    end

    return killed
end

function system.fork(cmd, log_file, keep_alive)
    if not cmd then
        log:warn("Unable to start empty command")
        return nil
    end

    local nohup = keep_alive and "nohup " or ""

    local pid
    if string_utils.is_empty(log_file) then
        pid = system.read(nohup .. cmd .. silent_redirection .. " & printf $!", remove_newlines)
    else
        local file_redirection = " >>" .. log_file .. " 2>&1"
        pid = system.read(nohup .. cmd .. file_redirection .. " & printf $!", remove_newlines)
    end

    if system.is_running(pid) then
        return pid
    else
        log:error("Failed to start " .. cmd)
        return nil
    end
end

function system.get_kernel_name()
    return system.read("uname -s", remove_newlines)
end

function system.get_kernel_release()
    return system.read("uname -r", remove_newlines)
end

function system.get_kernel_version()
    return system.read("uname -v", remove_newlines)
end

function system.get_machine_name()
    return system.read("uname -m", remove_newlines)
end

function system.get_os()
    return system.read("uname -o", remove_newlines)
end

function system.get_hostname()
    return system.read("uname -n", remove_newlines)
end

function system.get_pwd()
    return system.read("pwd", remove_newlines)
end

function system.get_whoami()
    return system.read("whoami", remove_newlines)
end

function system.get_epoch_datetime_ms()
    return tonumber(system.read("date +%s%3N", remove_newlines))
end

function system.backup(path, data, encoder)
    local previous = path .. "previous.json"
    local current = path .. "current.json"
    system.move(current, previous)

    local f, err = io.open(current, "w")
    if not f then
        log:warn("Unable to open file to save current " .. path .. ": " ..  err)
        return false
    end

    if not f:write(encoder(data), '\n') then
        log:warn("Failed to save current " .. path .. ".")
        return false
    end

    return f:close()
end

---Decode/Deserialize data from a file into a table
---@param filepath string file to read
---@param decoder function decoder to process the data for deserialization
---@return nil|table
function system.load(filepath, decoder)
    local f, err = io.open(filepath, "r")
    if not f then
        log:warn("Unable to open file to load " .. filepath .. ": " ..  err)
        return nil
    end

    local content = f:read("a")
    if not content then
        log:warn("Failed to read " .. filepath .. ".")
        return nil
    end

    f:close()
    local success, data = pcall(function() return decoder(content) end)
    return success and data or nil

end

function system.restore(path, decoder)
    local saved_state = system.load(path .. "current.json", decoder)
    if not saved_state then
        saved_state = system.load(path .. "previous.json", decoder) or {}
    end

    return saved_state
end

function system.clear(filepath)
    io.open(filepath, "w"):close()
end

function system.remove_backups(path)
    system.clear(path .. "previous.json")
    system.clear(path .. "current.json")
end

function system.load_saved_state(backup_path)
    local saved_state = system.load(backup_path .. "current.json")
    if not saved_state then
        saved_state = system.load(backup_path .. "previous.json") or {}
    end

    return saved_state
end

return system
