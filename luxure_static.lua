local Error = require 'luxure.error'.Error
local ltn12 = require("ltn12")
---@class StaticFile
---The static file middleware for Luxure
local StaticFile = {}
StaticFile.__index = StaticFile

---@class File
---@field ext string The file extension for this file
---@field path string The resolved file path used
---@field fd file* The file descriptor for this file
---@field size number The number of bytes in this file
local File = {}
File.__index = File

--- Constructor for a File
---@param path string
---@return File
function File.new(path)
    local filename = string.match(path, '[^/]+$')
    local ext
    -- no filename means this path ends in a slash
    if not filename then
        ext = 'html'
        path = path .. 'index.html'
    else
        ext = string.match(filename, '[^.]+$')
    end
    local fd, err = io.open(path)

    if not fd and ext == filename then
        fd = io.open(path .. '.html')
        if not fd then
            io.open(path .. '/index.html')
        end
        if fd then
            ext = 'html'
        end
    end
    if not fd then
        return nil, err
    end
    local size = fd:seek('end')
    fd:seek('set')
    local ret = {
        fd = fd,
        ext = ext,
        path = path,
        size = size,
    }
    setmetatable(ret, File)
    return ret
end

StaticFile.__call = function(self, dir)
    return self:build(dir)
end

---Generrates a ltn12.sink for sending data across
---a Response
---@param res Response
local function response_sink(res)
    return function(chunk, err)
        Error.assert(not err, err)
        if not chunk then
            res:send()
        else
            res:append_body(chunk)
        end
        return 1
    end
end

--- The primary action of this middleware, it will lookup the file associated
--- with the request and sends it out via the Response
---@param req Request
---@param res Response
function StaticFile:send_file(req, res)
    res:set_send_buffer_size(self._send_buffer_size)
    local f = self:find_file(req)
    res:content_length(f.size)
    -- set the mime type based on the file extension
    local mime = self._content_types[f.ext]
        or 'application/octet-stream'
    res:content_type(mime)
    -- perform a buffered read of the file
    -- calling res:append_bod on each chunk
    ltn12.pump.all(
        ltn12.source.file(f.fd),
        res:sink()
    )
end

--- Find a the file on disk for a request
---@param req Request
---@return File
function StaticFile:find_file(req)
    local resolved = self._dir
    if string.sub(req.url.path, 1, 1) ~= '/' then
        resolved = resolved .. '/' .. req.url.path
    else
        resolved = resolved .. req.url.path
    end
    local f, _e = File.new(resolved)
    if not f then print('No file', _e) end
    Error.assert(f, 'File not found', 404)
    return f, resolved
end

--- Set the base directory for looking for files
---@param path string
---@return StaticFile
function StaticFile:dir(path)
    if string.sub(path, -1) == '/' then
        path = string.sub(path, 1, -2)
    end
    self._dir = path
    return self
end

--- Set the send buffer size
---@param size number
---@return StaticFile
function StaticFile:send_buffer_size(size)
    self._send_buffer_size = size
    return self
end

---Override a single mime type file extension mapping
---@param ext string The file extension, excluding the leading .
---@param mime string The mime type to assocated with the file extension
---@return StaticFile
function StaticFile:mime(ext, mime)
    self._content_types[ext] = mime
    return self
end

---Override a list of mime type file extension mappings
---@param t table table of pairs
---@return StaticFile
function StaticFile:mimes(t)
    for ext, mime in pairs(t) do
        self:mime(ext, mime)
    end
    return self
end

--- Finalize the configuration of this middleware
--- returning the middleware function
---@return fun(req:Request,res:Response)
function StaticFile:build(dir)
    if type(dir) == 'string' then
        self:dir(dir)
    end
    return function(req, res, next)
        next(req, res)
        if not req.handled then
            local err = self:send_file(req, res)
            req.err = err or req.err
            if not req.err then
                req.handled = true
            end
        end
    end
end

--- private initializer
---@return StaticFile
local function init()
    local ret = {
        _dir = '.',
        _send_buffer_size = 1024 * 2,
        _content_types = require 'content_types',
    }
    setmetatable(ret, StaticFile)
    return ret
end

return init()