local text = gma.textinput
local feed = gma.feedback 
local cmd = gma.cmd 
local o = gma.show.getobj.handle
local a = gma.show.getobj
local property = gma.show.property.get
local sub = string.sub


function InstanceType(fixtureObject, subFixtureID)
    local fixtureTypeString = property(fixtureObject, 3)
    local fixtureTypeNum = fixtureTypeString:sub(0, fixtureTypeString:find('%s+'))
    local instanceHandle = o("FixtureType " .. fixtureTypeNum .. ".2." .. subFixtureID)
    return property(instanceHandle,1)
end

return function()
    local startFixture = text('First Fixture', '')
    local lastFixture = text('Last Fixture', '')
    local fixtures = {}
    local error = false
    local lastFixtureType = property(o("Fixture " .. startFixture), 3)
    feed ("Fixture Type: " .. lastFixtureType)
    for i = startFixture, lastFixture, 1 do
        local checkFix = o("Fixture " .. math.floor(i))
        if checkFix ~= nil then
            local fixtureType = property(checkFix, 3)
            --feed ("Fix: " .. i .. " Type: " .. fixtureType)
            if (fixtureType ~= lastFixtureType) then
                feed('Fixture Type Mismatch: ' .. fixtureType)
                error = true
            end
        else 
        feed("Gaps in fixture numbers, danger will robinson")
        end

        fixtures[#fixtures + 1] = i
    end
    if error == false then
        feed(#fixtures .. " fixtures of same fixture type found")
        local thisFixture = o("Fixture " .. startFixture)
        local totalInstances = a.amount(thisFixture)
        local instanceSplits = {}
        local childCount, lastChildCount
        local instanceType, lastInstanceType
        
        for i = 1, totalInstances, 1 do
            instanceType = InstanceType(thisFixture, i)
            feed("Instance Type: " .. instanceType)
            if instanceType ~= lastInstanceType then
            instanceSplits[#instanceSplits + 1] = i + 1
            feed("Instance Split " .. #instanceSplits .. " at " .. i)
            end
            lastInstanceType = instanceType
        end

        if #instanceSplits == 1 then
            gma.gui.msgbox("ERROR", "Only one type of instance, nothing to do")
            else
                
        local groupPrefix = text("What we calling this?", lastFixtureType)
        local firstGroup = text('First Group (of ' .. #instanceSplits + 1 ..')to store?', 'ENTER GROUP #')
        if (firstGroup ~= 'ENTER GROUP #') then
            firstGroup = tonumber(firstGroup)
            cmd('BlindEdit On; Fixture ' .. startFixture .. ' thru ' .. lastFixture)
            cmd('Store Group ' .. firstGroup .. ' /o; Label Group ' .. firstGroup .. ' "' .. groupPrefix .. ' ALL Instances"; ClearAll')
            local lastGroup = firstGroup + #instanceSplits - 1

            local thisGroup = math.floor(firstGroup + 1)
            local thisBlock =  math.floor(instanceSplits[2] - instanceSplits[1]) --usually 1 but we can't be 100% sure that'll always be true, cuepix are weird sometimes
            local instancesLeft = math.floor(totalInstances - thisBlock)

            cmd('Group ' .. firstGroup .. '; MB ' .. thisBlock .. '; MI 1.' .. totalInstances .. '; store Group ' .. thisGroup .. ' /o; label Group ' .. thisGroup .. ' "' .. groupPrefix .. ' ' .. InstanceType(thisFixture, 1) ..'"; ClearAll')
            for i = 2, #instanceSplits, 1 do
            cmd('group ' .. firstGroup .. '; - group ' .. math.floor(firstGroup + 1) .. ' thru ' .. math.floor(thisGroup))
            thisGroup = thisGroup + 1
            
            if (i < #instanceSplits) then
                thisBlock =  math.floor(instanceSplits[i + 1] - instanceSplits[i])
                cmd('MB ' .. thisBlock ..'; MI 1.' .. instancesLeft)
                instancesLeft = instancesLeft - thisBlock
            end
            cmd('Store Group ' .. thisGroup .. ' /o; Label Group ' .. thisGroup .. ' "' .. groupPrefix .. ' ' .. InstanceType(thisFixture, instanceSplits[i]) .. '"')
        end  
        cmd('BlindEdit Off')
        end
    end

        
    else 
        gma.gui.msgbox("ERROR", "Multiple fixture types selected, you'd have a a bad time")
    end
end
