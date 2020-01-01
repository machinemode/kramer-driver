local system = require("libs.system")

local sidecar = {}

function sidecar.restart(bin, current_pid, log_file, keep_alive)
    system.try_kill(current_pid)
    return system.fork(bin, log_file, keep_alive)
end

function sidecar.stop(pid)
    return system.try_kill(pid)
end

function sidecar.is_running(pid)
    return system.is_running(pid)
end

return sidecar
