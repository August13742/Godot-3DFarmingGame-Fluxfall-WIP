# Fluxfall - Prologue (WIP)

My second game ever, currently under development. (Made Public for Internship / Job Application)

Think of it as Harvestella + Rune Factory: Guardians of Azuma + Frostpunk.

## What's here:

### Item & Inventory & Crafting System with Automatic Database Generation
![Demo](demo_gifs/inventory_crafting_demo.gif)
### Functional 3rd Person Action RPG Camera & State-Machine Based Player Control 
Using Raycast & Shapecast

![Demo](demo_gifs/player_control_demo.gif)
### Functional Day & Night Cycle with Adjustable Time Scale
Shader based celestial body simulation (https://godotshaders.com/shader/stylized-sky-with-procedural-sun-and-moon/), Time calculation logic is moved to a new Singleton

### Functional Crop System with Hydration Requirement
Inspired by Minecraft's Growth Tick System but with my own twist: A Stohastic Model
![Demo](demo_gifs/crop_daynight_demo.gif)

p = $\frac{1}{I}P_{tick}*P_{grow}$

mean = $\frac{S}{p}$

variance = $\frac{S(1-p)}{p^2}$

by separating visual stages and computation stages, variance and mean can be fine-tuned. 

For example: 
Growth Tick (GT) Check happens every 10 in-game Minute with probability. 
if GT && hydrated && (rand()<= growth_chance) then stage ++, if stage satisfices Visual change, then change model.


since the system is implemented based on in-game time, Sleep can be achieved by simpling tweaking the Time Scale.

### To do:
1. QTE & Cutscene
2. Terrains and Environments (Main Field, Main Town, etc.)
3. Combat System with 2~3 Mobs and 1 boss
4. Smart Helper NPCs 

