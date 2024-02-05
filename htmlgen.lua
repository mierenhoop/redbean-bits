local function htmlgen(wrt)
  wrt = wrt or Write
  local gsub, format = string.gsub, string.format
  local select, setmetatable = select, setmetatable
  local esc = EscapeHtml or function(s)
    return (gsub(s, "[&><\"']", {
      ["&"]="&amp;", [">"]="&gt;",
      ["<"]="&lt;", ["\""]="&quot;",
      ["'"]="&#39;",
    }))
  end
  local function writeattr(t, off)
    while off <= #t do
      if type(t[off]) == "table" then
        writeattr(t[off], 1)
        off = off + 1
      else
        wrt(" "..t[off])
        off = off + 1
        if t[off] then
          wrt("=\""..esc(t[off]).."\"")
          off = off + 1
        end
      end
    end
    for k, v in pairs(t) do
      if type(k) == "string" then
        wrt(" "..k)
        if v then
          wrt("=\""..esc(v).."\"")
        end
      end
    end
  end

  local mt = {
    __call = function(self, arg)
      return self
    end,
    __close = function(self)
      wrt("</"..self.tag..">")
    end,
  }
  return setmetatable({
    doc = function() wrt"<!DOCTYPE html>" end,
    text = function(self, text, ...)
      if select("#", ...) > 0 then
        text = format(text, ...)
      end
      wrt(esc(text))
    end,
    raw = function(self, raw, ...)
      if select("#", ...) > 0 then
        raw = format(raw, ...)
      end
      wrt(raw)
    end,
  }, {
    __call = function(self, tag)
      local t
      if type(tag) == "table" then
        t = tag
        tag = tag[1]
      end
      wrt("<"..tag)
      if t then
        writeattr(t, 2)
      end
      wrt">"
      return setmetatable({tag=tag, close=mt.__close}, mt)
    end,
  })
end

return htmlgen
