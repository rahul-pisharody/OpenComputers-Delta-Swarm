# OpenComputers: Delta-Swarm
A Drone-Swarm program based on Master-Slave architecture

Requirements:
 1. Drone with navigation uprade and wireless card
 2. Any wireless setup (Tablet, Computer with Wireless Relay, even a Robot with Wireless capability)

Instructions:
 1. `flash hive_bios.lua` and make 6 (can be changed in bios) drones with same BIOS
 2. Start the first drone and wait for it to turn Red
 3. Start other drones, one-by-one, waiting for it to register into the swarm. 
      The registration process is visible as white light in one of the drones. Start the next when it's over.
 4. After all 6 have been registered, they will all turn orange and move to (5,5,0) relative to themselves.
      At this point, run `hive_load_ai` and wait. After about 10 seconds, they will turn Red(Alpha), Blue(Beta) and Yellow(All others).
   
 5. Right now, the only fully working command is movement in Delta formation.
      Run `hive_ctrl ` with relative movement coordinates (x,y,z) as the arguments.
      e.g.: `hive_ctrl 30 5 -10`

  This supports dynamic adding of drones (but only one at a time), drone failure recovery (Multiple failures not handled yet) 
and automatic charging implemented as a queue.
  The charger must have a waypoint labelled "CHARGER" below it's charging position and a lever above to activate it.
  
  In progress: Task distribution through the Alpha (Build a basic house in coordination. Maybe a whole town.)
