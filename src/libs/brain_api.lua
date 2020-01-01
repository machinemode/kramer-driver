local system = require("libs.system")
local json = require("lunajson")

local brain_api = {}
local WORKING_DIR = "resources/data/"

function brain_api.get_brain_data()
    local brain_settings = system.load(WORKING_DIR .. "settings/brain.settings.json", json.decode) or {}
    local brain =  system.load(WORKING_DIR .. "Brain.json", json.decode) or {}
    brain.tcp_port = brain_settings.brain_tcp_port or 8000
    brain.udp_port = brain_settings.brain_udp_port or 54345
    return brain
end

function brain_api.get_project_data()
    return system.load(WORKING_DIR .. "Project.json", json.decode) or {}
end

function brain_api.get_space_data()
    return system.load(WORKING_DIR .. "Space.json", json.decode) or {}
end

return brain_api
