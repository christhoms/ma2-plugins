
--[[    
chris@chris.uk
CONFIGURATION: change here if you want it to skip steps ]]

local askInstanceTypes = true -- Ask whether to include each instance type in layout? Set to false for full send
local drawBitmapBox = true -- Draw bitmap rectangle around fixtures, set to false to disable
local createInstanceGroups = true -- Create groups for each instance type at the end, set to false to disable



--[[
DON'T CHANGE ANYTHING BELOW HERE
]]

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

function median(numlist)
    if type(numlist) ~= 'table' then
        return numlist
    end
    table.sort(numlist)
    if #numlist % 2 == 0 then
        return (numlist[#numlist / 2] + numlist[#numlist / 2 + 1]) / 2
    end
    return numlist[math.ceil(#numlist / 2)]
end

function split(s)
    chunks = {}
    for substring in s:gmatch("%S+") do
        table.insert(chunks, substring)
    end
    return chunks
end

function InstanceType(fixtureObject, subFixtureID)
    local fixtureTypeString = property(fixtureObject, 3)
    local fixtureTypeNum = fixtureTypeString:sub(0, fixtureTypeString:find('%s+'))
    local instanceHandle = o("FixtureType " .. fixtureTypeNum .. ".2." .. subFixtureID)
    local typeName = property(instanceHandle, 1)
    --feed("Subfix: " .. subFixtureID .. " has type:" .. typeName)
    return typeName
end

function getGroup(grpNum)
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

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function table.findkey(table, element)
    for key, value in pairs(table) do
        if value == element then
            return key
        end
    end
    return nil
end

function keysOfSet(set)
    local ret = {}
    for k, _ in pairs(set) do
        ret[#ret + 1] = k
    end
    return ret
end

-- fun stuff below

function createLayout(group)

    local groupHandle = o("Group " .. group)
    local groupName = property(groupHandle, 1)
    local groupFixtures = getGroup(group)
    local fixType
    local instId
    if next(groupFixtures) ~= nil then
        -- build tables of fixtures and instances
        local fixtureList = {}
        local instanceList = {}
        local instanceCount = 0
        local mainFix
        local subFix
        for i = 1, #groupFixtures, 1 do
            if groupFixtures[i]:find('%.') then -- fixture has subfixtures
                -- feed("Found . in fixture ID")
                local splitPoint = {groupFixtures[i]:find(' '), groupFixtures[i]:find('%.')}
                mainFix = tonumber(groupFixtures[i]:sub(splitPoint[1] + 1, splitPoint[2] - 1))
                subFix = tonumber(groupFixtures[i]:sub(splitPoint[2] + 1))
                if table.contains(fixtureList, mainFix) == false then
                    fixtureList[#fixtureList + 1] = mainFix
                    instanceList[mainFix] = {}
                end

                if table.contains(instanceList[mainFix], subFix) then
                    feed("duplicate instance")
                else
                    instanceList[mainFix][subFix] = true
                    instanceCount = instanceCount + 1
                end

            else -- single instance fixture

                local splitPoint = groupFixtures[i]:find(' ')
                mainFix = tonumber(groupFixtures[i]:sub(splitPoint + 1))
                if table.contains(fixtureList, mainFix) == false then
                    fixtureList[#fixtureList + 1] = mainFix
                    instanceList[mainFix] = {}
                end
            end
        end
        feed("Fixtures: " .. #fixtureList)
        feed("Instance arrays: " .. #instanceList)
        feed("InstanceCount:" .. instanceCount)

        -- check for same fixturetypes
        local firstFixture = fixtureList[1]

        local fixtures = {}
        local error = false
        local firstFixtureType = property(o("Fixture " .. fixtureList[1]), 3)

        feed("Fixture Type: " .. firstFixtureType)
        for i = 1, #fixtureList, 1 do
            local checkFix = o("Fixture " .. fixtureList[i])
            if checkFix ~= nil then
                local fixtureType = property(checkFix, 3)
                -- feed ("Fix: " .. i .. " Type: " .. fixtureType)
                if (fixtureType ~= firstFixtureType) then
                    feed('Fixture Type Mismatch: ' .. fixtureType)
                    error = true
                end
            else
                feed("Gaps in fixture numbers, danger will robinson")
            end

            fixtures[#fixtures + 1] = i
        end

        if error == false then
            local fixtureTypeNum = firstFixtureType:sub(0, firstFixtureType:find('%s+'))
            -- feed("Instance Count is at: " .. instanceCount)
            feed("Fixture Type: " .. fixtureTypeNum)
            local rowYPos = -2 -- offset so first row is 0
            local pixelLayout = {}
            local maxCount = 0
            local totalInstances
            local instanceSplits = {}
            local instanceTypes = {}
            local instanceType, lastinstanceType, scaleFactor

            if instanceCount > 0 then -- multi instance
                scaleFactor = text("Scale Factor?", 10)
                feed("Multi Instance Detected")
                feed(#fixtures .. " fixtures of same fixture type found")

                -- find instance splits
                local thisFixture = o("Fixture " .. firstFixture)
                totalInstances = a.amount(thisFixture)

                for i = 1, totalInstances, 1 do
                    instanceType = InstanceType(thisFixture, i)
                    -- feed("Instance Type: " .. instanceType)
                    if instanceType ~= lastInstanceType then
                        instanceSplits[#instanceSplits + 1] = i + 1
                        instanceTypes[#instanceSplits] = instanceType
                        feed("Instance Split " .. #instanceSplits .. " at " .. i)
                    end
                    lastInstanceType = instanceType
                end

                for i = 1, #instanceSplits, 1 do
                    rowYPos = rowYPos + 1 -- add a gap between instance types
                    -- determine layout of pixels per instance type
                    local pixelsThisRow

                    if #instanceSplits > i then
                        pixelsThisRow = instanceSplits[i + 1] - instanceSplits[i]
                    else
                        pixelsThisRow = (totalInstances - instanceSplits[i]) + 2 -- I don't know why + 2 but it made it work
                    end
                    feed("There should be " .. pixelsThisRow .. " pixels of Type: " .. instanceTypes[i])
                    local firstInstance = instanceSplits[i] - 1
                    local lastInstance = (instanceSplits[i] + pixelsThisRow) - 2 -- again, not sure.
                    feed("Pixel: " .. firstInstance .. " to:" .. lastInstance)
                    -- local allX = {}
                    -- local allY = {}
                    -- local allZ = {}
                    local pixelRows = {}
                    local rowValues = {}
                    local rowInstances = {}
                    local thisRow = 0
                    local r = 0

                    local lastX, lastY, lastZ

                    for pix = firstInstance, lastInstance, 1 do
                        local instanceHandle = o("FixtureType " .. fixtureTypeNum .. '.2.' .. pix)
                        local instX = tonumber(property(instanceHandle, 3))
                        local instY = tonumber(property(instanceHandle, 4))
                        local instZ = tonumber(property(instanceHandle, 5))

                        -- feed("Instance " .. i .. " X:" .. instX .. " Y:" .. instY .. " Z:" .. instZ)
                        if instY ~= lastY then
                            if table.contains(rowValues, instY) then
                                for p = 1, #rowValues, 1 do
                                    if rowValues[p] == instY then
                                        thisRow = p
                                    end
                                end
                                --            feed("Pixel Row Exists: " .. thisRow)
                            else
                                thisRow = #pixelRows + 1
                                rowValues[thisRow] = instY
                                rowInstances[thisRow] = {}
                                pixelRows[thisRow] = {}
                                pixelRows[thisRow]['pixels'] = {}
                                r = 1
                            end
                        end

                        -- feed("This row: " .. thisRow .. " pix: " .. pix .. " X:" .. instX)

                        pixelRows[thisRow][r] = {}
                        pixelRows[thisRow][r]['x'] = instX;
                        pixelRows[thisRow][r]['inst'] = pix;

                        -- replace this with a better way

                        -- allX[#allX + 1] = instX
                        -- allY[#allY + 1] = instY
                        -- allZ[#allZ + 1] = instZ
                        r = r + 1

                        lastY = instY
                    end

                    feed("Pixel Rows:" .. #pixelRows)
                    for i = 1, #pixelRows, 1 do
                        rowYPos = rowYPos + 1
                        -- sort rows by low X to high X
                        function compare(a, b)
                            return a['x'] < b['x']
                        end
                        table.sort(pixelRows[i], compare)
                        -- give new X co-ordinate
                        local xArr = {}

                        for a = 1, #pixelRows[i], 1 do
                            xArr[a] = pixelRows[i][a]['x']
                        end

                        -- local instances = keysOfSet(pixelRows[i])

                        local numCells = #pixelRows[i]
                        local firstCellX = ((numCells - 1) / 2) * -1
                        local lastCellX = (numCells - 1) / 2
                        feed("Row " .. i .. " contains " .. numCells .. " cells")

                        local minX = math.min(unpack(xArr))
                        local maxX = math.max(unpack(xArr))

                        -- feed("Min: " .. minX .. " Max:" .. maxX)
                        -- feed("First: " .. firstCellX .. " Last: " .. lastCellX)
                        local thisCell = firstCellX
                        for key, value in ipairs(pixelRows[i]) do
                            -- feed("Inst:" .. value['inst'] .. " gets X:" .. thisCell .. " Y:" .. rowYPos)
                            local thisInstance = value['inst'];
                            pixelLayout[thisInstance] = {thisCell, rowYPos}
                            thisCell = thisCell + 1
                        end
                        if (#pixelRows[i] > maxCount) then
                            maxCount = #pixelRows[i]
                        end
                    end
                end
            else -- single instance fixture
                feed("Single Instance Detected")
                pixelLayout[1] = {0, 0}
                totalInstances = 1
                scaleFactor = 1

            end
            -- now we have auto generated pixel layout, throw into temporary layout and prompt for any amends or load custom layout maybe?

            feed('Each fixture will need: ' .. maxCount .. ' columns and ' .. rowYPos .. ' rows')

            -- decide whether to use 3D INFO or manual rows

            local chooseLayoutType = gma.gui.confirm("Use 3D Info?",
                "Click OK to use 3D Positions\nCancel to specify manual rows")
            local frontView = nil
            local fixturePositions = {}
            if chooseLayoutType == nil then
                -- gather info needed to draw layout
                local fixtureRows = {}
                -- sort fixtures by fixtureID
                function compare(a, b)
                    return a < b
                end
                table.sort(fixtureList, compare)

                local thisFixture = fixtureList[1]
                local remainingFixtures = #fixtureList

                while remainingFixtures > 0 do
                    local thisRow = #fixtureRows + 1
                    local rowQty = text("Row" .. thisRow .. " fixtures (" .. remainingFixtures .. " left)",
                        "# of fixtures")
                    if rowQty ~= "# of fixtures" then
                        if tonumber(rowQty) <= remainingFixtures then
                            -- passed validation
                            fixtureRows[thisRow] = tonumber(rowQty)
                            remainingFixtures = remainingFixtures - tonumber(rowQty)
                            feed("subtracting " .. rowQty .. " fixtures, " .. remainingFixtures .. " remaining")
                        else
                            feed("Too many! setting to last fixtures")
                            fixtureRows[thisRow] = remainingFixtures
                            remainingFixtures = 0
                        end
                    else
                        -- throw error and decide whether to continue
                        feed("Error")
                        break
                    end
                end
                -- check for error/break

                -- find widest row and base other positions on widest, to center fixtures nicely (maybe?!?)
                local fixCount = 1
                for i = 1, #fixtureRows, 1 do
                    feed("Row: " .. i .. " Fixtures:" .. fixtureRows[i])
                    local xMultiplier = maxCount + 2
                    local yMultiplier = rowYPos + 2
                    local firstFixtureX = (((fixtureRows[i] - 1) / 2) * -1) * xMultiplier
                    local lastFixtureX = ((fixtureRows[i] - 1) / 2) * xMultiplier

                    local thisFixtureX = firstFixtureX
                    for f = 1, fixtureRows[i], 1 do
                        local thisFixID = fixtureList[fixCount]
                        local thisFixture = o("Fixture " .. thisFixID .. ".1")
                        fixturePositions[#fixturePositions + 1] = {}
                        fixturePositions[#fixturePositions]['fixture'] = thisFixID
                        fixturePositions[#fixturePositions]['x'] = thisFixtureX
                        fixturePositions[#fixturePositions]['y'] = i * yMultiplier
                        fixturePositions[#fixturePositions]['z'] = i * yMultiplier
                        fixCount = fixCount + 1
                        thisFixtureX = thisFixtureX + xMultiplier
                    end
                end

            else

                frontView = gma.gui.confirm("Which Axis?", "OK for Front, CANCEL for Top")

                -- get 3d positions
                local allX, allY, allZ = {}, {}, {}
                local xRows, yRows, zRows = {}, {}, {}
                local xRowFixtures, yRowFixtures, zRowFixtures = {}, {}, {}
                for i = 1, #fixtureList, 1 do
                    local thisFixID = fixtureList[i]
                    local thisFixture = o("Fixture " .. thisFixID .. ".1")
                    local mainX, mainY, mainZ = property(thisFixture, 15), property(thisFixture, 16),
                        property(thisFixture, 17)
                    feed("Fixture: " .. thisFixID .. " X:" .. mainX .. " Y:" .. mainY .. " Z:" .. mainZ)
                    fixturePositions[#fixturePositions + 1] = {}
                    fixturePositions[#fixturePositions]['fixture'] = thisFixID
                    fixturePositions[#fixturePositions]['x'] = mainX
                    fixturePositions[#fixturePositions]['y'] = mainY
                    fixturePositions[#fixturePositions]['z'] = mainZ
                    allX[#allX + 1] = mainX
                    allY[#allY + 1] = mainY
                    allZ[#allZ + 1] = mainZ

                    local rowKey = table.findkey(yRows, mainY)
                    if rowKey ~= nil then
                        -- other fixture at this Y, might be a row
                        feed("Row Key: " .. rowKey)
                        -- local existingRows = yrowFixtures[rowKey]
                        yRowFixtures[rowKey][#yRowFixtures[rowKey] + 1] = thisFixID
                    else
                        yRows[#yRows + 1] = mainY
                        yRowFixtures[#yRowFixtures + 1] = {}
                    end

                end
                feed('Total Y Rows:' .. #yRows)

                -- do some math to figure out a good layout
                --[[
                local freqX = tally(allX)
                local freqY = tally(allY)
                local freqZ = tally(allZ)
                for key, value in pairs(freqY) do
                    feed("Y:" .. key .. ">" ..value)
                end
                for key, value in pairs(freqX) do
                    feed("X:" .. key .. ">" ..value)
                end
                for key, value in pairs(freqZ) do
                    feed("Z:" .. key .. ">" ..value)
                end
                feed("Fixtures with same Y: " .. math.max(unpack(freqY)))
                feed("Fixtures with same X: " .. math.max(unpack(freqX)))
                feed("Fixtures with same Z: " .. math.max(unpack(freqZ)))
                --]]
                local furthestLeft = math.min(unpack(allX))
                local furthestRight = math.max(unpack(allX))
                local furthestUp = math.max(unpack(allY))
                local furthestDown = math.min(unpack(allY))

                for i = 1, #fixturePositions, 1 do
                    local thisFixture = fixturePositions[i]
                    fixturePositions[i]['x'] = thisFixture['x'] * scaleFactor
                    fixturePositions[i]['y'] = thisFixture['y'] * scaleFactor
                    fixturePositions[i]['z'] = thisFixture['z'] * scaleFactor
                end
            end

            local destLayout = text("Where you want it?", "Choose layout #")
            if destLayout ~= "Choose layout #" then

                -- one thing to try, determine if any fixture is within "width of pixels" of other fixtures
                -- if so, increase multiplication factor until it doesn't, and then add a couple of pixels for nice padding

                -- will need an array with all required instances of selected fixtures
                local allSubfixtures = {}
                local includedInstances = {}
                if askInstanceTypes then
                    for i = 1, #instanceSplits, 1 do
                        local instanceTypeName = InstanceType(o("Fixture " .. firstFixture), instanceSplits[i] - 1)
                        local confirmType = gma.gui.confirm("Include these Subfixtures?", "Instance Type: " ..
                            instanceTypeName .. "\nInclude in layout?")
                        if confirmType ~= nil then
                            if i < #instanceSplits then
                                for ii = instanceSplits[i] - 1, instanceSplits[i + 1] - 2, 1 do
                                    includedInstances[#includedInstances + 1] = ii
                                    feed("Including " .. ii)
                                end
                            else
                                for ii = instanceSplits[i] - 1, totalInstances, 1 do
                                    feed ("Last Type: Including " .. ii)
                                    includedInstances[#includedInstances + 1] = ii
                                end
                            end
                        end

                    end
            else
                for i = 1, totalInstances, 1 do
                    includedInstances[#includedInstances + 1] = i
                end
            end
                for i = 1, #fixtureList, 1 do
                    for s = 1, totalInstances, 1 do
                        if table.contains(includedInstances, s) then
                            allSubfixtures[#allSubfixtures + 1] = "Fixture " .. fixtureList[i] .. "." .. s
                        end
                    end
                end
                if #includedInstances == 0 and instanceCount == 0 then --hacky fix
                    includedInstances[1] = 1
                end
                -- position cells in layout data

                local layoutName = property(o("Group " .. group), 1)
                feed("Layout Name: " .. layoutName)
                -- make the layout XML
                local xmlText = [[<?xml version="1.0" encoding="utf-8"?>
<MA xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.malighting.de/grandma2/xml/MA" xsi:schemaLocation="http://schemas.malighting.de/grandma2/xml/MA http://schemas.malighting.de/grandma2/xml/3.2.2/MA.xsd" major_vers="3" minor_vers="2" stream_vers="2">
    <Info datetime="2016-09-26T20:40:54" showfile="dummyfile" />
    <Group index="]] .. destLayout .. [[" name="]] .. layoutName .. [[">    
        <Subfixtures>
                    ]]

                for key, fixture in pairs(allSubfixtures) do
                    fixstring = split(fixture)[1]
                    fixid = split(fixture)[2]
                    if (fixstring == "Fixture") then
                        xmltag = "fix_id"
                    end
                    if (fixstring == "Channel") then
                        xmltag = "cha_id"
                    end
                    xmlText = xmlText .. "          <Subfixture " .. xmltag .. "=\"" .. fixid .. "\" />\n"
                end

                xmlText = xmlText .. [[
                        </Subfixtures>
                        <LayoutData index="0" snap_always_active="true" background_color="000000" visible_grid_h="1" visible_grid_w="0" snap_grid_h="0.5" snap_grid_w="0.5" default_gauge="Filled &amp; Symbol" subfixture_view_mode="DMX Layer">
                            <SubFixtures>
                ]]

                -- instead of normal 3D layout, place our pixel layout instead
                local xList, yList = {}, {} -- these are to figure out rectangle for bitmapping

                for i = 1, #fixturePositions, 1 do

                    local thisFixture = fixturePositions[i]['fixture']
                    local baseX = fixturePositions[i]['x']
                    local baseY = fixturePositions[i]['y'] * -1
                    local baseZ = fixturePositions[i]['z'] * -1

                    feed("Fixture: " .. thisFixture .. " X:" .. baseX .. " Y:" .. baseY .. " Z:" .. baseZ)
                    for p = 1, #pixelLayout do
                        if table.contains(includedInstances, p) then
                            local posX = baseX + pixelLayout[p][1]
                            feed ("PosX: " .. posX)
                            local posZ
                            if frontView ~= nil then
                                posZ = baseZ + pixelLayout[p][2]
                            else
                                posZ = baseY + pixelLayout[p][2]
                            end

                            local instID = p
                            local sizeX = 1
                            local sizeY = 1
                            xmlText = xmlText .. [[
                            <LayoutSubFix center_x="]] .. posX .. [[" center_y="]] .. posZ .. [[" size_h="]] .. sizeY ..
                                          [[" size_w="]] .. sizeX ..
                                          [[" background_color="00000000" icon="None" show_id="1" show_type="1" function_type="Filled" select_group="1" enable_bitmaps="true">
                                <image/>
                                <Subfixture sub_index="]] .. instID .. [[" fix_id="]] .. thisFixture .. [[" />
                            </LayoutSubFix>
                ]]
                            xList[#xList + 1] = tonumber(posX)
                            yList[#yList + 1] = tonumber(posZ)
                        end
                    end

                end
                -- figure out where to draw bitmap rectangle
                local furthestLeft = math.min(unpack(xList))
                local furthestRight = math.max(unpack(xList))
                local furthestUp = math.max(unpack(yList))
                local furthestDown = math.min(unpack(yList))
                local centerX = math.abs((math.abs(furthestRight) - math.abs(furthestLeft)) / 2)
                local centerY = ((math.abs(furthestUp) + math.abs(furthestDown)) / 2)
                if (furthestUp < 0 and furthestDown < 0) then
                    centerY = centerY * -1
                end
                local rectWidth = math.abs(math.abs(furthestRight) + math.abs(furthestLeft)) + (2 * scaleFactor)
                local rectHeight = math.abs(math.abs(furthestDown) - math.abs(furthestUp)) + (2 * scaleFactor)

                feed("<L:" .. furthestLeft .. " R>:" .. furthestRight .. " U:" .. furthestUp .. " D:" .. furthestDown)
                feed("Center X: " .. centerX)
                feed("Center Y: " .. centerY)
                feed("Width: " .. rectWidth)
                feed("Height: " .. rectHeight)
                xmlText = xmlText .. "    </SubFixtures>"
                if drawBitmapBox then
                xmlText = xmlText .. [[
                    <Rectangles>
                    <LayoutElement font_size="Small" center_x="]] .. centerX .. [[" center_y="]] .. centerY ..
                              [[" size_h="]] .. rectHeight .. [[" size_w="]] .. rectWidth ..
                              [[" background_color="00000000" icon="None" show_id="1" show_name="1" show_type="1" show_dimmer_bar="Off" show_dimmer_value="Off" function_type="Bitmap">
                        <image/>
                    </LayoutElement>
                </Rectangles>
                ]]
                end
                xmlText = xmlText .. [[
        </LayoutData>
    </Group>
</MA>     
]]
                -- Write XML file to disk --
                local newlayout = {}
                newlayout.name = 'tempfile_createlayout'
                newlayout.directory = gma.show.getvar('PATH') .. '/importexport/'
                newlayout.fullpathXML = newlayout.directory .. newlayout.name .. '.xml'
                local fileXML = assert(io.open(newlayout.fullpathXML, 'w'))
                fileXML:write(xmlText)
                fileXML:close()

                -- import layout --
                cmd('Import \"' .. newlayout.name .. '.xml' .. '\" Layout ' .. tostring(destLayout) .. ' /nc') -- load new layout into showfile

                -- delete temp files --
                os.remove(newlayout.fullpathXML)
            end

            if instanceCount > 0 and createInstanceGroups then -- if multi instance, offer to make groups

                local createGroupsConfirm = gma.gui.confirm("Create Instance Groups?",
                    "OK to create groups for each Instance Type")
                if createGroupsConfirm ~= nil then
                    local thisFixture = o("Fixture " .. firstFixture)
                    local groupPrefix = text("What we calling this?", groupName)
                    local firstGroup = text('First Group (of ' .. #instanceSplits + 1 .. ')to store?', 'ENTER GROUP #')
                    if (firstGroup ~= 'ENTER GROUP #') then
                        firstGroup = tonumber(firstGroup)
                        cmd('BlindEdit On');
                        for i = 1, #fixtureList, 1 do
                            cmd('Fixture ' .. fixtureList[i]);
                        end
                        cmd('Store Group ' .. firstGroup .. ' /o; Label Group ' .. firstGroup .. ' "' .. groupPrefix ..
                                ' ALL Instances"; ClearAll')
                        local lastGroup = firstGroup + #instanceSplits - 1

                        local thisGroup = math.floor(firstGroup + 1)
                        local thisBlock = math.floor(instanceSplits[2] - instanceSplits[1]) -- usually 1 but we can't be 100% sure that'll always be true, cuepix are weird sometimes
                        local instancesLeft = math.floor(totalInstances - thisBlock)

                        cmd('Group ' .. firstGroup .. '; MB ' .. thisBlock .. '; MI 1.' .. totalInstances ..
                                '; store Group ' .. thisGroup .. ' /o; label Group ' .. thisGroup .. ' "' .. groupPrefix ..
                                ' ' .. InstanceType(thisFixture, 1) .. '"; ClearAll')
                        for i = 2, #instanceSplits, 1 do
                            cmd('group ' .. firstGroup .. '; - group ' .. math.floor(firstGroup + 1) .. ' thru ' ..
                                    math.floor(thisGroup))
                            thisGroup = thisGroup + 1

                            if (i < #instanceSplits) then
                                thisBlock = math.floor(instanceSplits[i + 1] - instanceSplits[i])
                                cmd('MB ' .. thisBlock .. '; MI 1.' .. instancesLeft)
                                instancesLeft = instancesLeft - thisBlock
                            end
                            cmd(
                                'Store Group ' .. thisGroup .. ' /o; Label Group ' .. thisGroup .. ' "' .. groupPrefix ..
                                    ' ' .. InstanceType(thisFixture, instanceSplits[i] - 1) .. '"')
                        end
                        cmd('BlindEdit Off')
                        logoTag()
                    end
                end
            end

        end

    end
end

function tally(t)
    local freq = {}
    for _, v in ipairs(t) do
        freq[v] = (freq[v] or 0) + 1
    end
    return freq
end

function keysOfSet(set)
    local ret = {}
    for k, _ in pairs(set) do
        ret[#ret + 1] = k
    end
    return ret
end

function IsNumeric(data)
    if type(data) == "number" then
        return true
    else
        return false
    end
end

function logoTag()
    feed("\n        __         _      ______       __         _             __  \n  _____/ /_  _____(_)____/ ____ \\_____/ /_  _____(_)____ __  __/ /__\n / ___/ __ \\/ ___/ / ___/ / __ `/ ___/ __ \\/ ___/ / ___// / / / //_/\n/ /__/ / / / /  / (__  ) / /_/ / /__/ / / / /  / (__  )/ /_/ / ,<   \n\\___/_/ /_/_/  /_/____/\\ \\__,_/\\___/_/ /_/_/  /_/____(_)__,_/_/\\_\\  \n                        \\____/                                      ")
end


return function()
    logoTag()
    local targetGroup = text('Which Group to create layout for', 'Enter group #')
    if targetGroup ~= 'Enter group #' then
        -- local targetLayout = text('Which Layout to store in?','Enter Layout #')
        local targetLayout = 22
        -- frontView = gma.gui.confirm('BAD ASS Layouts!!!', 'Click OK for Front view. Cancel for TOP view.')
        if frontView == nil then
            topView = true
        end
        if frontView then
            topView = false
        end
        local grouphandle = gma.show.getobj.handle("Group " .. targetGroup)
        nogroup = gma.show.getobj.class(grouphandle)
        if nogroup ~= nil then
            feed(targetGroup .. " to layout " .. targetLayout)
            createLayout(targetGroup, targetLayout)
        else
            gma.gui.msgbox("BADASS LAYOUTS", "No group " .. group)
        end
    else
        gma.gui.msgbox('Error', 'Invalid group')
    end
end
