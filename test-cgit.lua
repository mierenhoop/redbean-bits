-- run with `redbean -F test-cgit.lua`
package.path="./?.lua"

local cgit = require"cgit"

-- for cgit.css and cgit.png
ProgramDirectory("/usr/share/cgit")

function OnHttpRequest()
  if GetPath():match"^/git/" then
    cgit("/usr/lib/cgit/cgit.cgi", GetPath():match("^/git(/.*)$"), GetParams())
  else
    Route()
  end
end
