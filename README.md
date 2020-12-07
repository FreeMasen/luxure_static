# Luxure Static File Middleware

Luxure Static File Middleware is a middleware package
for sending static files from your Luxure web server

## Usage

### Installation

```sh
$ luarocks install luxure_static
```
### Examples

The most basic usage is to `require` this module and call it like a function

```lua
local lux = require 'luxure'
local socket = require 'socket'
local static = require 'luxure-static'

local server = lux.Server.new(socket)
server:use(static('example_files'))
server:listen(9876)
server:run()
```

For more advanced usages, the module returns a builder that you can use for
configuration.

#### Options

- `send_buffer_size`: This middleware buffers the output of the response body, this will override the default 2048 bytes
- `mime`: A map file extensions to mime types exists for well known mime types, however you may need to add your own mappings
- `mimes`: Same as `mime` but takes a table where the extension is the key and the mime type is the value

```lua
local lux = require 'luxure'
local socket = require 'socket'
local static = require 'luxure-static'

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
```