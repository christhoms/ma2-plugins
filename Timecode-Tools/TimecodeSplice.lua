-- helper function to parse the XML data of a timecode and return a table representation of the timecode
    function parseTimecode(tc)
        local file = {}
        file.name = 'tempfile.xml'
        file.directory = gma.show.getvar('PATH') .. '/' .. 'importexport' .. '/'
        file.fullpath = file.directory .. file.name
    
        gma.cmd('Export Timecode ' .. tc .. ' \"' .. file.name .. '\"') -- create temporary file
    
        local t = {} -- convert XML file into a table
        for line in io.lines(file.fullpath) do
            t[#t + 1] = line
        end
        os.remove(file.fullpath) -- delete temporary file
    
        return t
    end
    
    -- helper function to find the highest Track index in timecode XML
    function findSpliceIndex(tc)
        local spliceIndex = 1
        for i = 1, #tc do
            if tc[i]:find('<Track ') then
                spliceIndex = i
            end
        end
        -- should return number of "Track" items found
        return spliceIndex
    end
    
    -- helper function to adjust the time values of all events in a timecode by a given offset
    function adjustTimecodes(tc, startIndex, offset)
        for i = 1, #tc do
            if tc[i]:find('<Event') then
                local timeStr = tc[i]:match('time="(.-)"')
                if timeStr then
                    local time = tonumber(timeStr)
                    time = time + offset
                    tc[i] = tc[i]:gsub('time=".-"', 'time="' .. time .. '"')
                end
            elseif tc[i]:find('<Track ') then
                local indexStr = tc[i]:match('index="(.-)"')
                if indexStr then
                    local newIndex = tonumber(indexStr)
                    newIndex = newIndex + startIndex
                    tc[i] = tc[i]:gsub('index=".-"', 'index="' .. newIndex .. '"')
                end
            end
        end
    end
    
    -- helper function to merge the tracks of the second timecode into the first timecode at the given splice index
        function mergeTimecodes(tc1, tc2)
            local t = tc1
            local spliceIndex = #tc1 - 1
            local include = false
            local l = 0
            for i = 1, #tc2 - 1 do -- start at 2 to skip <Timecode> and end at -1 to skip </Timecode>
                if (tc2[i]:find("<Track ")) then
                    include = true
                end
                if (tc2[i]:find("</Timecode>")) then
                    include = false
                end

                if include == true then
                    table.insert(t, spliceIndex + l, tc2[i])
                    l = l + 1
                end
            end
            return t
        end

    -- helper function to create a new timecode XML file from the merged timecode table and import it as a new timecode
function createNewTimecodeXML(tc, destTC)
    local tcName = 'tempfile_createtimecode'
    local tcDir = gma.show.getvar('PATH') .. '/importexport/'
    local tcPath = tcDir .. tcName .. '.xml'

    -- Write merged timecode table to disk as XML file
    local file = assert(io.open(tcPath, 'w'))
    for i = 1, #tc do
        file:write(tc[i] .. '\n')
    end
    -- Import the new timecode XML file
    gma.cmd('Import \"' .. tcName .. '.xml' .. '\" at Timecode ' .. tostring(destTC) .. ' /nc')
    os.remove(tcPath)
    file:close()
    -- Import the new timecode XML file
    gma.cmd('Import \"' .. tcName .. '.xml' .. '\" at Timecode ' .. tostring(destTC) .. ' /nc')
    os.remove(tcPath)
end


function SpliceTC(firstTC, secondTC, splicePoint, spliceOffset, destTC)
    gma.cmd("SelectDrive 1")
    -- call the helper functions to splice the timecode objects
    local tc1 = parseTimecode(firstTC)
    local tc2 = parseTimecode(secondTC)
    local spliceIndex = findSpliceIndex(tc1)
    adjustTimecodes(tc2, spliceIndex, (splicePoint - spliceOffset))
    createNewTimecodeXML(mergeTimecodes(tc1, tc2), destTC)
end

return function()
    local firstTC = gma.textinput("First Timecode?","Input Timecode #")
    local secondTC = gma.textinput("Second Timecode?", "Input Timecode #")
    local splicePoint = gma.textinput("Splice Point (Frames)", "0")
    local spliceOffset = gma.textinput("Splice Offset in Timecode #2", "0")
    local destTC = gma.textinput("Output Timecode","Choose a Timecode to save to")
    SpliceTC(firstTC, secondTC, splicePoint, spliceOffset, destTC)
end