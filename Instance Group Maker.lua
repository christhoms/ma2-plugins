local text = gma.textinput
local feed = gma.feedback 
local cmd = gma.cmd 
local o = gma.show.getobj.handle
local a = gma.show.getobj
local property = gma.show.property.get
local sub = string.sub



return function()
    local startFixture = text('First Fixture', '')
    local lastFixture = text('Last Fixture', '')
    local totalInstances = text('Number of Instances Total?', '')
    local instanceTypeNum = tonumber(text('Number Of Instance Types?', ''))
    local instanceSplits = {}
    for i = 2, instanceTypeNum, 1 do
        instanceSplits[i] = text('Instance type ' .. i .. ' starts at which subfixture?', '')
    end
    local firstGroup = text('First Group to store?', '')
    cmd('BlindEdit On; Fixture ' .. startFixture .. ' thru ' .. lastFixture)
    cmd('Store Group ' .. firstGroup .. ' /o; Label Group ' .. firstGroup .. ' "ALL Instances"; ClearAll')
    local lastGroup = firstGroup + instanceTypeNum - 1
    local thisGroup = math.floor(firstGroup + 1)
    local instancesLeft = math.floor(totalInstances - (instanceSplits[2] - 1))
    cmd('Group ' .. firstGroup .. '; MI 1.' .. totalInstances .. '; store Group ' .. thisGroup .. ' /o; label Group ' .. thisGroup .. ' "Instance Type 1"; ClearAll')
        for i = 2, instanceTypeNum, 1 do
        cmd('group ' .. firstGroup .. '; - group ' .. math.floor(firstGroup + 1) .. ' thru ' .. math.floor(thisGroup))
        thisGroup = thisGroup + 1
        
        if (i < instanceTypeNum) then
            local thisBlock =  math.floor(instanceSplits[i + 1] - instanceSplits[i])
            cmd('MB ' .. thisBlock ..'; MI 1.' .. instancesLeft)
            instancesLeft = instancesLeft - thisBlock
        end
        cmd('Store Group ' .. thisGroup .. ' /o; Label Group ' .. thisGroup .. ' "Instance Type ' .. i .. '"')
    end  
    cmd('BlindEdit Off')
end
