package.path="./?.lua"

local htmlgen = require"htmlgen"

local buf = {}
local function appendbuf(s) buf[#buf+1] = s end
do
  local h = htmlgen(appendbuf)
  h:doc()

  local _ <close> = h{"html", "lang","en"}

  do
    local _ <close> = h{"div", {class="main"}, {id="main"}}
    h{"div",class="section"}
    h:text"input number: "
    h{"input",type="number"}
    h"/div"
  end
end

assert(table.concat(buf) == [[<!DOCTYPE html><html lang="en"><div class="main" id="main"><div class="section">input number: <input type="number"></div></div></html>]], "test 1 failed")
print("test 1 passed")

buf = {}
do
  local h = htmlgen(appendbuf)

  local root = h{"main", "class", "center", id="main"}

  local div = h{"div", onclick=[[alert("&><\"'")]]}
  h:text("escape me %s", "<")
  div:close()
  h"br"
  h:raw"don't <strong>escape</strong> me"
  root:close()
end

assert(table.concat(buf) == [[<main class="center" id="main"><div onclick="alert(&quot;&amp;&gt;&lt;\&quot;&#39;&quot;)">escape me &lt;</div><br>don't <strong>escape</strong> me</main>]], "test 2 failed")
print"text 2 passed"
