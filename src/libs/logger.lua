local ll = require("logging")
require("logging.console")

local logger = {}

function logger.defaultLogger(name, level)
    if name ~= nil then
        ll.defaultLogger(ll.console {
            logLevel = level,
            destination = "stderr",
            timestampPattern = "!%Y-%m-%dT%H:%M:%S.%qZ",
            logPattern = "%date %level [" .. name .. "]: %message\n"
        })
    end

    return ll.defaultLogger()
end

return logger
