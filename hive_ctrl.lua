local modem = require("component").modem
local event = require("event")

function sendAndRecv(drone_index,msg,data1,data2)
  data2 = data2 or nil
  modem.open(660)
  modem.broadcast(650,msg,data1)
  local evt,src,prt,dist,ind,msg1,msg2,msg3
  --print("send")
  while true do
    evt,_,src,prt,dist,ind,msg1,msg2,msg3 = event.pull(5,"modem")
    if ind==drone_index then break
    elseif evt==nil then return nil end
  end
  --print("recv:")
  --print(ind,msg1,msg2,msg3)
  modem.close(660)
  return msg1,msg2,msg3
end

function moveDrone(drone_index,x,y,z)
  modem.broadcast(650,"DO","if drone_index=="..tostring(drone_index).." then move("..tostring(x)..","..tostring(y)..","..tostring(z)..") end")
end
function moveAll(x,y,z)
  modem.broadcast(650,"ALLDO","move("..tostring(x)..","..tostring(y)..","..tostring(z)..")")
end

local test_cmds=[[move(30,0,0); move(2,0,0) move(30,0,0); move(0,0,2) move(30,0,0); move(-2,0,0) move(30,0,0); move(0,0,-2) move(30,0,0); move(0,2,0) move(30,0,0)]]
local x,y,z=...
x=tonumber(x) or nil y=tonumber(y) or nil z=tonumber(z) or nil
modem.broadcast(650,"SWARM MOVE",x,y,z)
--moveAll(x,y,z)
--modem.broadcast(650,"TASKS",test_cmds)
for i in test_cmds:gmatch("[^;]+") do
  print(i)
  print(";")
end