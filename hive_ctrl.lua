local modem = require("component").modem
local event = require("event")

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
