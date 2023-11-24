-- MA2 Layout to Resolume Advanced Output v0.1
--9/11/23
-- IMPORTANT: for this to do anything you will need my Fixture files installed in you user's "Documents/Resolume Arena/Fixture Library" folder.
-- Get those HERE: https://www.dropbox.com/s/tqwoyabo3sfw47n/Unzip%20to%20Resolume%20Arena%20Fixture%20Library%20Folder.zip?dl=0
--


--CONFIG VARS
local askForResolution = false
local askForTarget = true
local defaultWidth = 1920
local defaultHeight = 1080
local scaleFactor = 10 -- make things bigger so pixel layout makes more sense




local fixtureTypes = {}
fixtureTypes['rgb'] = "8fe644dbf560463bbec9d377987249a1"
fixtureTypes['rgbw'] = "fa971f896dd24e2699f81ca7e80cd968"
fixtureTypes['cmy'] = "b74379fb2fa444e1a292380e80d8f9cb"
fixtureTypes['dim'] = "e30dccf73f3547258c9bdfcc5a3a5a08"
--




----
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
---

function encodeIP(ipAddress)
    -- Match each segment of the IP address
    local ipParts = {ipAddress:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}

    -- Calculate the decimal value
    local decimalIP = (tonumber(ipParts[4]) * 16777216) + (tonumber(ipParts[3]) * 65536) + (tonumber(ipParts[2]) * 256) + tonumber(ipParts[1])

    return "TT_IP\n" .. decimalIP
end



