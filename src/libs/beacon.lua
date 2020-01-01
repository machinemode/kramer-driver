local json = require("lunajson")

local beacon = {}
local multicast_address = '239.249.243.243'

local function to_result(terminated, status, code)
    return (terminated == true), string.format("%s (%i)", string.upper(status), code)
end

function beacon.build_command(address, port, message)
    -- See https://www.gnu.org/software/bash/manual/html_node/Redirections.html
    local escaped_message = string.gsub(json.encode(message), '"', '\\"')
    return string.format(
        [[bash -c "echo '%s' > /dev/udp/%s/%i"]],
        escaped_message,
        address,
        port or 54345
    )
end

function beacon.multicast(port, message)
    local command = beacon.build_command(multicast_address, port, message)
    return to_result(os.execute(command))
end

function beacon.unicast(address, port, message)
    local command = beacon.build_command(address, port, message)
    return to_result(os.execute(command))
end

return beacon
