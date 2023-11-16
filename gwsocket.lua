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

function gwsocket:send(data)
  local path = self and self.pipein or "/tmp/wspipein.fifo"
  local pipein, err = unix.open(path, unix.O_WRONLY)
  if err then return nil, err end
  local sent, err = unix.write(pipein, data)
  unix.close(pipein)
  return sent, err
end

function gwsocket:poller()
  local path = self and self.pipeout or "/tmp/wspipeout.fifo"
  local pipeout = assert(unix.open(path, unix.O_RDONLY | unix.O_NONBLOCK))

  local pollfds = { [pipeout] = unix.POLLIN | unix.POLLPRI|unix.POLLRDHUP|unix.POLLERR|unix.POLLHUP|unix.POLLNVAL}

  local function closer()
    unix.close(pipeout)
  end

  return function()
    print("polling")
    print("poll", EncodeLua{unix.poll(pollfds)})
    local data, err = unix.read(pipeout)
    if data and data ~= "" then
      return data
    end
    assert(unix.close(pipeout))
  end
end

function gwsocket.open(path)
  path = path or unix.commandv("gwsocket") or "./gwsocket"

  local self = setmetatable({}, gwsocket)

  local pid = assert(unix.fork())
  if pid == 0 then
    -- close stdout
    unix.close(1)
    assert(unix.execve(path))
    unix.exit(127)
  end

  self.ppid = unix.getpid()
  self.pid = pid
  print("ppid", self.ppid, "pid", pid)

  return self
end

return gwsocket
