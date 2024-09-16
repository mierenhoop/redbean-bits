package.path="./?.lua"
local dbopen = require"db"

unix.unlink("/tmp/test.db")
do
  local db <close> = dbopen"/tmp/test.db"

  db.exec[[
  CREATE TABLE a (v);
  INSERT INTO a VALUES (1);
  ]]

  local i = 0
  for v in db.urows"select v from a" do
    assert(i == 0 and v == 1, "test 1 failed")
    i = 1
  end
  print"test 1 passed"

  db.transaction(function()
    db.urow("insert into a(v) values (3)")
  end)
  assert(db.urow"select 1 from a where v = 3" == 1)
  print"test 2 passed"

  pcall(db.transaction, function()
    db.urow("insert into a(v) values (4)")
    error()
  end)
  assert(db.urow"select 1 from a where v = 4" == nil)
  print"test 3 passed"
end

unix.unlink("/tmp/test.db")
