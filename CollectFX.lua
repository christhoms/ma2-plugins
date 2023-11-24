local staticFX = {} 
-- never move/copy these FX
staticFX[385] = 1
staticFX[386] = 1
staticFX[387] = 1
staticFX[388] = 1

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
    
    local TCObject = text("Timecode Pool #","#")
    local fxStart = text("FXStart #", "#")
    
    -- Export Timecode to XML and find sequences used in tracks
    local tcTracks = getTC(TCObject)
    local totalEffects = {}
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

        for e = 1, #seqEffects, 1 do
            local effectID = seqEffects[e]
            feed("FX: " .. effectID)
            totalEffects[effectID] = 1
        end
        -- Check if FX are already within the FX Range or need moving
        -- Copy FX to new location, update sequence to reference new FX
    end
    gma.gui.progress.stop(progress_h)

    local allFX = {}
    for k,_ in pairs(totalEffects) do
        allFX[#allFX + 1] = k
    end
    

    feed (#allFX .. " effects found in all sequences")
    local fxEnd = tonumber(fxStart) + #allFX

    local fxToMove = {}
    for i = 1, #allFX, 1 do
        local thisEffect = tonumber(allFX[i])
        if thisEffect < tonumber(fxStart) or thisEffect > fxEnd then
            if not staticFX[thisEffect] then --check it's not a stomp
            fxToMove[#fxToMove + 1] = thisEffect
            end
        else 
            feed ("Effect: " .. thisEffect .. " is already in the specified range")
        end
    end
    fxEnd = tonumber(fxStart) + #fxToMove
    feed (#fxToMove .. " FX will need to be copied")
    feed ("Looking for FX space between " .. fxStart .. " and " .. fxEnd)
    -- Check for available space in FX range
    if (checkSpace("Effect", fxStart, #allFX)) == true then
        feed("Plenty of space for FX")
        local proceed = gma.gui.confirm("Proceed?","Will copy " .. #fxToMove .. " effects, OK to proceed?")
        if proceed then
            local seqString = table.concat(sequenceList, " + ")           
            for i = 1, #fxToMove, 1 do
                local newFX = tonumber(fxStart) + i
            cmd("Copy Effect " .. fxToMove[i] .. " At " .. newFX)
            cmd("Replace Effect " .. fxToMove[i] .. " With " .. newFX .. " If Sequence " .. seqString .. " /nc")
            end
        else
            feed ("quitting")
        end
    else
        feed("Not Enough space for all FX")
        local nextSpace = advanceSpace("Effect", fxStart, #fxToMove)
        feed("First available space is at: " .. nextSpace)
        local proceed = gma.gui.confirm("Proceed?", "OK to put ALL fx in first available space (" .. nextSpace .. ")\nCancel to make space manually.\nYou will need " .. #fxToMove .. " slots")
        
        if proceed then
            local seqString = table.concat(sequenceList, " + ")
            for i = 1, #fxToMove, 1 do
                local newFX = nextSpace + i
            cmd("Copy Effect " .. fxToMove[i] .. " At " .. newFX)
            cmd("Replace Effect " .. fxToMove[i] .. " With " .. newFX .. " If Sequence " .. seqString .. " /nc")
            end
        else
            feed ("quitting")
        end
    end

end