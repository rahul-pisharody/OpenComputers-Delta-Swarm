function sleep(timeout)
  local deadline = computer.uptime() + timeout
  while computer.uptime()<deadline do
    computer.pullSignal(deadline-computer.uptime())
  end
end

List = {}
function List.new ()
  return {first = 0, last = -1}
end
function List.pushleft (list, value)
  local first = list.first - 1
  list.first = first
  list[first] = value
end
function List.pushright (list, value)
  local last = list.last + 1
  list.last = last
  list[last] = value
end
function List.popleft (list)
  local first = list.first
  if first > list.last then error("list is empty") end
  local value = list[first]
  list[first] = nil        -- to allow garbage collection
  list.first = first + 1
  return value
end
function List.popright (list)
  local last = list.last
  if list.first > last then error("list is empty") end
  local value = list[last]
  list[last] = nil         -- to allow garbage collection
  list.last = last - 1
  return value
end

chargeQueue = List:new()
function pushChargeQueue(x)
   List.pushright(chargeQueue,x)
end
function popChargeQueue(x)
   return List.popleft(chargeQueue,x)
end
function isChargeQueueEmpty()
    return (chargeQueue.first>chargeQueue.last)
end
function isInChargeQueue(data)
  for k,dr in pairs(chargeQueue) do
    if dr==data then return true end
  end
  return false
end
function getChargeNext()
    return chargeQueue[chargeQueue.first]
end

charging=0

function isChargerOccupied()
  return charging~=0
end