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





local leftGroup = 434
local rightGroup = 435
local inGroup = 436
local outGroup = 437

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



function ProcessGroups(thisGroup)
    feed("Creating slightly smarter groups for: " .. property(o("Group " .. thisGroup), 1))
    
    --Create Slightly smarter groups
    cmd('BlindEdit On')
    local groupFixtures = GetGroup(thisGroup)
    cmd('ClearAll')
    cmd("MaTricksReset")
    cmd("Group " .. thisGroup)
    local fixCount = #groupFixtures
    local halfFix = math.floor(fixCount/2)
    local inOutFix = math.ceil(halfFix / 2)
    cmd("MaTricksBlocks " .. halfFix)
    cmd('Next')
    cmd('Store Group ' .. leftGroup .. ' /m')
    cmd('Next')
    cmd('Store Group ' .. rightGroup .. ' /m')
    cmd("MaTricksReset")
    cmd("MaTricksWings 2")
    cmd("MaTricksBlocks " .. inOutFix)
    cmd('Next')
    cmd('Store Group ' .. outGroup .. ' /m')
    cmd('Next')
    cmd('Store Group ' .. inGroup .. ' /m')
    cmd('ClearAll')
    cmd('Group ' .. leftGroup)
    cmd('Store World "LEFT" /o')
    cmd('Group ' .. rightGroup)
    cmd('Store World "RIGHT" /o')
    cmd('ClearAll')
    cmd('BlindEdit Off')
end

return function()
    cmd('BlindEdit On; ClearAll; Store Group ' .. leftGroup .. ' thru ' .. outGroup .. ' /o; BlindEdit Off')
    ProcessGroups(3)
    ProcessGroups(4)
    ProcessGroups(5)
    ProcessGroups(6)
    ProcessGroups(9)
    ProcessGroups(10)
    ProcessGroups(12)
    ProcessGroups(14)
    ProcessGroups(15)
end
