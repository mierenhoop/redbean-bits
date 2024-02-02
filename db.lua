local db = {}

db.__index = db

local lsqlite3 = assert(lsqlite3 or require"lsqlite3", "db: lsqlite3 not found")

function db.open(path)
  local pid = unix.getpid()

  local self = setmetatable({}, db)

  self._db = assert(lsqlite3.open(path), "db: could not open")
  self.curpid = pid

  self._db:busy_timeout(1000)
  return self
end

function db:close()
  self._db:close()
  self._db = nil
  self.curpid = nil
end

db.__close, db.__gc = db.close, db.close

local function dbok(db, ret)
  if ret ~= lsqlite3.OK then
    error(db:errmsg())
  end
end

local function prep(db, sql, ...)
  local stmt = db:prepare(sql)
  if not stmt then error(db:errmsg()) end
  dbok(db, stmt:bind_values(...))
  return stmt
end


function db:exec(sql)
  dbok(self._db, self._db:exec(sql))
end

function db:urow(sql, ...)
  local iter, state, _, closer <close> = self:urows(sql, ...)
  return iter(state)
end

function db:urows(sql, ...)
  local stmt = prep(self._db, sql, ...)
  local closer = setmetatable({}, {
    __close = function()
      dbok(self._db, stmt:finalize())
    end
  })
  return stmt:urows(), stmt, nil, closer
end

function db:transaction(f)
  if self.intrans then return f() end

  self:exec"BEGIN TRANSACTION;"

  self.intrans = true
  local ok, err = pcall(f)
  self.intrans = false
  if not ok then
    self:exec"ROLLBACK;"
    error(err)
  end

  self:exec"COMMIT;"
end

return db
