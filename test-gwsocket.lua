package.path="./?.lua"

local gwsocket = require"gwsocket"

local conn <close> = gwsocket.open { strict = true }

print([[
open your browser's console and paste the following:
var ws = new WebSocket("ws://]] .. assert(unix.gethostname()) .. [[:7890");
ws.onmessage = (ev) => console.log("received: '"+ev.data+"'");
ws.onopen = () => ws.send("test");]])
conn:listen(function(data, fd, typ)
  if typ == 16 then return end
  if typ == 1 and data == "test" then
    print"test 1 passed"

    conn:send(data, fd, 1)

    print"did you get back the text 'test'? (y/n)"
    if io.read(1):lower() == "y" then
      print"test 2 passed"
    else
      print"test 2 failed"
    end
  else
    print"test 1 failed"
  end
  return true
end)
