local gwsocket = {}

gwsocket.__index = gwsocket

function gwsocket:close()
  print"close"
  if self.pid and self.ppid == unix.getpid() then
    print"closing pid"
    assert(unix.kill(self.pid, unix.SIGINT))
    self.pid = nil
  end
end

gwsocket.__close, gwsocket.__gc = gwsocket.close, gwsocket.close

function gwsocket:send(data, client, typ)
  local path = self and self.pipein or "/tmp/wspipein.fifo"
  local pipein, err = unix.open(path, unix.O_WRONLY)
  if err then return nil, err end

  if self.strict then
    assert(client)
    local header = string.pack(">III", client, typ or 2, #data) -- default to binary
    data = header .. data
  end

  local sent, err = unix.write(pipein, data)
  unix.close(pipein)
  return sent, err
end

-- todo: make callback
function gwsocket:poller()
  local path = self and self.pipeout or "/tmp/wspipeout.fifo"
  local pipeout = assert(unix.open(path, unix.O_RDONLY | unix.O_NONBLOCK))

  local pollfds = { [pipeout] = unix.POLLIN }

  local function closer()
    assert(unix.close(pipeout))
  end

  return function()
    print("polling")
    -- TODO: timeout?
    print("poll", EncodeLua{unix.poll(pollfds)})

    local client, typ

    if self.strict then
      local header, err = unix.read(pipeout, 12)
      print("header", #header, header)
      local len
      client, typ, len = header:unpack(">III")

      local data, err = unix.read(pipeout, len)
      print("data", #data, data)
    end

    local data, err = unix.read(pipeout)
    return data ~= "" and data, client, typ
  end, nil, nil, setmetatable({}, { __close = closer })
end

function gwsocket.open(opts)
  local path = opts.path or unix.commandv("gwsocket") or "./gwsocket"

  local self = setmetatable({}, gwsocket)

  self.strict = opts.strict ~= false

  local args = { path, self.strict and "--strict" }

  local pid = assert(unix.fork())
  if pid == 0 then
    -- close stdout
    unix.close(1)
    assert(unix.execve(path, args))
    unix.exit(127)
  end

  self.ppid = unix.getpid()
  self.pid = pid
  print("ppid", self.ppid, "pid", pid)

  return self
end

return gwsocket
