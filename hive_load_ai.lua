local modem = require("component").modem

function loadFile(filepath)
  local fdesc=io.open(filepath)
  if not fdesc then print("FILE "..filepath.." NOT FOUND")
  else
    local contents = fdesc:read("*a")
    fdesc:close()
    modem.broadcast(650,"DOFILE",contents)
    --print(contents)
  end
end

loadFile("hive_ai\hive_utils.lua")
os.sleep(3)
loadFile("hive_ai\hive_chargeQueue.lua")
os.sleep(3)
loadFile("hive_ai\hive_move.lua")
os.sleep(3)
loadFile("hive_ai\hive_loop.lua")
--modem.broadcast(650,"DOFILE","modem.open(350) drone.setLightColor(0xFFFFFF) drone.setStatusText("THIS") while true do sleep(10) end")
    