package.path="./?.lua"

local gwsocket = require"gwsocket"

local conn = gwsocket.open()

if assert(unix.fork()) == 0 then
  Sleep(1)
  print(gwsocket.send(conn, "from fn"))
  print(conn:send("from method"))
  print(gwsocket.send({pipeout="/tmp/pipeout.fifo"}, "from path"))
  unix.exit(0)
else
  Sleep(.5)
  print("poller", unix.getpid())
  for data in conn:poller() do
    print(data)
  end
end
