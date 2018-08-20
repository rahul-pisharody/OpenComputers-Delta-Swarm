alpha = 1
beta = 2

function isAlpha()
  return (drone_index==alpha)
end

function isBeta()
  return drone_index==beta
end

function removeDrone(id)
  if drone_index>id then drone_index=drone_index-1 end
  table.remove(swarm_list,id)
  swarm_num=#swarm_list
end

function flushMsgBuffer()
  while true do
    evt=computer.pullSignal(1)
    if evt==nil then break end
  end
end

function getAck(sport,ackport,msg,data,id,timeout)
  local start_time=computer.uptime()
  while true do
    if timeout~=nil and computer.uptime()>start_time+timeout then return false end
    local ev,_,sr,prt,_,m = computer.pullSignal(1)
    if (sr==swarm_list[id] and m==msg.." ACK") then
      return true
    end
    if ev==nil then modem.send(swarm_list[id],sport,msg,data) end
  end
end

function wait(rport,msg,id)
  local r_op = modem.isOpen(rport)
  modem.open(rport)
  while true do
    local evt,_,s,pt,_,m,dat=computer.pullSignal(1)
    if m==msg and s==swarm_list[id] then
      break
    end
  end
  if r_op then modem.open(rport) else modem.close(rport) end
end

function waitAndAck(rport,ackport,msg,id)
  local r_op = modem.isOpen(rport)
  local ack_op = modem.isOpen(ackport)
  local sig_str = modem.getStrength()
  modem.close(ackport)
  modem.open(rport)
  while true do
    local evt,_,s,pt,_,m,dat=computer.pullSignal(1)
    if m==msg then
      modem.send(s,ackport,msg.." ACK")
      drone.setStatusText("ACK:"..tostring(dat))
      if s==swarm_list[id] then
        break
      end
    end
  end
  modem.setStrength(sig_str)
  if r_op then modem.open(rport) else modem.close(rport) end
  if ack_op then modem.open(ackport) else modem.close(ackport) end
end



function sync()
  modem.open(600)
  modem.open(610)
  if isAlpha() then
    notifySwarm(610,600,"READY",alpha)
  else
    waitAndAck(610,600,"READY",alpha)
  end
  
  if isAlpha() then
    modem.broadcast(610,"GO")
  else
    wait(610,"GO",alpha)
  end
  modem.close(600)
  modem.close(610)
end


function isInTable(tab,x)
  for k,v in pairs(tab) do
    if v==x then return true end
  end
  return false
end

function notifySwarmExc(sport,ackport,msg,data,exc_table)
  local col = drone.getLightColor()
  drone.setLightColor(0xFFFFFF)
  local sp_op = modem.isOpen(sport)
  local ack_op = modem.isOpen(ackport)
  local sig_str = modem.getStrength()
  modem.setStrength(50)
  modem.close(sport)
  modem.open(ackport)
  
  local i=1
  repeat
    if i~=drone_index and not isInTable(exc_table,i) then
      drone.setStatusText("NLp:"..tostring(i)..tostring(#swarm_list))
      modem.send(swarm_list[i],sport,msg,data)
      if not getAck(sport,ackport,msg,data,i,15) then
        notifySwarmExc(333,333,"DRONEOUT",i,{i})
        removeDrone(i)
        for n,m in pairs(exc_table) do if m>i then m=m-1 end end
        i=i-1
      end
    end
    i=i+1
  until i>swarm_num

  modem.setStrength(sig_str)
  if sp_op then modem.open(sport) else modem.close(sport) end
  if ack_op then modem.open(ackport) else modem.close(ackport) end
  drone.setLightColor(col)
end

function notifyExcl(sport,ackport,msg,data,id)
  local col = drone.getLightColor()
  drone.setLightColor(0x5555FF)
  local sp_op = modem.isOpen(sport)
  local ack_op = modem.isOpen(ackport)
  local sig_str = modem.getStrength()
  modem.setStrength(50)
  modem.close(sport)
  modem.open(ackport)
  drone.setStatusText("NLp:"..tostring(id)..tostring(#swarm_list))
  modem.send(swarm_list[id],sport,msg,data)
  if not getAck(sport,ackport,msg,data,id,15) then
    notifySwarmExc(333,333,"DRONEOUT",id,{id})
    removeDrone(id)
  end
  modem.setStrength(sig_str)
  if sp_op then modem.open(sport) else modem.close(sport) end
  if ack_op then modem.open(ackport) else modem.close(ackport) end
  drone.setLightColor(col)
end

idle_flag = 0
idle_time = 0

function liveCheck(id,tx)
  if idle_flag==0 then
    idle_flag=1
    idle_time=computer.uptime()
  else
    if computer.uptime()>idle_time+tx then
      drone.setLightColor(0x33FFBB)
      idle_time=computer.uptime()
      modem.setStrength(100)
      modem.send(swarm_list[id],333,"LIVECHK")
      local t=idle_time
      while true do
        if computer.uptime()>t+15 then
          drone.setLightColor(0xFF00FF)
          removeDrone(alpha)
          notifySwarmExc(333,333,"DRONEOUT",alpha,{})
          break
        end
        local evt,_,s,_,_,msg=computer.pullSignal(2)
        if msg==nil then modem.send(swarm_list[id],333,"LIVECHK") end
        if s==swarm_list[alpha] then break end
      end
    end
  end
end