--Mighty Flippa v1.0



-- Choose a group and world number here that will be way clear of anything you use in your programming, it will be overwritten and deleted after this runs
local tempGroup = 2999
local tempWorld = 999

local text = gma.textinput
local feed = gma.feedback
local cmd = gma.cmd
local o = gma.show.getobj.handle
local a = gma.show.getobj
local property = gma.show.property.get
local sub = string.sub
local unpack = table.unpack

function InstanceType(fixtureObject, subFixtureID)
    local fixtureTypeString = property(fixtureObject, 3)
    local fixtureTypeNum = fixtureTypeString:sub(0, fixtureTypeString:find("%s+"))
    local instanceHandle = o("FixtureType " .. fixtureTypeNum .. ".2." .. subFixtureID)
    local typeName = property(instanceHandle, 1)
    -- feed("Subfix: " .. subFixtureID .. " has type:" .. typeName)
    return typeName
end

function getGroup(grpNum)
    gma.cmd("SelectDrive 1") -- select the internal drive
    local file = {}
    file.name = "tempfile.xml"
    file.directory = gma.show.getvar("PATH") .. "/" .. "importexport" .. "/"
    file.fullpath = file.directory .. file.name
    gma.cmd("Export Group " .. grpNum .. ' "' .. file.name .. '" /o') -- create temporary file
    local t = {} -- convert XML file into a table
    for line in io.lines(file.fullpath) do
        t[#t + 1] = line
    end
    os.remove(file.fullpath) -- delete temporary file
    local groupList = {} -- declare groupList
    for i = 1, #t do
        if t[i]:find("Subfixture ") then
            local indices = {t[i]:find('"%d+"')} -- find points of quotation marks
            indices[1], indices[2] = indices[1] + 1, indices[2] - 1 -- move reference points to first an last characters inside those marks
            -- label based on status as a fixture or as a channel
            local fixture
            if t[i]:find("fix_id") then
                fixture = "Fixture " .. tostring(t[i]:sub(indices[1], indices[2])) -- extract the number as the fixture number
            elseif t[i]:find("cha_id") then
                fixture = "Channel " .. tostring(t[i]:sub(indices[1], indices[2]))
            end -- extract the number as the fixture number
            -- if the object contains a subfixture...
            if t[i]:find("sub_index") then
                local indices = {t[i]:find('"%d+"', indices[2] + 2)}
                indices[1], indices[2] = indices[1] + 1, indices[2] - 1
                fixture = fixture .. "." .. tostring(t[i]:sub(unpack(indices)))
            end
            -- append to list
            groupList[#groupList + 1] = fixture -- extract the number to the group list
        end
    end
    return groupList
end

function logoTag()
    feed(
        "\n        __         _      ______       __         _             __  \n  _____/ /_  _____(_)____/ ____ \\_____/ /_  _____(_)____ __  __/ /__\n / ___/ __ \\/ ___/ / ___/ / __ `/ ___/ __ \\/ ___/ / ___// / / / //_/\n/ /__/ / / / /  / (__  ) / /_/ / /__/ / / / /  / (__  )/ /_/ / ,<   \n\\___/_/ /_/_/  /_/____/\\ \\__,_/\\___/_/ /_/_/  /_/____(_)__,_/_/\\_\\  \n                        \\____/                                      "
    )
end

function invertInstances(fixtureID, startInstance, lastInstance)
    local firstSubFixture = (fixtureID .. "." .. startInstance)
    local firstSubFixturePatch = property(o("Fixture " .. firstSubFixture), "patch")
    local firstSubFixturePatchAddress = sub(firstSubFixturePatch, -3)
    local instances = a.amount(o("Fixture " .. fixtureID))
    local lastSubFixture = (fixtureID .. "." .. lastInstance)
    local lastSubfixturePatch = property(o("Fixture " .. lastSubFixture), "patch")
    local lastSubfixturePatchAddress = sub(lastSubfixturePatch, -3)
    feed(
        "Start Instance: " ..
            firstSubFixture .. " At Address " .. firstSubFixturePatch .. " with " .. instances .. " Instances"
    )
    feed("End Instance: " .. lastSubFixture .. " At Address " .. lastSubfixturePatch)
    if firstSubFixturePatchAddress > lastSubfixturePatchAddress then
        do
            cmd("Delete Fixture " .. lastSubFixture .. " Thru " .. firstSubFixture .. "/nc")
            cmd(
                "Assign Fixture " ..
                    firstSubFixture .. " Thru " .. lastSubFixture .. " At DMX " .. lastSubfixturePatch .. "/nc"
            )
        end
    else
        cmd("Delete Fixture " .. firstSubFixture .. " Thru " .. lastSubFixture .. "/nc")
        cmd(
            "Assign Fixture " ..
                lastSubFixture .. " Thru " .. firstSubFixture .. " At DMX " .. firstSubFixturePatch .. "/nc"
        )
    end
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function keysOfSet(set)
    local ret = {}
    for k, _ in pairs(set) do
        ret[#ret + 1] = k
    end
    return ret
end

return function()
    cmd("Delete World " .. tempWorld .. "; Store World " .. tempWorld .. ";BlindEdit On; Fixture Thru")
    cmd("Store Group " .. tempGroup .. " /o /nc")
    local groupList = getGroup(tempGroup)
    cmd("World 1; Delete World " .. tempWorld .. "; BlindEdit Off; Delete Group " .. tempGroup)
    local fixtureList = {}
    local instanceList = {}

    feed("-----")
    if #groupList == 0 then
        gma.gui.msgbox(
            "ERROR: NO FIXTURES SELECTED",
            "Select some CELLS and try again. Only Select cells you want FLIPPED!"
        )
    else
        local instanceCount = 0

        -- gma.gui.progress.stop(pbar) -- for testing
        if groupList[1]:find("%.") == nil then
            gma.gui.msgbox("ERROR", "Single Instance Fixture\n\nNothing to do here!")
        else
            local pbar = gma.gui.progress.start("Flipper")
            lastPbarHandle = pbar
            gma.gui.progress.settext(pbar, "Processing Fixtures")
            gma.gui.progress.setrange(pbar, 1, #groupList)
            local splitPoint = {groupList[1]:find(" "), groupList[1]:find("%.")}
            local mainFix = tonumber(groupList[1]:sub(splitPoint[1] + 1, splitPoint[2] - 1))
            local subFix = tonumber(groupList[1]:sub(splitPoint[2] + 1))
            local firstInstanceType = InstanceType(o("Fixture " .. mainFix), subFix)
            local lastInstanceType
            local error = false
            for i = 1, #groupList, 1 do
                gma.gui.progress.set(pbar, i)
                splitPoint = {groupList[i]:find(" "), groupList[i]:find("%.")}
                mainFix = tonumber(groupList[i]:sub(splitPoint[1] + 1, splitPoint[2] - 1))
                subFix = tonumber(groupList[i]:sub(splitPoint[2] + 1))
                local thisInstanceType = InstanceType(o("Fixture " .. mainFix), subFix)
                lastInstanceType = thisInstanceType
                if thisInstanceType ~= firstInstanceType then
                    feed("Error: instance type mismatch: " .. firstInstanceType .. " / " .. thisInstanceType)
                    error = true
                    break
                else
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
                end
            end
            gma.gui.progress.stop(pbar)
            if error == true then
                gma.gui.msgbox(
                    "ERROR",
                    "Multiple types of instance selected\n\nYou don't want to do that, you weirdo\n\n[" ..
                        firstInstanceType .. "] / [" .. lastInstanceType .. "]"
                )
            else
                if
                    gma.gui.confirm(
                        "OK to proceed?",
                        "\n[" ..
                            #fixtureList ..
                                "] fixtures selected for invert with [" ..
                                    instanceCount ..
                                        "] total instances\n[" ..
                                            math.floor(instanceCount / #fixtureList) ..
                                                "] per fixture - does that look right?"
                    )
                 then
                    pbar = gma.gui.progress.start("Flipper")
                    lastPbarHandle = pbar
                    gma.gui.progress.settext(pbar, "Inverting Instances")
                    gma.gui.progress.setrange(pbar, 1, #fixtureList)
                    gma.gui.progress.set(pbar, 1)
                    for i = 1, #fixtureList, 1 do
                        gma.gui.progress.set(pbar, i)
                        feed(i .. ": " .. fixtureList[i])
                        local instances = keysOfSet(instanceList[fixtureList[i]])
                        local starti = math.min(unpack(instances))
                        local lasti = math.max(unpack(instances))
                        feed("First Instance: " .. starti .. " Last Instance: " .. lasti)
                        invertInstances(fixtureList[i], starti, lasti)
                    end
                    gma.gui.progress.stop(pbar)
                end
            end
        end
    end
    logoTag()
end
