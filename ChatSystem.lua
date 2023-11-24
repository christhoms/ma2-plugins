local stations = {"192.168.0.11", "192.168.0.12", "192.168.0.13"}

function SendMessage()
    local message = gma.textinput("SEND MESSAGE", "TYPE HERE")
    gma.show.setvar("ChatMessage", message)
    for i = 1, #stations do
        gma.cmd('RemoteCommand ' .. stations[i] .. ' LUA "ShowMessage()"')
    end
end

function ShowMessage()
    gma.gui.msgbox("CHAT MESSAGE", text)
end