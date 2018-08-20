nav = require("navigation")

function getDronePos(i)
  if i>swarm_num then return nil end
  modem.close(350)
  modem.open(390)
  modem.send(swarm_list[i],350,"WHERE")
  local c=1
  while true do
    local evt,_,src,prt,_,msg,x,y,z = computer.pullSignal(5)
    if msg==nil then
      if c==5 then return nil end
      modem.send(swarm_list[i],350,"WHERE")
      c=c+1
    end
    if msg=="POS" and src==swarm_list[i] then 
      drone.setStatusText("GOT IT")
      modem.close(390) modem.open(350) 
      return x,y,z
    end
  end
end

function getAlphaPos()
  getDronePos(1)
end

function moveDrone(drone_index,x,y,z)
  modem.send(swarm_list[drone_index],350,"ALPHASAYS","move("..tostring(x)..","..tostring(y)..","..tostring(z)..")")
end

function droneDo(drone_index,task)
  drone.setStatusText("DO:"..task)
  modem.send(swarm_list[drone_index],350,"ALPHASAYS",task)
end

function move(x,y,z)
  local orient=""
  if math.abs(x)>=math.abs(z) then
    if x>=0 then orient="+x"
    else orient="-x" end
  else
    if z>0 then orient="+z"
    else orient="-z" end
  end
  drone.setStatusText(orient)
  drone.move(x,y,z)
  state="moving"
  --computer.pullSignal(3)
end

function charge(x,y,z)
  move(x,y,z)
  state="charging"
end

function findCharger()
  local wypts=nav.findWaypoints(64)
  local x,y,z
  for i=1,wypts.n do
    if wypts[i].label == "CHARGER" then
      x=wypts[i].position[1]
      y=wypts[i].position[2]+1
      z=wypts[i].position[3]
    end
  end
  return x,y,z
end

function deltaFormation(orient,x,y,z)
  local x1 = x or nil
  local y1 = y or nil
  local z1 = z or nil
  if isAlpha() then return
  else
    if x1==nil then x1,y1,z1 = getAlphaPos() end
    if x1==nil then
      drone.setStatusText("ERROR")
      return
    end
    local x2,y2,z2 = nav.getPosition()
    local dx=x1-x2 
    local dy=y1-y2 
    local dz=z1-z2
    if isBeta() then
      if orient=="+x" then move(dx-2,dy+1,dz)
      elseif orient=="-x" then move(dx+2,dy+1,dz)
      elseif orient=="+z" then move(dx,dy+1,dz-2)
      elseif orient=="-z" then move(dx,dy+1,dz+2)
      end
    elseif drone_index%2==0 then
      if orient=="+x" then move(dx-2*(math.ceil(drone_index/2)-1),dy,dz+2*(math.ceil(drone_index/2)-1))
      elseif orient=="-x" then move(dx+2*(math.ceil(drone_index/2)-1),dy,dz-2*(math.ceil(drone_index/2)-1))
      elseif orient=="+z" then move(dx-2*(math.ceil(drone_index/2)-1),dy,dz-2*(math.ceil(drone_index/2)-1))
      elseif orient=="-z" then move(dx+2*(math.ceil(drone_index/2)-1),dy,dz+2*(math.ceil(drone_index/2)-1))
      end
    elseif drone_index%2==1 then
      if orient=="-z" then move(dx-2*(math.ceil(drone_index/2)-1),dy,dz+2*(math.ceil(drone_index/2)-1))
      elseif orient=="+z" then move(dx+2*(math.ceil(drone_index/2)-1),dy,dz-2*(math.ceil(drone_index/2)-1))
      elseif orient=="+x" then move(dx-2*(math.ceil(drone_index/2)-1),dy,dz-2*(math.ceil(drone_index/2)-1))
      elseif orient=="-x" then move(dx+2*(math.ceil(drone_index/2)-1),dy,dz+2*(math.ceil(drone_index/2)-1))
      end
    end
  end
end

function swarmMove(x,y,z)
  state="moving"
  local orient
  if math.abs(x)>=math.abs(z) then 
    if x>=0 then orient="+x" 
    else orient="-x" 
    end
  else
    if z>=0 then orient="+z" 
    else orient="-z" 
    end
  end
  local tx,ty,tz = nav.getPosition()
  drone.setLightColor(0x00AAFF)
  notifySwarmExc(350,350,"ALPHASAYS","deltaFormation(\""..orient.."\","..tostring(tx)..","..tostring(ty)..","..tostring(tz)..")",{})
  --sync()
  drone.setLightColor(0xFF5555)
  sleep(1)
  notifySwarmExc(350,350,"ALPHASAYS BEFORE","move("..tostring(x)..","..tostring(y)..","..tostring(z)..")",{})
  drone.setLightColor(0xFF8800)
  sync()
  drone.setLightColor(0x00FF00)
  move(x,y,z)
end

function distributeTasks(task_str)
  i=1
  local my_task=""
  drone.setLightColor(0x555555)
  for task in task_str:gmatch("[^;]+") do
    drone.setStatusText("TK:"..task)
    if i==drone_index then
      my_task=task:gsub( "^%s*", "")
    elseif i>swarm_num then
      my_task = my_task..task:gsub( "^%s*", "")
    else
      local x,y,z=getDronePos(i)
      local x1,y1,z1=nav.getPosition()
      droneDo(i,"move("..tostring(x1-x)..","..tostring(y1-y)..","..tostring(z1-z)..") "..task:gsub( "^%s*", ""))
    end
    i=i+1
  end
  --drone.setStatusText("TKS:"..tostring(i)..task_str)
  load(my_task)()
end