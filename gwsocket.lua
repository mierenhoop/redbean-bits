local gwsocket = {}

gwsocket.__index = gwsocket

local function execpipe(cmd)
  local fdor, fdow = assert(unix.pipe())
  local fdir, fdiw = assert(unix.pipe())
  local out
  local pid = assert(unix.fork())
  if pid == 0 then
    assert(unix.close(fdiw))
    assert(unix.dup(fdir, 0))
    assert(unix.close(fdir))
    assert(unix.close(fdor))
    assert(unix.dup(fdow, 1))
    assert(unix.close(fdow))

    assert(unix.close(2)) -- stderr
    assert(unix.execve(cmd[1], cmd))
    assert(unix.exit(127))
  end
  assert(unix.close(fdow))
  assert(unix.close(fdir))

  return pid, fdiw, fdor
end

function gwsocket:listen(fn)
  local pollfds = { [self.reader] = unix.POLLIN }

  local _ <close> = setmetatable({}, { __close = function()
    if self.reader then assert(unix.close(self.reader)) self.reader = nil end
  end})

  while true do
    -- TODO: timeout?
    assert(unix.poll(pollfds))

    local client, typ
    local len = unix.PIPE_BUF

    if self.strict then
      local header = assert(unix.read(self.reader, 12))
      if header and header ~= "" then
        client, typ, len = string.unpack(">III", header)
      end
    end

    local data = assert(unix.read(self.reader, len))
    if data ~= "" then
      if fn(data, client, typ) then break end
    end
  end
end

function gwsocket:close()
  if self.writer then assert(unix.close(self.writer)) self.writer = nil end
  if self.reader then assert(unix.close(self.reader)) self.reader = nil end
  if self.pid and self.ppid == unix.getpid() then
    assert(unix.kill(self.pid, unix.SIGINT))
    self.pid = nil
  end
end

gwsocket.__close = gwsocket.close

function gwsocket:send(data, client, typ)
  if self.strict then
    assert(client)
    local header = string.pack(">III", client, typ or 2, #data) -- default to binary
    data = header .. data
  end

  assert(assert(unix.write(self.writer, data)) == #data)
end

function gwsocket.open(opts)
  local path = opts.path or unix.commandv("gwsocket") or "./gwsocket"

  local self = setmetatable({}, gwsocket)

  self.strict = opts.strict ~= false

  local args = { path, "--std", self.strict and "--strict" or nil }

  self.pid, self.writer, self.reader = execpipe(args)

  self.ppid = assert(unix.getpid())

  return self
end

return gwsocket
