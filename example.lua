local lux = require 'luxure'
local socket = require 'socket'
local static = require 'luxure_static'

local server = lux.Server.new(socket)
server:use(static
    :send_buffer_size(4096)
    :mime('wasm', 'application/wasm')
    :mimes({
        'lua', 'application/lua',
        'moon', 'application/moonscript',
        'tl', 'application/teal',
    })
    :build('./example_files')
)
server:listen(9876)
server:run()