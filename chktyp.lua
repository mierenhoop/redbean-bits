local function check(c, v)
  -- support Lua <5.3
  local mathtype = math.type or function(n)
    if type(n) ~= "number" then return type(n) end
    return tostring(n):match"^%-?%d+$" and "integer" or "float"
  end
  local t = {
    s = {type, "string"},
    b = {type, "boolean"},
    n = {type, "number"},
    i = {mathtype, "integer"},
    t = {type, "table"},
    f = {type, "function"},
  }
  assert(t[c], "type specifier '" .. c .. "' unknown")
  return t[c][1](v) == t[c][2]
end

---@param types string
local function chktyp(types, ...)
  assert(type(types) == "string")
  local j = 1
  local c
  local function nextprint()
    repeat
      c = types:sub(j,j)
      j = j + 1
    until c ~= " "
  end
  nextprint()
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    local ok = check(c, v)
    nextprint()
    while c == "|" do
      nextprint()
      ok = ok or check(c, v)
      nextprint()
    end
    if c == "?" then
      ok = ok or (v == nil)
      nextprint()
    end
    assert(ok, "type mismatch")
  end
  assert(j == #types + 2, "not enough arguments provided based on types string")
end

return chktyp
