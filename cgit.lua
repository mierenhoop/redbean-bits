local function readall(fd)
  local alldata = {}
  while true do
    local data, err = unix.read(fd)
    if data then
      if data == "" then break end
      table.insert(alldata, data)
    elseif err:errno() ~= EINTR then
      Log(kLogWarn, tostring(err))
      break
    end
  end
  assert(unix.close(fd))
  return table.concat(alldata)
end

return function(prog, path, params)
  local env = {
    "SERVER_PORT="..select(2, GetServerAddr()),
    "REQUEST_METHOD="..GetMethod(),
    "QUERY_STRING="..EncodeUrl({params = params}):sub(2),
    "PATH_INFO="..path,
  }
  local reader, writer = assert(unix.pipe())
  if assert(unix.fork()) == 0 then
    assert(unix.close(1))
    assert(unix.dup(writer))
    assert(unix.close(writer))
    assert(unix.close(reader))
    assert(unix.execve(prog, {prog}, env))
    assert(unix.exit(127))
  end
  assert(unix.close(writer))
  local data = readall(reader)
  assert(unix.wait())

  local t = {}
  local headers, body = data:match("(.-\n)\n(.*)$")
  for k, v in headers:gmatch"(.-): (.-)\n" do
    if k == "Status" then
      local code, reason = v:match"^(%d+) (.+)$"
      if code and reason then
        SetStatus(tonumber(code), reason)
      end
    else
      SetHeader(k, v)
    end
  end
  Write(body)
end
