--[[config]]--
local speedMaster = "SpecialMaster 3.1"
local nudgeAmount = 2


--[[handy shortcuts]]--
local text = gma.textinput
local feed = gma.feedback
local cmd = gma.cmd
local o = gma.show.getobj.handle
local property = gma.show.property.get

--[[actual functions that do things]]--
function NudgeBPMUp()
    local master = o(speedMaster)
    local speedPercent = property(master, 1)
    local speedBPM = math.floor(((tonumber(speedPercent:sub(0, speedPercent:len() - 1)) / 100) * 225) + 0.5)
    --feed("BPM:" .. speedBPM)
    gma.show.setvar("StoredBPM", speedBPM)
    local nudgeBPM = speedBPM + nudgeAmount
    cmd(speedMaster .. " at " .. nudgeBPM)
end

function NudgeBPMDown()
    local master = o(speedMaster)
    local speedPercent = property(master, 1)
    local speedBPM = math.floor(((tonumber(speedPercent:sub(0, speedPercent:len() - 1)) / 100) * 225) + 0.5)
    --feed("BPM:" .. speedBPM)
    gma.show.setvar("StoredBPM", speedBPM)
    local nudgeBPM = speedBPM - nudgeAmount
    cmd(speedMaster .. " at " .. nudgeBPM)
end