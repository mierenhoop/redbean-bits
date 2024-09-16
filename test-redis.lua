package.path="./?.lua"
local redis = require"redis"

local red = assert(redis())

red.set("dog", "an animal")

assert(red.get"dog" == "an animal", "test 1 failed")
print"test 1 passed"

red.multi()

red.set("cat", "Marry")
red.set("horse", "Bob")

local ret = red.exec()
assert(ret[1] == "OK" and ret[2] == "OK", "test 2 failed")
print"test 2 passed"
