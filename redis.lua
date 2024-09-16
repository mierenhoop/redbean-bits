return function(opts)
  opts = opts or {}
  local ESOCKET = "redis: connection not open"
  local ip, err = ResolveIp(opts.host or "localhost")
  if not ip then return nil, err end
  local fd, err = unix.socket()
  if not fd then return nil, err end
  local ok, err = unix.setsockopt(fd, unix.IPPROTO_TCP, unix.TCP_NODELAY, true)
  if not ok then return nil, err end
  local ok, err = unix.connect(fd, ip, opts.port or 6379)
  if not ok then return nil, err end
  local function parseline()
    local code = assert(unix.recv(fd, 1))
    local line, tab
    repeat
      local peek = assert(unix.recv(fd, nil, unix.MSG_PEEK))
      local cr = peek:find("\r", 1, true)
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
    local code, line = parseline(fd)
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
  local function send(...)
    assert(fd, ESOCKET)
    local n = select("#", ...)
    local sent, err = assert(unix.send(fd, "*"..n.."\r\n"))
    if err then return nil, err end
    for i = 1, n do
      local cmd = tostring(select(i, ...))
      local tosend = "$"..#cmd.."\r\n"
      assert(unix.send(fd, tosend))
      assert(unix.send(fd, cmd.."\r\n"))
    end
    return parse(fd)
  end
  return setmetatable({
    ESOCKET = ESOCKET,
    settimeout = function(rcv, snd)
      assert(fd, ESOCKET)
      if rcv then
        assert(unix.setsockopt(fd, unix.SOL_SOCKET, unix.SO_RCVTIMEO, rcv))
      end
      if snd then
        assert(unix.setsockopt(fd, unix.SOL_SOCKET, unix.SO_SNDTIMEO, snd))
      end
    end,
  }, {
    __index = function(_, k)
      return function(...)
        return send(k, ...)
      end
    end,
    __close = function()
      if fd then assert(unix.close(fd)) fd = nil end
    end,
  })
end
