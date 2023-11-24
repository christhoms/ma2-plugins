--half-it v0.1


-- Choose a group and world number here that will be way clear of anything you use in your programming, it will be overwritten and deleted after this runs
local tempGroup = 2999
local tempWorld = 999




------

local text = gma.textinput
local feed = gma.feedback
local cmd = gma.cmd
local o = gma.show.getobj.handle
local a = gma.show.getobj
local property = gma.show.property.get
local sub = string.sub
local print = feed
local getHandle = gma.show.getobj.handle
local getClass = gma.show.getobj.class
local unpack = table.unpack


-------
function GetGroup(grpNum)
    gma.cmd('SelectDrive 1') -- select the internal drive

    local file = {}
    file.name = 'tempfile.xml'
    file.directory = gma.show.getvar('PATH') .. '/' .. 'importexport' .. '/'
    file.fullpath = file.directory .. file.name
    gma.cmd('Export Group ' .. grpNum .. ' \"' .. file.name .. '\" /o') -- create temporary file

    local t = {} -- convert XML file into a table
    for line in io.lines(file.fullpath) do
        t[#t + 1] = line
    end
    os.remove(file.fullpath) -- delete temporary file

    local groupList = {} -- declare groupList
    for i = 1, #t do
        if t[i]:find('Subfixture ') then
            local indices = {t[i]:find('\"%d+\"')} -- find points of quotation marks
            indices[1], indices[2] = indices[1] + 1, indices[2] - 1 -- move reference points to first an last characters inside those marks

            -- label based on status as a fixture or as a channel
            local fixture
            if t[i]:find('fix_id') then
                fixture = 'Fixture ' .. tostring(t[i]:sub(indices[1], indices[2])) -- extract the number as the fixture number
            elseif t[i]:find('cha_id') then
                fixture = 'Channel ' .. tostring(t[i]:sub(indices[1], indices[2]))
            end -- extract the number as the fixture number

            -- if the object contains a subfixture...
            if t[i]:find('sub_index') then
                local indices = {t[i]:find('\"%d+\"', indices[2] + 2)}
                indices[1], indices[2] = indices[1] + 1, indices[2] - 1
                fixture = fixture .. '.' .. tostring(t[i]:sub(unpack(indices)))
            end

            -- append to list
            groupList[#groupList + 1] = fixture -- extract the number to the group list
        end
    end
    return groupList
end


return function()
    cmd("Delete World " .. tempWorld .. "; Store World " .. tempWorld .. ";BlindEdit On; Fixture Thru")
    cmd("Store Group " .. tempGroup .. " /o /nc")
    local groupFixtures = getGroup(tempGroup)
    cmd("World 1; Delete World " .. tempWorld .. "; Delete Group " .. tempGroup .. "; BlindEdit Off" )
    local fixCount = #groupFixtures
    local halfFix = math.floor(fixCount/2)
    cmd("MaTricksBlocks " .. halfFix)
    cmd('Next')
end
