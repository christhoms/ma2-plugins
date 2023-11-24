local criteria = "If Sequence /lm /nc"

local firstJDC = 201
local lastJDC = 244

local firstStrikeM = 601
local lastStrikeM = 644


--MA STUFF
local text = gma.textinput
local feed = gma.feedback
local cmd = gma.cmd
local o = gma.show.getobj.handle
local a = gma.show.getobj
local property = gma.show.property.get
local print = feed


--Create an Array like: strikeMInstanceMap[destinationInstance] = sourceInstance
local strikeMInstanceMap = {}

--RGB ROW 1
strikeMInstanceMap[6] = 3
strikeMInstanceMap[7] = 4
strikeMInstanceMap[8] = 5
strikeMInstanceMap[9] = 5
strikeMInstanceMap[10] = 6
strikeMInstanceMap[11] = 7
strikeMInstanceMap[12] = 8
--RGB ROW 2
strikeMInstanceMap[13] = 9
strikeMInstanceMap[14] = 10
strikeMInstanceMap[15] = 11
strikeMInstanceMap[16] = 11
strikeMInstanceMap[17] = 12
strikeMInstanceMap[18] = 13
strikeMInstanceMap[19] = 14
--WHITE ROW 1
strikeMInstanceMap[20] = 15
strikeMInstanceMap[21] = 16
strikeMInstanceMap[22] = 17
strikeMInstanceMap[23] = 18
strikeMInstanceMap[24] = 19
strikeMInstanceMap[25] = 20
strikeMInstanceMap[26] = 20
strikeMInstanceMap[27] = 21
strikeMInstanceMap[28] = 21
strikeMInstanceMap[29] = 22
strikeMInstanceMap[30] = 23
strikeMInstanceMap[31] = 24
strikeMInstanceMap[32] = 25
strikeMInstanceMap[33] = 26
--WHITE ROW 2
strikeMInstanceMap[34] = 15
strikeMInstanceMap[35] = 16
strikeMInstanceMap[36] = 17
strikeMInstanceMap[37] = 18
strikeMInstanceMap[38] = 19
strikeMInstanceMap[39] = 20
strikeMInstanceMap[40] = 20
strikeMInstanceMap[41] = 21
strikeMInstanceMap[42] = 21
strikeMInstanceMap[43] = 22
strikeMInstanceMap[44] = 23
strikeMInstanceMap[45] = 24
strikeMInstanceMap[46] = 25
strikeMInstanceMap[47] = 26


return function()
    local destFixture = firstStrikeM
    for f = firstJDC, lastJDC do
        for k,v in pairs(strikeMInstanceMap) do
            local cmdString = "Clone Fixture " .. f .. "." .. v .. " at Fixture " .. destFixture .. "." .. k .. " " .. criteria
            feed(cmdString)
            --uncomment when ready to run
            --cmd(cmdString)
    end

end
