local lu = require("luaunit")
local brain_api = require("libs.brain_api")

TestBrainApi = {}

function TestBrainApi:test_get_never_nil()
    local info = brain_api.get_brain_data()
    lu.assertNotNil(info)
    lu.assertEquals(info.tcp_port, 8000)
    lu.assertEquals(info.udp_port, 54345)

    lu.assertNotNil(brain_api.get_project_data())
    lu.assertNotNil(brain_api.get_space_data())
end
