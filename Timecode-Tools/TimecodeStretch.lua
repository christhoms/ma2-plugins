function stretchTimecode(tcNum, startBPM, destBPM, destTC)
    
    local factor = tonumber(startBPM) / tonumber(destBPM)
    gma.echo ("Start BPM: " .. startBPM .. " Dest BPM: " .. destBPM)
    gma.echo ("Stretch factor of: " .. factor)
    
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
    local newtimecode = {}
    newtimecode.name = 'tempfile_createtimecode'
    newtimecode.directory = gma.show.getvar('PATH')..'/importexport/'
    newtimecode.fullpathXML = newtimecode.directory..newtimecode.name..'.xml'
    -- Write XML file to disk --
    local fileXML = assert(io.open(newtimecode.fullpathXML, 'w'))  
    for i = 1, #t do
        if t[i]:find('index="%d+" time="%d+"') then
            _, _, index, time = t[i]:find('index="(%d+)" time="(%d+)"')
            --gma.echo("Found time on line: " .. i)
            adjTime = math.floor(tonumber(time) * factor)
            --gma.echo('TC: ' .. time .. " becomes: " .. adjTime)
            newline = t[i]:gsub('time="(%d+)"','time="' .. adjTime .. '"')
            t[i] = newline
        end
        fileXML:write(t[i] .. "\n")
    end
    
    fileXML:close()
    gma.cmd('Import \"'..newtimecode.name..'.xml'..'\" at Timecode '..tostring(destTC)..' /nc') --load new layout into showfile

    os.remove(newtimecode.fullpathXML)
end

return function()
        inputTC = gma.textinput("Which Timecode?","Input Timecode #")
        startBPM = gma.textinput ("Start BPM?","126")
        destBPM = gma.textinput("Final BPM", "128")
        destTC = gma.textinput("Output Timecode","Choose a Timecode to save to")
        stretchTimecode(inputTC, startBPM, destBPM, destTC)
end
