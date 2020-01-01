rockspec_format = "3.0"
package = "kramer-driver"
version = "0.0.1-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   summary = "Need to figure out how to sync what is manually installed with what is in a rockspec.",
   detailed = [[
Need to figure out how to sync what is manually installed with what is in a rockspec.
]],
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
   "lua >= 5.3",
   "fun >= 0.1",
   "inspect >= 3.1",
   "luacheck >= 1.1.2-1",
   "luaunit >= 3.4",
   "luacc >= 0.9",
   "lunajson >= 1.2",
   "lualogging >= 1.8",
   "penlight >= 1.13.1-1"
}
test = {
   type = "command",
   command = "./lua -l set_paths tests/test_suite.lua -v"
}
