local chktyp = require"chktyp"

local function experr(fun, ...)
  local ok, err = pcall(fun, ...)
  if ok then
    error("error '" .. tostring(err) .. "'")
  end
end

chktyp("s", "test")
experr(chktyp, "s", {})
experr(chktyp, "s", nil)
chktyp("sn", "test", 10)
chktyp("s n", "test", 10)
experr(chktyp, "s n", "test", "test")
experr(chktyp, "s n", "test", 10, "test")
experr(chktyp, "s n", "test", 10, nil)
experr(chktyp, "s n", "test")
chktyp("i", 10)
experr(chktyp, "i", 10.1)
chktyp("i?", 10)
chktyp("i?", nil)
experr(chktyp, "i?", 10.1)
chktyp("s|i", "hi")
chktyp("s|i", 10)
experr(chktyp, "s|i", 10.1)
chktyp("s|i?", nil)
experr(chktyp, "s|i?", {})
chktyp("s|i? i", nil, 10)
experr(chktyp, "s|i? i", nil, 10.1)

print("Tests passed")
