package.path="./?.lua"
local redis = require"redis"

local red = assert(redis.open())

red:set("dog", "an animal")

print("dog", red:get"dog")

red:multi()

red:set("cat", "Marry")

-- works too
red.set("horse", "Bob")

print("exec", EncodeLua(red:exec()))
