-- Make sure the tests are run after the server has initialized
if not _TEST_INIT then
    _TEST_INIT = true
    local old = OnServerStart
    function OnServerStart()
        dofile("./test.lua")
        if old then old() end
    end

    return
end

if assert(unix.fork()) ~= 0 then return end

assert(true == true)
print("Everything OK :)")

os.exit()
