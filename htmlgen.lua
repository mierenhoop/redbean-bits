local function htmlgen(wrt)
  wrt = wrt or Write
  local esc = EscapeHtml or function(s)
    return (s:gsub("[&><\"']", {
      ["&"]="&amp;", [">"]="&gt;",
      ["<"]="&lt;", ["\""]="&quot;",
      ["'"]="&#39;",
    }))
  end
  local intag
  local function closetag()
      if intag then wrt(">") intag = false end
  end
  local mt = {
    __call = function(self, arg)
      assert(intag)
      for i = 1, #arg, 2 do
        wrt(" "..arg[i])
        if arg[i+1] then
          wrt("=\""..esc(arg[i+1]).."\"")
        end
      end
      for k, v in pairs(arg) do
        if type(k) == "string" then
          wrt(" "..k)
          if v then
            wrt("=\""..esc(v).."\"")
          end
        end
      end
      return self
    end,
    __close = function(self)
      closetag()
      wrt("</"..self.tag..">")
    end,
  }
  return setmetatable({
    doc = function() wrt"<!DOCTYPE html>" end,
    text = function(self, text, ...)
      closetag()
      if select("#", ...) == 0 then
        text = string.format(text, ...)
      end
      wrt(esc(text))
    end,
    raw = function(self, raw, ...)
      closetag()
      if select("#", ...) == 0 then
        raw = string.format(raw, ...)
      end
      wrt(raw)
    end,
    close = closetag
  }, {
    __call = function(self, tag)
      closetag()
      wrt("<"..tag)
      intag = true
      return setmetatable({tag=tag,close=mt.__close}, mt)
    end,
    __close = closetag,
  })
end

return htmlgen
