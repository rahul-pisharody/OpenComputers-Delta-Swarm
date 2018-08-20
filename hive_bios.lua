function require(x)
  return component.proxy(component.list(x)())
end
drone = require("drone")
modem = require("modem")

file_list = {}
swarm_list = {}
swarm_num = 0

drone_index = 0

function isInSwarm(taddr)
  for i,addr in pairs(swarm_list) do
    if addr==taddr then return true end
  end
  return false
end

function addToSwarm(drone)
  if isInSwarm(drone) then return end
  swarm_num=swarm_num+1
  swarm_list[swarm_num]=drone
end

function sendSwarmList(dest)
  for i=1,swarm_num,1 do
    while true do
      modem.send(dest,550,"DRONE",swarm_list[i],i)
      local evt,_,s,p,_,m=computer.pullSignal(10)
      if (m=="DRONE ACK") then break end
    end
  end
  modem.send(dest,550,"END LIST")
end

function notifySwarm(sport,ackport,msg,data)
  local col = drone.getLightColor()
  drone.setLightColor(0xFFFFFF)
  local sp_op = modem.isOpen(sport)
  local ack_op = modem.isOpen(ackport)
  local sig_str = modem.getStrength()
  modem.setStrength(50)
  modem.close(sport)
  modem.open(ackport)
  for k,addr in pairs(swarm_list) do
    if k~=drone_index then
      drone.setStatusText("NLp:"..tostring(k)..tostring(#swarm_list))
      modem.send(addr,sport,msg,data)
      while true do
        local ev,_,sr,prt,_,m = computer.pullSignal(1)
        if (sr==addr and m==msg.." ACK") then
          break
        end
        if ev==nil then modem.send(addr,sport,msg,data)
        else drone.setStatusText(msg.."\n"..sr)
        end
      end
    end
  end
  modem.setStrength(sig_str)
  if sp_op then modem.open(sport) else modem.close(sport) end
  if ack_op then modem.open(ackport) else modem.close(ackport) end
  drone.setLightColor(col)
end


function pollNewDrone()
  modem.close(550)
  modem.open(555)
  modem.open(560)
  while true do
    event,_,src,port,_,msg,drone_add=computer.pullSignal(1)
    if msg~=nil then drone.setStatusText("M:"..msg) end
    if (msg=="HI" and port==555 and not(isInSwarm(src))) then
      modem.send(src,550,"HI ACK")
      break
    elseif (msg=="NEWDRONE" and port==560) then
      modem.close(555)
      addToSwarm(drone_add)
      modem.send(src,555,"NEWDRONE ACK")
      modem.open(555)
      return
    elseif event==nil then
      return
    end
  end
  c=1
  while c<4 do
    event,_,src,port,_,msg=computer.pullSignal(1)
    if msg~=nil then c=c+1 end
    if event==nil then break
    elseif (msg=="ICHOOSEYOU") then
      sendSwarmList(src)
      notifySwarm(560,555,"NEWDRONE",src)
      addToSwarm(src)
      break
    end
  end
end

modem.open(550)
modem.broadcast(555,"HI")
c=0
while c<5 do
  event,_,src,port,_,msg=computer.pullSignal(2)
  if event==nil then c=c+1 end
  if (msg=="HI ACK" and port==550) then break end
end
if msg==nil then
  addToSwarm(modem.address)
  drone_index=1
  drone.setLightColor(0xFF0000)
  while swarm_num<6 do
    drone.setStatusText(tostring(swarm_num))
    pollNewDrone()
  end
elseif msg=="HI ACK" then
  modem.send(src,555,"ICHOOSEYOU")
  while true do
    event,_,src,port,_,msg,drone_add,num=computer.pullSignal(10)
    if msg=="END LIST" then
      swarm_num=#swarm_list
      break
    elseif msg=="DRONE" then
      swarm_list[num]=drone_add
      modem.send(src,555,"DRONE ACK")
    end
  end 
  addToSwarm(modem.address)
  drone_index = swarm_num
  while swarm_num<6 do
    pollNewDrone()
    drone.setStatusText(tostring(swarm_num))
  end
end
drone.setLightColor(0xFFAA00)

drone.move(5,5,0)
modem.open(650)
while true do
  local evt,_,src,prt,_,msg,data = computer.pullSignal()
  if msg=="DOFILE" then
    drone.setStatusText("DOING"..data)
    table.insert(file_list,data)
    load(data)()
  end
end