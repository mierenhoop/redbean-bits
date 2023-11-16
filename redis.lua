local redis = {}

redis.ESOCKET = "redis: connection not open"

local find = string.find

--[[
local redis = require"redis"
local conn = assert(redis.open { host = "localhost", port = 6379 } )
]]

local conn = {}
conn.__index = conn

function conn:__index(k)
  local v = rawget(self, k) or rawget(conn, k)
  if v then return v end
  -- TODO: check if command possible?
  -- TODO: make command lower/upper case?
  return function(...)
    -- you can call with `:` or with `.`
    return self:send(k, select(... == self and 2 or 1, ...))
  end
end

function conn:settimeout(rcv, snd)
  assert(self.fd, redis.ESOCKET)
  if rcv then
    assert(unix.setsockopt(self.fd, unix.SOL_SOCKET, unix.SO_RCVTIMEO, rcv))
  end
  if snd then
    assert(unix.setsockopt(self.fd, unix.SOL_SOCKET, unix.SO_SNDTIMEO, snd))
  end
end


function conn:__close()
  if self.fd then
    assert(unix.close(self.fd))
    self.fd = nil
  end
end

conn.__gc = conn.__close

local function parse_line(fd)
  local code = assert(unix.recv(fd, 1))

  local line, tab
  repeat
    local peek = assert(unix.recv(fd, nil, unix.MSG_PEEK))
    local cr = find(peek, "\r", 1, true)
    local data = assert(unix.recv(fd, cr and (cr-1) or #peek))
    if not line then
      line = data
    elseif tab then
      table.insert(tab, data)
    else
      tab = {data}
    end
  until cr

  assert(unix.recv(fd, 2)) -- CRLF

  return code, tab and table.concat(tab) or line
end

local function parse(fd)
  local code, line = parse_line(fd)

  if code == "+" then
    return line
  elseif code == "-" then
    return false, line
  elseif code == ":" then
    return assert(tonumber(line))
  elseif code == "$" then
    local count = assert(tonumber(line))
    local data = assert(unix.recv(fd, count))
    assert(unix.recv(fd, 2)) -- CRLF
    return data
  elseif code == "*" then
    local count = assert(tonumber(line))
    local arr = {}
    for i = 1, count do
      local ret, err = parse(fd)
      arr[i] = (not err) and ret or {false, err} -- same as lua-resty-redis
    end
    return arr
  end
end

-- will error when protocol not handled as expected
function conn:send(...)
  assert(self.fd, redis.ESOCKET)

  local n = select("#", ...)

  local sent, err = assert(unix.send(self.fd, "*"..n.."\r\n"))
  if err then return nil, err end
  for i = 1, n do
    local cmd = tostring(select(i, ...))
    local tosend = "$"..#cmd.."\r\n"
    assert(unix.send(self.fd, tosend))
    assert(unix.send(self.fd, cmd.."\r\n"))
  end

  return parse(self.fd)
end

function redis.open(opts)
  opts = opts or {}
  local self = setmetatable({}, conn)

  local ip, err = ResolveIp(opts.host or "localhost")
  if not ip then return nil, err end

  self.fd, err = unix.socket()
  if not self.fd then return nil, err end

  local ok, err = unix.setsockopt(self.fd, unix.IPPROTO_TCP, unix.TCP_NODELAY, true)
  if not ok then return nil, err end

  local ok, err = unix.connect(self.fd, ip, opts.port or 6379)
  if not ok then return nil, err end

  return ok and self, err
end

return redis
