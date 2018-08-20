state="idle"

function stateUpdate()
  if state=="idle" then
    if isAlpha() then 
      drone.setLightColor(0xAA0000)
    elseif isBeta() then 
      drone.setLightColor(0x0000AA)
      liveCheck(alpha,20)
    else drone.setLightColor(0xFFFF00)
    end
  else idle_flag=0
  end
  if state=="moving" then
    if drone.getVelocity()<0.5 then
        state="idle"
    end
  elseif state=="waitCharge" then
    if getChargeNext()==drone_index then
      local x,y,z = findCharger()
      if x~=nil then
        local cols=drone.getLightColor()
        old_posx,old_posy,old_posz=-x,-y,-z
        charge(x,y,z)
        state="charging"
      end
    end
  elseif state=="charging" then  
    if (chargeflag==0 and drone.getOffset()<0.2 and drone.getVelocity()<0.3) then
      drone.use(1)
      drone.setLightColor(0x008800)
      chargeflag=1
    elseif (computer.energy()/computer.maxEnergy() >0.95) then
      drone.setLightColor(0x88FF88)
      drone.use(1)
      move(old_posx,old_posy,old_posz)
      state="chargedone"
      chargeflag=0
    end
  elseif state=="chargedone" then
    drone.setStatusText("IM DONE")
    if isAlpha() then 
      notifySwarmExc(320,320,"CHARGEOVER",drone_index,{})
      popChargeQueue()
      state="idle"
    else
      modem.send(swarm_list[1],320,"CHARGEDONE",drone_index)
    end
  end
end


chargeflag = 0
old_posx,old_posy,old_posz = 0,0,0

modem.open(650)
drone.setStatusText("This one")
modem.open(350)
modem.open(320)
modem.open(333)--DRONELIVECHECK
modem.open(555)
modem.open(560)

local ctr = 10

drone.setStatusText("STARTING")
flushMsgBuffer()
while true do
  drone.setStatusText(state)
  stateUpdate()
  modem.open(350)
  modem.open(320)
  local evt,_,src,prt,dist,msg,data,data2,data3=computer.pullSignal(1)
  if isBeta() and src==swarm_list[alpha] then
    idle_time=computer.uptime()
  end
  if msg~=nil then drone.setStatusText(msg) end
  if msg=="ISIDLE" then
    modem.send(src,350,"IDLE",drone_index)
  elseif msg=="LIVECHK" then
    local strg=modem.getStrength()
    modem.setStrength(dist*2)
    modem.send(src,333,"LIVECHK ACK")
    modem.setStrength(strg)
  elseif msg=="DRONEOUT" then
    modem.send(src,333,"DRONEOUT ACK")
    removeDrone(data)
    flushMsgBuffer()
  elseif msg=="ALLDO" then
    drone.setStatusText("Something")
    if isAlpha() then
      notifySwarmExc(350,350,"ALPHASAYS BEFORE",data,{})
      sync()
      load(data)()
    end
  elseif msg=="SWARM MOVE" and isAlpha() and state=="idle" then
    swarmMove(data,data2,data3)
  elseif msg=="TASKS" and isAlpha() and state=="idle" then
    distributeTasks(data)
    --flushMsgBuffer()
  elseif msg=="ALPHASAYS" then
    modem.send(src,350,"ALPHASAYS ACK")
    local old_state=state
	state="busy"
    drone.setLightColor(0xB2EDC9)
    load(data)()
	if state~="moving" then state=old_state end
    flushMsgBuffer()
  elseif msg=="ALPHASAYS BEFORE" then
    modem.send(src,350,"ALPHASAYS BEFORE ACK")
    local old_state=state
	state="busy"
    drone.setLightColor(0xFF5555)
    sync()
    drone.setLightColor(0x00FF00)
    load(data)()
	if state~="moving" then state=old_state end
  elseif msg=="ALPHASAYS AFTER" then
    modem.send(src,350,"ALPHASAYS AFTER ACK")
    local old_state=state
	state="busy"
    drone.setLightColor(0x00FF00)
    load(data)()
    sync()
	if state~="moving" then state=old_state end
  elseif msg=="WHERE" then
    drone.setStatusText("HERE")
    modem.send(src,390,"POS",nav.getPosition())
  elseif msg=="CHARGEDONE ACK" then
    if getChargeNext()==drone_index then
      state="idle"
      ch=popChargeQueue()
      drone.setStatusText("OVER:"..tostring(ch))
    end
  elseif msg=="CHARGEDONE" then
    modem.send(src,320,"CHARGEDONE ACK")
    if getChargeNext()==data then
      notifySwarmExc(320,320,"CHARGEOVER",data,{data})
      drone.setStatusText("OVER:"..tostring(popChargeQueue()))
    end
  elseif msg=="CHARGE" then
    if not isInChargeQueue(data) then 
      pushChargeQueue(data)
      drone.setStatusText("Queue:"..tostring(data))
    end
    modem.send(src,320,"CHARGE ACK")
  elseif msg=="CHARGEOVER" then
    local ch
    if not isChargeQueueEmpty() and getChargeNext()==data then 
      ch=popChargeQueue()
      drone.setStatusText("OVER:"..tostring(ch))
    end
    modem.send(src,320,"CHARGEOVER ACK")
  elseif msg=="CHARGE REQ" then
    notifySwarmExc(320,320,"CHARGE",data,{})
    --if not isChargeQueueEmpty() then
      --notifyExcl(320,320,"CHARGE",data,getChargeNext())
    --end
    pushChargeQueue(data)
    modem.send(src,320,"CHARGE REQ ACK")
  elseif msg=="CHARGE REQ ACK" then
    if state=="idle" then 
      state="waitCharge"
      drone.setLightColor(0x888800)
    end
    --local x,y,z = findCharger()
    --if x~=nil then charge(x,y,z) notifySwarm(320,320,"CHARGE",0) end
  elseif msg=="HI" then
    local n=swarm_num
    while swarm_num==n do pollNewDrone() end
    if isBeta() then
      for f=1,#file_list do
        modem.send(src,650,"DOFILE",file_list[f])
        sleep(3)
      end
    end
  elseif msg=="NEWDRONE" then
    addToSwarm(data)
    modem.send(src,555,"NEWDRONE ACK")
    if isBeta() then
      for f=1,#file_list do
        modem.send(src,650,"DOFILE",file_list[f])
        sleep(3)
      end
    end
  elseif evt==nil then
    --drone.setStatusText("Nothing")
    --if state=="idle" and computer.energy()/computer.maxEnergy()<0.1 and drone.getVelocity()<0.3 then
      --local x,y,z = findCharger()
      --if x~=nil then
        --charge(x,y,z)
      --end
    if (state=="idle" and computer.energy()/computer.maxEnergy() <0.3 and drone.getVelocity()<0.3 and not isInChargeQueue(drone_index)) then
      ctr=ctr+1
      if ctr>=5 then
        ctr = 0
        drone.setStatusText("LOW ENERGY")
        if isAlpha() then
          local x,y,z = findCharger()
          if x~=nil then
            notifySwarmExc(320,320,"CHARGE",drone_index,{})
            pushChargeQueue(drone_index)
            state="waitCharge"
          end
        else
          modem.send(swarm_list[1],320,"CHARGE REQ",drone_index)
        end
      end
    end
  end
  if msg~=nil then prev_msg=msg end
end