function processLayout(thisLayout, compWidth, compHeight, fixtureType)
    
    gma.cmd('SelectDrive 1') -- select the internal drive

    local file = {}
    file.name = 'tempfile.xml'
    file.directory = gma.show.getvar('PATH') .. '/' .. 'importexport' .. '/'
    file.fullpath = file.directory .. file.name
    gma.cmd('Export Layout ' .. thisLayout .. ' \"' .. file.name .. '\" /o') -- create temporary file

    local t = {} -- convert XML file into a table
    for line in io.lines(file.fullpath) do
        t[#t + 1] = line
    end
    os.remove(file.fullpath) -- delete temporary file

    local fixtureList = {}
    --create array of universes, each will need its own Lumiverse in Resolume
    local universeList = {}
    local universeIDs = {}
    -- get all pixels in layout. For each we will need: X Location, Y Location, Colour Type (RGB/RGBW/Dim), Patch / Universe
    for i=1, #t do
        local thisFixture = {}
        if t[i]:find('LayoutSubFix ') then
            thisFixture['x'], thisFixture['y'] = t[i]:match("center_x=\"*(.-)\" center_y=\"*(.-)\"")
            thisFixture['x'] = thisFixture['x'] * scaleFactor
            thisFixture['y'] = thisFixture['y'] * scaleFactor
            local mainFixture, subFixture = t[i+2]:match("fix_id=\"*(.-)\""),t[i+2]:match("sub_index=\"*(.-)\"")
            thisFixture['fixtureID'] = mainFixture ..".".. subFixture
            -- feed("Fixture: " ..thisFixture['fixtureID'])
            -- feed("X:" .. thisFixture['x'] .. " Y:" .. thisFixture['y'])
            local fixHandle = o("Fixture " .. thisFixture['fixtureID'])
            -- for p = 1, gma.show.property.amount(fixHandle) do
            --     feed("Property: " .. p .. ": " .. property(fixHandle, p))
            -- end
            local patch = property(fixHandle, 4)
            local universe = patch:match("(%d+).*")
            local patchAddress = patch:match("%.(%d+)")
            -- feed("Universe: " .. universe)
            -- feed("Patch: " .. patchAddress)
            thisFixture['universe'] = universe
            thisFixture['address'] = patchAddress
            thisFixture['patch'] = patch
            fixtureList[#fixtureList + 1] = thisFixture
            universeList[universe] = true
        end
    end




    

    --check for different types of Colour, should probably not cross the streams

    --Determine new X + Y Co-ordinates based on desired output resolution and pixel size

    --Generate Resolume XML and export
    local artnetTarget = "TT_BROADCAST"
    if askForTarget then
        local confirmTarget = gma.gui.confirm("Select Target","OK for Broadcast, Cancel to Enter IP")
        if  confirmTarget == nil then
            local targetIP = text("Artnet Target IP?", "2.0.0.1")
            feed("Encoding IP: " .. targetIP)
            artnetTarget = encodeIP(targetIP)
        end
    end

    local xmlText = [[<?xml version="1.0" encoding="utf-8"?>
<XmlState name="MA2 DMX Layout Output">
	<versionInfo name="Resolume Arena" majorVersion="6" minorVersion="1" microVersion="0" revision="1"/>
	<ScreenSetup name="ScreenSetup">
		<Params name="ScreenSetupParams"/>
		<CurrentCompositionTextureSize width="]] .. compWidth .. [[" height="]] .. compHeight .. [["/>
		<screens>
]]
local lumiverseCount = 1
local screenUniqueID = 1684059309218
local sliceUniqueID = 1684059309238
local lumiverseID = 6362816615335067648
local midX = math.floor(tonumber(compWidth) / 2)
local midY = math.floor(tonumber(compHeight) / 2)
local pixW = 1
local pixH = 1
    for k,v in pairs(universeList) do
        universeIDs[#universeIDs + 1] = k
    end
    table.sort(universeIDs, function(a, b) return a < b end)
    for i = 1, #universeIDs do
        local thisUniverse = universeIDs[i]
        feed("Building Lumiverse: " .. thisUniverse)
        local artSubnet = math.floor(tonumber(thisUniverse) / 16)
        local artUniverse = math.abs(math.floor((artSubnet - (tonumber(thisUniverse) / 16)) * 16)) - 1
         feed("Subnet: " .. artSubnet)
         feed("Uni: " .. artUniverse)
        xmlText = xmlText .. "<DmxScreen name=\"Lumiverse " .. lumiverseCount .."\" uniqueId=\"" .. screenUniqueID .. "\" LumiverseId=\"" .. lumiverseCount - 1 .. "\">\n"
        xmlText = xmlText .. [[
            <Params name="Params">
            <Param name="Name" T="STRING" default="" value="Lumiverse ]] .. lumiverseCount .. [[ - Subnet: ]] .. artSubnet .. [[ Universe: ]] .. artUniverse .. [["/>
            <Param name="Enabled" T="BOOL" default="1" value="1"/>
            <Param name="Hidden" T="BOOL" default="0" value="0"/>
            <Param name="Auto Span" T="BOOL" default="1" value="1"/>
            <Param name="Align Output" T="BOOL" default="1" value="1"/>
        </Params>
        <Params name="Output">
            <ParamRange name="Opacity" T="DOUBLE" default="1" value="1">
                <PhaseSourceStatic name="PhaseSourceStatic" phase="1"/>
                <BehaviourDouble name="BehaviourDouble"/>
                <ValueRange name="defaultRange" min="0" max="1"/>
                <ValueRange name="minMax" min="0" max="1"/>
                <ValueRange name="startStop" min="0" max="1"/>
            </ParamRange>
            <ParamRange name="Brightness" T="DOUBLE" default="0" value="0">
                <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                <BehaviourDouble name="BehaviourDouble"/>
                <ValueRange name="defaultRange" min="-1" max="1"/>
                <ValueRange name="minMax" min="-1" max="1"/>
                <ValueRange name="startStop" min="-1" max="1"/>
            </ParamRange>
            <ParamRange name="Contrast" T="DOUBLE" default="0" value="0">
                <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                <BehaviourDouble name="BehaviourDouble"/>
                <ValueRange name="defaultRange" min="-1" max="1"/>
                <ValueRange name="minMax" min="-1" max="1"/>
                <ValueRange name="startStop" min="-1" max="1"/>
            </ParamRange>
            <ParamRange name="Red" T="DOUBLE" default="0" value="0">
                <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                <BehaviourDouble name="BehaviourDouble"/>
                <ValueRange name="defaultRange" min="-1" max="1"/>
                <ValueRange name="minMax" min="-1" max="1"/>
                <ValueRange name="startStop" min="-1" max="1"/>
            </ParamRange>
            <ParamRange name="Green" T="DOUBLE" default="0" value="0">
                <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                <BehaviourDouble name="BehaviourDouble"/>
                <ValueRange name="defaultRange" min="-1" max="1"/>
                <ValueRange name="minMax" min="-1" max="1"/>
                <ValueRange name="startStop" min="-1" max="1"/>
            </ParamRange>
            <ParamRange name="Blue" T="DOUBLE" default="0" value="0">
                <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                <BehaviourDouble name="BehaviourDouble"/>
                <ValueRange name="defaultRange" min="-1" max="1"/>
                <ValueRange name="minMax" min="-1" max="1"/>
                <ValueRange name="startStop" min="-1" max="1"/>
            </ParamRange>
        </Params>
        <guides>
            <ScreenGuide name="ScreenGuide" type="0">
                <Params name="Params">
                    <ParamPixels name="Image"/>
                    <ParamRange name="Opacity" T="DOUBLE" default="0.25" value="0.25">
                        <PhaseSourceStatic name="PhaseSourceStatic" phase="0.25"/>
                        <BehaviourDouble name="BehaviourDouble"/>
                        <ValueRange name="defaultRange" min="0" max="1"/>
                        <ValueRange name="minMax" min="0" max="1"/>
                        <ValueRange name="startStop" min="0" max="1"/>
                    </ParamRange>
                </Params>
            </ScreenGuide>
            <ScreenGuide name="ScreenGuide" type="1">
                <Params name="Params">
                    <ParamPixels name="Image"/>
                    <ParamRange name="Opacity" T="DOUBLE" default="0.25" value="0.25">
                        <PhaseSourceStatic name="PhaseSourceStatic" phase="0.25"/>
                        <BehaviourDouble name="BehaviourDouble"/>
                        <ValueRange name="defaultRange" min="0" max="1"/>
                        <ValueRange name="minMax" min="0" max="1"/>
                        <ValueRange name="startStop" min="0" max="1"/>
                    </ParamRange>
                </Params>
            </ScreenGuide>
        </guides>
        <layers>
        ]]
        for f=1, #fixtureList do
            if fixtureList[f]['universe'] == thisUniverse then
                feed("Inserting Fixture: " .. fixtureList[f]['fixtureID'])
                -- feed("Fixture Type is: " .. fixtureType)
                -- feed("Fixture ID:".. fixtureTypes[fixtureType])
                --insert fixture into layout
               xmlText = xmlText .. [[					<DmxSlice uniqueId="]] .. sliceUniqueID .. [[">
               <Params name="Common">
               <Param name="Name" T="STRING" default="Layer" value="1 RGB PIXEL"/>
               <Param name="Enabled" T="BOOL" default="1" value="1"/>
           </Params>
           <Params name="Input">
               <ParamChoice name="Input Source" default="0:1" value="0:1" storeChoices="0"/>
               <Param name="Input Opacity" T="BOOL" default="1" value="1"/>
               <Param name="Input Bypass/Solo" T="BOOL" default="1" value="1"/>
               <ParamChoice name="Fixture" T="STRING" default="" value="]] .. fixtureTypes[fixtureType] .. [[" storeChoices="0"/>
               <ParamRange name="Start Channel" T="DOUBLE" default="1" value="]] .. fixtureList[f]['address'] ..[[">
                   <PhaseSourceStatic name="PhaseSourceStatic" phase="0"/>
                   <BehaviourDouble name="BehaviourDouble"/>
                   <ValueRange name="defaultRange" min="1" max="131072"/>
                   <ValueRange name="minMax" min="1" max="131072"/>
                   <ValueRange name="startStop" min="1" max="131072"/>
               </ParamRange>
               <ParamChoice name="Filter Mode" T="INT32" default="0" value="0" storeChoices="0"/>
           </Params>
           <Params name="Output">
               <Param name="Flip" T="UINT8" default="0" value="0"/>
               <ParamRange name="Brightness" T="DOUBLE" default="0" value="0">
                   <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                   <BehaviourDouble name="BehaviourDouble"/>
                   <ValueRange name="defaultRange" min="-1" max="1"/>
                   <ValueRange name="minMax" min="-1" max="1"/>
                   <ValueRange name="startStop" min="-1" max="1"/>
               </ParamRange>
               <ParamRange name="Contrast" T="DOUBLE" default="0" value="0">
                   <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                   <BehaviourDouble name="BehaviourDouble"/>
                   <ValueRange name="defaultRange" min="-1" max="1"/>
                   <ValueRange name="minMax" min="-1" max="1"/>
                   <ValueRange name="startStop" min="-1" max="1"/>
               </ParamRange>
               <ParamRange name="Red" T="DOUBLE" default="0" value="0">
                   <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                   <BehaviourDouble name="BehaviourDouble"/>
                   <ValueRange name="defaultRange" min="-1" max="1"/>
                   <ValueRange name="minMax" min="-1" max="1"/>
                   <ValueRange name="startStop" min="-1" max="1"/>
               </ParamRange>
               <ParamRange name="Green" T="DOUBLE" default="0" value="0">
                   <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                   <BehaviourDouble name="BehaviourDouble"/>
                   <ValueRange name="defaultRange" min="-1" max="1"/>
                   <ValueRange name="minMax" min="-1" max="1"/>
                   <ValueRange name="startStop" min="-1" max="1"/>
               </ParamRange>
               <ParamRange name="Blue" T="DOUBLE" default="0" value="0">
                   <PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
                   <BehaviourDouble name="BehaviourDouble"/>
                   <ValueRange name="defaultRange" min="-1" max="1"/>
                   <ValueRange name="minMax" min="-1" max="1"/>
                   <ValueRange name="startStop" min="-1" max="1"/>
               </ParamRange>
           </Params>
           <InputRect orientation="0">
           <v x="]]
           -- top left co-ordinate
           .. midX + fixtureList[f]['x'] - (pixW / 2) .. [[" y="]]
           .. midY + fixtureList[f]['y'] - (pixH / 2) ..
           [["/>
           <v x="]]
           -- top right co-ordinate
           .. midX + fixtureList[f]['x'] + (pixW / 2) .. [[" y="]]
           .. midY + fixtureList[f]['y'] - (pixH / 2) ..
           [["/>          
           <v x="]]
           -- bottom right co-ordinate
           .. midX + fixtureList[f]['x'] + (pixW / 2) .. [[" y="]]
           .. midY + fixtureList[f]['y'] + (pixH / 2) ..
           [["/>
           
           <v x="]]
           -- bottom left co-ordinate
           .. midX + fixtureList[f]['x'] - (pixW / 2) .. [[" y="]]
           .. midY + fixtureList[f]['y'] + (pixH / 2) ..
           [["/>
           
       </InputRect>
       <OutputRect orientation="0">
           <v x="-0.5" y="-0.5"/>
           <v x="0.5" y="-0.5"/>
           <v x="0.5" y="0.5"/>
           <v x="-0.5" y="0.5"/>
       </OutputRect>
       <FixtureInstance name="FixtureInstance">
           <Fixture name="Fixture" uuid="82258f48831941208c885d302fd84131" fixtureName="">
               <Params name="Params">
                   <ParamFixturePixels storage="0" name="Pixels">
                       <ParamRange name="Width" T="DOUBLE" default="1" value="1">
                           <PhaseSourceStatic name="PhaseSourceStatic" phase="0"/>
                           <BehaviourDouble name="BehaviourDouble"/>
                           <ValueRange name="defaultRange" min="1" max="512"/>
                           <ValueRange name="minMax" min="1" max="512"/>
                           <ValueRange name="startStop" min="1" max="512"/>
                       </ParamRange>
                       <ParamRange name="Height" T="DOUBLE" default="1" value="1">
                           <PhaseSourceStatic name="PhaseSourceStatic" phase="0"/>
                           <BehaviourDouble name="BehaviourDouble"/>
                           <ValueRange name="defaultRange" min="1" max="512"/>
                           <ValueRange name="minMax" min="1" max="512"/>
                           <ValueRange name="startStop" min="1" max="512"/>
                       </ParamRange>
                       <ParamChoice name="Color Format" T="STRING" default="rgb" value="rgb" storeChoices="0"/>
                       <ParamChoice name="Distribution" T="INT32" default="170" value="170" storeChoices="0"/>
                       <ParamRange name="Gamma" T="DOUBLE" default="2.5" value="2.5">
                           <PhaseSourceStatic name="PhaseSourceStatic" phase="0.75"/>
                           <BehaviourDouble name="BehaviourDouble"/>
                           <ValueRange name="defaultRange" min="1" max="3"/>
                           <ValueRange name="minMax" min="1" max="3"/>
                           <ValueRange name="startStop" min="1" max="3"/>
                       </ParamRange>
                   </ParamFixturePixels>
               </Params>
           </Fixture>
            </FixtureInstance>
            </DmxSlice>
               ]]
               sliceUniqueID = sliceUniqueID + 1
            end
        end
        feed("Finished adding fixtures for universe: " .. thisUniverse)
        xmlText = xmlText .. [[
            </layers>
            <OutputDevice>
                <OutputDeviceDmx name="Lumiverse" deviceId="Lumiverse" idHash="]] .. lumiverseID .. [[">
                    <Params name="Params">
                        <ParamRange name="Framerate" T="DOUBLE" default="30" value="30">
                            <PhaseSourceStatic name="PhaseSourceStatic" phase="0.74358974358974361252"/>
                            <BehaviourDouble name="BehaviourDouble"/>
                            <ValueRange name="defaultRange" min="1" max="40"/>
                            <ValueRange name="minMax" min="1" max="40"/>
                            <ValueRange name="startStop" min="1" max="40"/>
                        </ParamRange>
                        <ParamRange name="Delay" T="DOUBLE" default="40" value="40">
                            <PhaseSourceStatic name="PhaseSourceStatic" phase="0.26666666666666666297"/>
                            <BehaviourDouble name="BehaviourDouble"/>
                            <ValueRange name="defaultRange" min="0" max="150"/>
                            <ValueRange name="minMax" min="0" max="150"/>
                            <ValueRange name="startStop" min="0" max="150"/>
                        </ParamRange>
                        <ParamChoice name="Dmx Interface" T="INT32" default="0" value="0" storeChoices="0"/>
                    </Params>
                    <DmxOutputParams name="Params">
                        <Param name="TargetIP" default="TT_DISABLED" value="]] .. artnetTarget .. [["/>
                        <ParamRange name="Subnet" T="DOUBLE" default="0" value="]] .. artSubnet ..[[">
                            <PhaseSourceStatic name="PhaseSourceStatic" phase="0"/>
                            <BehaviourDouble name="BehaviourDouble"/>
                            <ValueRange name="defaultRange" min="0" max="15"/>
                            <ValueRange name="minMax" min="0" max="15"/>
                            <ValueRange name="startStop" min="0" max="15"/>
                        </ParamRange>
                        <ParamRange name="Universe" T="DOUBLE" default="0" value="]] .. artUniverse .. [[">
                            <PhaseSourceStatic name="PhaseSourceStatic" phase="0"/>
                            <BehaviourDouble name="BehaviourDouble"/>
                            <ValueRange name="defaultRange" min="0" max="15"/>
                            <ValueRange name="minMax" min="0" max="15"/>
                            <ValueRange name="startStop" min="0" max="15"/>
                        </ParamRange>
                    </DmxOutputParams>
                </OutputDeviceDmx>
            </OutputDevice>
        </DmxScreen>
        ]]

        screenUniqueID = screenUniqueID + 1
        lumiverseID = lumiverseID + 1
        lumiverseCount = lumiverseCount + 1
    end
    xmlText = xmlText .. [[
		</screens>
		<SoftEdging>
			<Params name="Soft Edge">
				<ParamRange name="Gamma Red" T="DOUBLE" default="2" value="2">
					<PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
					<BehaviourDouble name="BehaviourDouble"/>
					<ValueRange name="defaultRange" min="1" max="3"/>
					<ValueRange name="minMax" min="1" max="3"/>
					<ValueRange name="startStop" min="1" max="3"/>
				</ParamRange>
				<ParamRange name="Gamma Green" T="DOUBLE" default="2" value="2">
					<PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
					<BehaviourDouble name="BehaviourDouble"/>
					<ValueRange name="defaultRange" min="1" max="3"/>
					<ValueRange name="minMax" min="1" max="3"/>
					<ValueRange name="startStop" min="1" max="3"/>
				</ParamRange>
				<ParamRange name="Gamma Blue" T="DOUBLE" default="2" value="2">
					<PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
					<BehaviourDouble name="BehaviourDouble"/>
					<ValueRange name="defaultRange" min="1" max="3"/>
					<ValueRange name="minMax" min="1" max="3"/>
					<ValueRange name="startStop" min="1" max="3"/>
				</ParamRange>
				<ParamRange name="Gamma" T="DOUBLE" default="1" value="1">
					<PhaseSourceStatic name="PhaseSourceStatic" phase="1"/>
					<BehaviourDouble name="BehaviourDouble"/>
					<ValueRange name="defaultRange" min="0" max="1"/>
					<ValueRange name="minMax" min="0" max="1"/>
					<ValueRange name="startStop" min="0" max="1"/>
				</ParamRange>
				<ParamRange name="Luminance" T="DOUBLE" default="0.5" value="0.5">
					<PhaseSourceStatic name="PhaseSourceStatic" phase="0.5"/>
					<BehaviourDouble name="BehaviourDouble"/>
					<ValueRange name="defaultRange" min="0" max="1"/>
					<ValueRange name="minMax" min="0" max="1"/>
					<ValueRange name="startStop" min="0" max="1"/>
				</ParamRange>
				<ParamRange name="Power" T="DOUBLE" default="2" value="2">
					<PhaseSourceStatic name="PhaseSourceStatic" phase="0.27536231884057965624"/>
					<BehaviourDouble name="BehaviourDouble"/>
					<ValueRange name="defaultRange" min="0.10000000000000000555" max="7"/>
					<ValueRange name="minMax" min="0.10000000000000000555" max="7"/>
					<ValueRange name="startStop" min="0.10000000000000000555" max="7"/>
				</ParamRange>
			</Params>
		</SoftEdging>
	</ScreenSetup>
</XmlState>
    ]]


                -- Write XML file to disk --
                local newlayout = {}
                newlayout.name = 'resolume_createlayout'
                if gma.show.getvar('HOSTSUBTYPE')=='onPC' then 
                    newlayout.directory = gma.show.getvar('PATH') .. '/importexport/'
                else     
                    local drivePaths = {
    
                        "/media/sdb1",
                        "/media/sdc1",
                        "/media/sdd1",
                        
                     }
                    local existingDrives, nonExistingDrives = listDriveExistence(drivePaths)
                    -- Print the results
                    gma.feedback("Existing drives:")
                    local driveString = ""
                    for _, path in ipairs(existingDrives) do
                       gma.feedback(path)
                       driveString = driveString .. path .. ","
                    end
                    
                    gma.feedback("Non-existing drives:")
                    for _, path in ipairs(nonExistingDrives) do
                       gma.feedback(path)
                    end
                    local driveToSelect = text("Drive For Export. Attached Drives:\n" .. driveString, "sdb1")
                    newlayout.directory = "/media/" .. driveToSelect .. '/'
                end
                newlayout.fullpathXML = newlayout.directory .. newlayout.name .. '.xml'
                feed("Writing to: " .. newlayout.fullpathXML)
                local fileXML = assert(io.open(newlayout.fullpathXML, 'w'))
                fileXML:write(xmlText)
                fileXML:close()



    -- Add MA Protocols and set variable for quick arm/disarm
    local universeString = table.concat(universeIDs, " + ")
    gma.show.setvar("PixelMergeUniverses", universeString)
    if gma.gui.confirm("Create Artnet Inputs?","OK to create input lines in Network Protocols") ~= nil then
    local artProtocol = o("Protocol 1")
    local protocolLines = a.amount(artProtocol)
    feed("Found " .. protocolLines .. " lines")
    local linesToDelete = {}
    for i = 0, protocolLines - 1, 1 do
        local thisLine = a.child(artProtocol, i)
        feed("Line " .. a.name(thisLine) .. " Property: " .. property(thisLine, 2))
        local lineType = property(thisLine, 2)
        if lineType == "Input" then
            local labelField = property(thisLine, 10)
            feed("Label: " .. labelField)
            if labelField:match("Chris.UK_MERGE: (.*)") then
                feed("This is an existing merge universe and should be deleted")
                linesToDelete[#linesToDelete + 1] = i + 1
            end
        end
    end
    table.sort(linesToDelete, function(a, b) return a > b end)
    for i = 1, #linesToDelete do
       cmd("Delete Protocol 1." .. linesToDelete[i])
    end
    local thisLine = a.amount(artProtocol) + 1
    for i=1, #universeIDs do
        local thisUniverse = universeIDs[i]
        local artSubnet = math.floor(tonumber(thisUniverse) / 16)
        local artUniverse = math.abs(math.floor((artSubnet - (tonumber(thisUniverse) / 16)) * 16)) - 1
        cmd("Store Protocol 1." .. thisLine)
        cmd("Assign Protocol 1." .. thisLine .. " /mode=Input /amount=1 /localstart=" .. thisUniverse .. " /subnet=" .. artSubnet ..  " /Universe=" .. artUniverse .. " /Info=\"Chris.UK_MERGE: " .. thisUniverse .. "\"")
        thisLine = thisLine + 1
    end
end




end

function logoTag()
    feed("\n        __         _      ______       __         _             __  \n  _____/ /_  _____(_)____/ ____ \\_____/ /_  _____(_)____ __  __/ /__\n / ___/ __ \\/ ___/ / ___/ / __ `/ ___/ __ \\/ ___/ / ___// / / / //_/\n/ /__/ / / / /  / (__  ) / /_/ / /__/ / / / /  / (__  )/ /_/ / ,<   \n\\___/_/ /_/_/  /_/____/\\ \\__,_/\\___/_/ /_/_/  /_/____(_)__,_/_/\\_\\  \n                        \\____/                                      ")
end


-- Function to check if a file or directory exists
function exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
       if code == 13 then
          -- Permission denied, but it exists
          return true
       end
    end
    return ok, err
 end
 
 
 function isdir(path)
    -- "/" works on both Unix and Windows
    return exists(path.."/")
 end
 
 
 function listDriveExistence(drivePaths)
    local existingDrives = {}
    local nonExistingDrives = {}
    
    for _, path in ipairs(drivePaths) do
       if isdir(path) then
          table.insert(existingDrives, path)
       else
          table.insert(nonExistingDrives, path)
       end
    end
 
    return existingDrives, nonExistingDrives
 end
 

return function()
    local thisLayout = text("Layout?", "24")
    local compWidth
    local compHeight
    if askForResolution then
        compWidth = text("Comp Width", defaultWidth)
        compHeight = text("Comp Height", defaultHeight)
    else
        compWidth = defaultWidth
        compHeight = defaultHeight
    end
    local typeInput = text("1: RGB, 2: RGBW, 3: CMY, 4: DIM", "1")
    local fixtureType
    if typeInput == "1" or string.lower(typeInput) == "rgb" then
        fixtureType = "rgb"
    elseif typeInput == "2" or string.lower(typeInput) == "rgbw" then
        fixtureType = "rgbw"
    elseif typeInput == "3" or string.lower(typeInput) == "cmy" then
        fixtureType = "cmy"
    elseif typeInput == "4" or string.lower(typeInput) == "dim" then
        fixtureType = "dim"
    else
        --exit

    end
    processLayout(thisLayout, compWidth, compHeight, fixtureType)
    logoTag()
end