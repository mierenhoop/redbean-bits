package.path="./?.lua"

local gwsocket = require"gwsocket"

local conn = gwsocket.open { strict = true }

Sleep(.5)
while true do
  for data in conn:poller() do
    print(data)
    --print(gwsocket.send(conn, "from fn"))
    --print(conn:send("from method"))
    --print(gwsocket.send({pipeout="/tmp/pipeout.fifo"}, "from path"))
  end
end
