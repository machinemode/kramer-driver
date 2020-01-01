#!/usr/bin/zsh

mkdir -p dist/extras
cp src/extras_driver.lua src/config.lua
./lua_modules/bin/luacc -o dist/extras/driver.lua -i src -i lua_modules/share/lua/5.3 \
    device_driver.category \
    config common \
    lunajson lunajson.decoder lunajson.encoder lunajson.sax \
    libs.logger logging logging.console \
    device_driver.driver libs.functional fun \
    device_driver.state \
    device_driver.command device_driver.comm_types \
    libs.beacon \
    libs.time_utils \
    libs.system libs.string_utils libs.brain_api

npx --yes luamin -f dist/extras/driver.lua > dist/extras/driver.min.lua
rm src/config.lua

mkdir -p dist/i18n
cp src/i18n_driver.lua src/config.lua
./lua_modules/bin/luacc -o dist/i18n/driver.lua -i src -i lua_modules/share/lua/5.3 \
    device_driver.category \
    config common \
    lunajson lunajson.decoder lunajson.encoder lunajson.sax \
    libs.logger logging logging.console \
    i18n.init i18n.plural i18n.interpolate i18n.variants i18n.version \
    device_driver.driver libs.functional fun \
    device_driver.state \
    device_driver.command device_driver.comm_types \
    libs.system libs.string_utils libs.brain_api

npx --yes luamin -f dist/i18n/driver.lua > dist/i18n/driver.min.lua
rm src/config.lua

mkdir -p dist/sidecar
cp src/sidecar_driver.lua src/config.lua
./lua_modules/bin/luacc -o dist/sidecar/driver.lua -i src -i lua_modules/share/lua/5.3 \
    device_driver.category \
    config common \
    lunajson lunajson.decoder lunajson.encoder lunajson.sax \
    libs.logger logging logging.console \
    device_driver.driver libs.functional fun \
    device_driver.state \
    device_driver.command device_driver.comm_types \
    libs.system libs.string_utils libs.sidecar

npx --yes luamin -f dist/sidecar/driver.lua > dist/sidecar/driver.min.lua
rm src/config.lua

mkdir -p dist/luacheck
cp lua_modules/share/lua/5.3/luacheck/builtin_standards/init.lua lua_modules/share/lua/5.3/luacheck/builtin_standards.lua
cp lua_modules/share/lua/5.3/luacheck/stages/init.lua lua_modules/share/lua/5.3/luacheck/stages.lua
cp lua_modules/share/lua/5.3/luacheck/vendor/sha1/init.lua lua_modules/share/lua/5.3/luacheck/vendor/sha1.lua

cp src/luacheck_driver.lua src/config.lua
./lua_modules/bin/luacc -o dist/luacheck/driver.lua -i src -i lua_modules/share/lua/5.3 \
    device_driver.category \
    config \
    lunajson lunajson.decoder lunajson.encoder lunajson.sax \
    libs.logger logging logging.console \
    luacheck.builtin_standards \
    luacheck.builtin_standards.love \
    luacheck.builtin_standards.ngx \
    luacheck.builtin_standards.playdate \
    luacheck.init \
    luacheck.version \
    luacheck.core_utils \
    luacheck.options \
    luacheck.standards \
    luacheck.check_state \
    luacheck.cache \
    luacheck.expand_rockspec \
    luacheck.stages.linearize \
    luacheck.stages.name_functions \
    luacheck.stages.detect_empty_statements \
    luacheck.stages \
    luacheck.stages.detect_uninit_accesses \
    luacheck.stages.detect_unreachable_code \
    luacheck.stages.parse_inline_options \
    luacheck.stages.detect_unbalanced_assignments \
    luacheck.stages.detect_empty_blocks \
    luacheck.stages.detect_compound_operators \
    luacheck.stages.detect_reversed_fornum_loops \
    luacheck.stages.detect_unused_fields \
    luacheck.stages.unwrap_parens \
    luacheck.stages.detect_bad_whitespace \
    luacheck.stages.detect_globals \
    luacheck.stages.detect_cyclomatic_complexity \
    luacheck.stages.resolve_locals \
    luacheck.stages.detect_unused_locals \
    luacheck.stages.parse \
    luacheck.lexer \
    luacheck.globbing \
    luacheck.serializer \
    luacheck.vendor.sha1 \
    luacheck.vendor.sha1.pure_lua_ops \
    luacheck.vendor.sha1.bit_ops \
    luacheck.vendor.sha1.lua53_ops \
    luacheck.vendor.sha1.bit32_ops \
    luacheck.vendor.sha1.common \
    luacheck.runner \
    luacheck.format \
    luacheck.config \
    luacheck.parser \
    luacheck.unicode_printability_boundaries \
    luacheck.utils \
    luacheck.fs \
    luacheck.decoder \
    luacheck.unicode \
    luacheck.profiler \
    luacheck.check \
    luacheck.filter \
    luacheck.multithreading \
    device_driver.driver libs.functional fun \
    device_driver.state \
    device_driver.command device_driver.comm_types \
    libs.system libs.string_utils

npx --yes luamin -f dist/luacheck/driver.lua > dist/luacheck/driver.min.lua
rm src/config.lua
