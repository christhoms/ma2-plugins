-- Chris.UK FancyCloner v0.1 7/6/23
-- Clones one group to another group, while duplicating FX objects and taking FX selection


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



function getTC(tcNum)
    gma.cmd("SelectDrive 1") -- select the internal drive
    local file = {}
    file.name = "tempfile.xml"
    file.directory = gma.show.getvar("PATH") .. "/" .. "importexport" .. "/"
    file.fullpath = file.directory .. file.name
    gma.cmd("Export Timecode " .. tcNum .. ' "' .. file.name .. '" /o') -- create temporary file
    local t = {} -- convert XML file into a table
    for line in io.lines(file.fullpath) do
        t[#t + 1] = line
    end
    os.remove(file.fullpath) -- delete temporary file
    local trackList = {}
    for i = 1, #t do
        if t[i]:find("Object name=\"") then
            -- Get Exec Page
            local execPage = string.match(t[i+3],"<No>(%d+)</No>")
            local execID = string.match(t[i+4], "<No>(%d+)</No>")
            -- append to list
            trackList[#trackList + 1] = execPage .. "." .. execID-- extract the number to the group list
        end
    end
    return trackList
end

function getSeqNum(execNum)
    gma.cmd("SelectDrive 1") -- select the internal drive
    local file = {}
    file.name = "tempfile.xml"
    file.directory = gma.show.getvar("PATH") .. "/" .. "importexport" .. "/"
    file.fullpath = file.directory .. file.name
    gma.cmd("Export Executor " .. execNum .. ' "' .. file.name .. '" /o') -- create temporary file
    local t = {} -- convert XML file into a table
    for line in io.lines(file.fullpath) do
        t[#t + 1] = line
    end
    os.remove(file.fullpath) -- delete temporary file
    local seqNum
    for i = 1, #t do
        if t[i]:find("Assignment name=\"") then
            -- Get Sequence Number
            seqNum = string.match(t[i+3],"<No>(%d+)</No>")
        end
    end
    return seqNum
end

function getSeqEffects(seqNum)
    gma.cmd("SelectDrive 1") -- select the internal drive
    local file = {}
    file.name = "tempfile.xml"
    file.directory = gma.show.getvar("PATH") .. "/" .. "importexport" .. "/"
    file.fullpath = file.directory .. file.name
    gma.cmd("Export Sequence " .. seqNum .. ' "' .. file.name .. '" /o') -- create temporary file
    local t = {} -- convert XML file into a table
    for line in io.lines(file.fullpath) do
        t[#t + 1] = line
    end
    os.remove(file.fullpath) -- delete temporary file
    local effectIDs = {}
    local progress_h = gma.gui.progress.start('Processing Sequence ' .. seqNum)
    gma.gui.progress.setrange(progress_h, 0, #t)
    for i = 1, #t do
        if t[i]:find("Effect name=\"") then
            -- Get Exec Page
            local effectID = string.match(t[i+2],"<No>(%d+)</No>")
            -- check if exists
            -- append to list
            effectIDs[effectID] = 1 -- extract the number to the list, add as index to avoid duplicates
        end
        gma.gui.progress.set(progress_h, i)
    end
    gma.gui.progress.stop(progress_h)
    local returnFX = {}
    for k,_ in pairs(effectIDs) do
        returnFX[#returnFX + 1] = k
      end
    return returnFX
end


function GetGroup(grpNum)
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
    local groupList = {}
    for i = 1, #t do
        if t[i]:find("Subfixture ") then
            local indices = {t[i]:find('"%d+"')}
            indices[1], indices[2] = indices[1] + 1, indices[2] - 1
            local fixture
            if t[i]:find("fix_id") then
                fixture = "Fixture " .. tostring(t[i]:sub(indices[1], indices[2]))
            elseif t[i]:find("cha_id") then
                fixture = "Channel " .. tostring(t[i]:sub(indices[1], indices[2]))
            end
            if t[i]:find("sub_index") then
                local indices = {t[i]:find('"%d+"', indices[2] + 2)}
                indices[1], indices[2] = indices[1] + 1, indices[2] - 1
                fixture = fixture .. "." .. tostring(t[i]:sub(unpack(indices)))
            end
            groupList[#groupList + 1] = fixture
        end
    end
    return groupList
end

--[[
function checkFXgroup(groupFixtures, effectNum)
    feed (#groupFixtures .. " fixtures passed to function")
    local result = true
    gma.cmd("SelectDrive 1") -- select the internal drive
    local file = {}
    file.name = "tempfile.xml"
    file.directory = gma.show.getvar("PATH") .. "/" .. "effects" .. "/"
    file.fullpath = file.directory .. file.name
    gma.cmd("Export Effect " .. effectNum .. ' "' .. file.name .. '" /o') -- create temporary file

    local t = {} -- convert XML file into a table
    for line in io.lines(file.fullpath) do
        t[#t + 1] = line
    end
    --os.remove(file.fullpath) -- delete temporary file
    local fxFixtures = {}
    local checkFixtures = {}
    
    for i = 1, #groupFixtures do

    end

    feed("Received " .. #checkFixtures .. " fixtures to check against")
    for i = 1, #t do
        if t[i]:find("<Fixture>") then
            local fixID = tonumber(string.match(t[i],"<Fixture>(%d*%.?%d+):?</Fixture>"))
            --feed ("Fixture ID: " .. fixID)
            --does it exist in groupFixtures?
            if not checkFixtures[fixID] then
                result = false
                feed("Fixture " .. fixID .. " not present in group")
            end
        end
    end
    return result
end
]]

local getHandle = gma.show.getobj.handle
function getClass(str)
    return gma.show.getobj.class(getHandle(str))
end

function checkSpace(poolType, start, length) --checks if range of pool spaces is empty
    local finish = start + length - 1 --set our finishing point
    local emptyStatus = true
    --feed("Checking for type: " .. poolType)
    --feed("Start ID: " .. start)
    --feed("finish ID: " .. finish)
    for i = start, finish do
        --feed ("Getting class for : " ..poolType..' '.. tostring(math.floor(i)))
      if getClass(poolType..' '..tostring(math.floor(i))) then --if space is not empty
        emptyStatus = false
        break
      end
    end
    return emptyStatus
  end

  
function advanceSpace(poolType, start, length)
local finalStart = start
while checkSpace(poolType, finalStart, length) == false do
    finalStart = finalStart + 1
end  
return math.floor(finalStart)
end




return function ()
    local cloneGroup = text("Which group to clone?", "#")
    local groupFixtures = getGroup(cloneGroup)
    feed (#groupFixtures .. " fixtures in group " .. cloneGroup)
    local destGroup = text("Destination Group?", "#")
    local firstTCObject = text("First Timecode Pool #","#")
    local lastTCObject = text("Last Timecode Pool #","#")
    local fxStart = text("Where to place new FX #", "#")
    local oldPrefix = text("Old FX Prefix?", "led1")
    local newPrefix = text("New FX Prefix?", "tempclone")


    local thisTC = tonumber(firstTCObject)
   
    local destFX = tonumber (fxStart)
    local numSongs = tonumber(lastTCObject) - tonumber(firstTCObject)
    local progress_h1 = gma.gui.progress.start('Processing TC Songs')
    gma.gui.progress.setrange(progress_h1, 0, numSongs)
    local thisSong = 1
    local copiedFX = {}
    while thisTC <= tonumber(lastTCObject) do
        -- Export Timecode to XML and find sequences used in tracks
        local tcTracks = getTC(thisTC)
        gma.gui.progress.set(progress_h1, thisSong) 
        local sequenceList = {}
        local progress_h = gma.gui.progress.start('Processing TC Tracks')
        gma.gui.progress.setrange(progress_h, 0, #tcTracks)
        
        for i = 1, #tcTracks, 1 do
            gma.gui.progress.set(progress_h, i) 
            local seqNum = getSeqNum(tcTracks[i])
            sequenceList[#sequenceList + 1] = seqNum
            -- Export sequence to XML and find FX used in sequence
            feed("Sequence: " .. seqNum)
            local seqEffects = getSeqEffects(seqNum)
            feed (#seqEffects .. " FX Found in sequence")
            

            local totalEffects = {}
            for e = 1, #seqEffects, 1 do
                local effectID = seqEffects[e]
                feed("FX: " .. effectID)
                totalEffects[effectID] = 1
            end

            gma.gui.progress.stop(progress_h)

            local allFX = {}
            for k,_ in pairs(totalEffects) do
                allFX[#allFX + 1] = k
            end

            local newFX = {}
            -- check FX to see if they contain source fixtures
            for i = 1, #allFX, 1 do
                local thisEffect = tonumber(allFX[i])
                feed ("Checking FX: " .. thisEffect)
                local thisLabel = property(o("Effect " .. thisEffect), 1)
                feed ("Label: " .. thisLabel)
                local thisPrefix = string.match(thisLabel, "^(.-)_")

                if thisPrefix == oldPrefix then
                    -- these are the droids you are looking for
                    if copiedFX[thisEffect] then
                        feed("FX already exists, will not be copied but will be updated")
                    else
                        newFX[thisEffect] = destFX
                        copiedFX[thisEffect] = destFX
                        destFX = destFX + 1    
                    end
                    
                    feed("Matched prefix")
                else 
                    --feed ("")
                end
            end

            
            for k,v in pairs(newFX) do
                -- if FX are relevant, maka a new label and copy FX to new piece of FX land
                cmd("Copy Effect " .. k .. " at " .. v )
                local label = property(o("Effect " .. k), 1)
                local newLabel = string.gsub(label, "^(.-)_", newPrefix .. "_")
                cmd("Label Effect " .. v .. " \"" .. newLabel .. "\"")
            end

            
            -- Take FX Selection on newFX
            cmd("BlindEdit On")
            cmd("Group " .. destGroup)
            cmd("Store Effect 1.\"" .. newPrefix .. "_*\".* /o")

            -- Clone source group at dest group if sequence.
            cmd("Clone group " .. cloneGroup .. " at " .. destGroup .. " if Sequence " .. seqNum .. " /lm /nc")
        
            cmd("Delete World 999")
            cmd("Group " .. destGroup)
            cmd("Store World 999 /o")
            -- World to dest group only
            cmd("World 999")
            -- replace source FX at DestFX if sequence
            for k,v in pairs(copiedFX) do
                cmd("Replace Effect " .. k .. " with " .. v .. " if Sequence " .. seqNum .. " /nc")
            end
            -- leave / delete world
            cmd ("World 1")
            cmd ("Delete World 999")
            cmd ("BlindEdit Off")
        end -- end of this TC Track, move on to next seq
            
            thisTC = thisTC + 1
            thisSong = thisSong + 1
    end
    gma.gui.progress.stop(progress_h1)
end