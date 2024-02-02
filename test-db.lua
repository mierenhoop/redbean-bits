package.path="./?.lua"
local dbmod = require"db"

unix.unlink("/tmp/test.db")
do
  local db <close> = dbmod.open"/tmp/test.db"

  db:exec[[
  CREATE TABLE a (v);
  INSERT INTO a VALUES (1);
  ]]

  local i = 0
  for v in db:urows"select v from a" do
    assert(i == 0 and v == 1, "test 1 failed")
    i = 1
  end
  print"test 1 passed"
end

unix.unlink("/tmp/test.db")
