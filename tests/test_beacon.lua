local lu = require("luaunit")
local beacon = require("libs.beacon")

TestBeacon = {}
function TestBeacon:test_build_command()
    lu.assertEquals(
        beacon.build_command("foo", 54345, { foo = "bar" }),
        [[bash -c "echo '{\"foo\":\"bar\"}' > /dev/udp/foo/54345"]]
    )
end

function TestBeacon:test_unicast_does_not_error()
    local status, _ = beacon.unicast("192.168.1.168", 54345, {})
    lu.assertTrue(type(status) == "boolean")
    lu.assertTrue(status)
end

function TestBeacon:test_multicast_does_not_error()
    local status, _ = beacon.multicast(54345, {})
    lu.assertTrue(status)
end

function TestBeacon:test_unicast_brain_identity()
    local status, _ = beacon.unicast("192.168.1.164", 54345, {
        beacon_type = "brain_identify",
        brain_version = "2.10.10-prod",
        port = 8000,
        space_id = "80fe4983-591d-4166-9ccc-3fdcadfec0bd"
    })
    lu.assertTrue(status)
end

function TestBeacon:test_unicast_brain_identity_via_hostname()
    local status, _ = beacon.unicast("arch0", 54345, {
        beacon_type = "brain_identify",
        brain_version = "2.10.10-prod",
        port = 8000,
        space_id = "80fe4983-591d-4166-9ccc-3fdcadfec0bd"
    })
    lu.assertTrue(status)
end

function TestBeacon:test_multicast_brain_identity()
    local status, _ = beacon.multicast(54345, {
        beacon_type = "brain_identify",
        brain_version = "2.10.10-prod",
        port = 8000,
        space_id = "80fe4983-591d-4166-9ccc-3fdcadfec0bd"
    })
    lu.assertTrue(status)
end
