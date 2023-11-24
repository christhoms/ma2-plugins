function deleteTimeTC(tcNum, timeToDelete, editPoint, destTC)

    gma.cmd("SelectDrive 1")
    local file = {}
    file.name = 'tempfile.xml'
    file.directory = gma.show.getvar('PATH') .. '/' .. 'importexport' .. '/'
    file.fullpath = file.directory .. file.name

    gma.cmd('Export Timecode ' .. tcNum .. ' \"' .. file.name .. '\"') -- create temporary file
    local t = {} -- convert XML file into a table
    for line in io.lines(file.fullpath) do
        t[#t + 1] = line
    end
    os.remove(file.fullpath) -- delete temporary file
    
    
    local m = {}
    local eIndex = 0
    local modifiedIndex = false
    local deleteThisItem = false
    local isEvent = false
    
    editPoint = tonumber(editPoint)
    timeToDelete = tonumber(timeToDelete)
    local endOfEdit = editPoint + timeToDelete

    for i = 1, #t do
        
        if t[i]:find('SubTrack index="%d+"') then
            _, _, index = t[i]:find('index="(%d+)"')
            gma.echo("Found SubTrack Index: " ..  index)
            -- New SubTrack
            eIndex = 0
            modifiedIndex = false
            deleteThisItem = false
        end

        
        if t[i]:find('index="%d+" time="%d+"') then
            isEvent = true
            _, _, index, time = t[i]:find('index="(%d+)" time="(%d+)"')
            gma.echo("Found time on line: " .. i)
            time = tonumber(time)
            if time > editPoint then
                if time < endOfEdit then
                    modifiedIndex = true
                    deleteThisItem = true
                    gma.echo("Event: " .. index .. " has time of: " .. time .. " and is within edit range, deleting whole event")
                else
                    deleteThisItem = false
                    adjTime = time - timeToDelete
                    gma.echo ("Event: " .. index .. " moves from " .. time .. " to " .. adjTime)    
                end
            else --leave this event alone
                isEvent = false
            end
        end
        if isEvent == false then
            m[#m + 1] = t[i]
        else
            if (deleteThisItem == false) then
                if modifiedIndex == true then
                    adjIndex = eIndex
                    eIndex = eIndex + 1
                    gma.echo("Adjusting Index to: " .. adjIndex)
                else 
                    adjIndex = index
                    gma.echo("Index did not change: " .. adjIndex)
                end
                newline = t[i]:gsub('index="%d+" time="(%d+)"','index="' .. adjIndex .. '" time="' .. adjTime .. '"')
                gma.echo("Writing new line")
                m[#m + 1] = newline
            end
        end
        --handle single line events
        if isEvent == true and t[i]:find('/>') then isEvent = false end
        --look for closing event tag
        if t[i]:find('</Event>') then isEvent = false end
        end
    
    
    local newtimecode = {}
    newtimecode.name = 'tempfile_createtimecode'
    newtimecode.directory = gma.show.getvar('PATH')..'/importexport/'
    newtimecode.fullpathXML = newtimecode.directory..newtimecode.name..'.xml'
    -- Write XML file to disk --
    local fileXML = assert(io.open(newtimecode.fullpathXML, 'w'))  
    for i = 1, #m do
        fileXML:write(m[i] .. "\n")
    end
    
    fileXML:close()
    gma.cmd('Import \"'..newtimecode.name..'.xml'..'\" at Timecode '..tostring(destTC)..' /nc') 

    os.remove(newtimecode.fullpathXML)
end




return function()
    inputTC = gma.textinput("Which Timecode?","Input Timecode #")
    timeToDelete = gma.textinput ("Subtract x frames from Timecode","0")
    editPoint = gma.textinput ("Frame to delete from", "0")

    --timeFromEnd = gma.textinput ("Subtract x frames from end","0")
    destTC = gma.textinput("Output Timecode","Choose a Timecode to save to")
    deleteTimeTC(inputTC, timeToDelete, editPoint, destTC)
end