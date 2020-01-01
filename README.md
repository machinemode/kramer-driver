# Kramer Control Extensions

Source code for the drivers provided on https://machinemode.gitlab.io/kramer-ext/:
* Extras - Extra system utilities that help obtain system information, perform basic functions, and persist arbitrary states
* i18n - Internationalization (i18n) driver that updates translation states when its locale is set
* Luacheck - Driver that runs Luacheck against all Lua chunks found in installed device drivers
* Sidecar - Sidecar driver that enables other processes/applications to run alongside a Brain


## Prerequisites

* [lua 5.3](https://www.lua.org/download.html)
* [luarocks](https://luarocks.org/)
* [npm](https://www.npmjs.com/)


## Development
Initialize the project:
```sh
luarocks --local init --lua-version "5.3" kramer-driver-0.0.1-1.rockspec
```

Install dependencies:
```sh
./luarocks install --deps-only kramer-driver-0.0.1-1.rockspec
./luarocks install https://gitlab.com/machinemode/i18n.lua/-/raw/expose-keys/i18n.lua-dev-1.rockspec
```

Run tests:
```sh
./luarocks test
```

Bundle lua scripts for use as "Category" overrides. Files are placed in `dist/`:
```sh
./bundle.sh
```
