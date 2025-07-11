# Tasks QoL Pack

A modpack consisting of my task related QoL mods.  
I decided to bundle together 3 of my mods because all depend on each other. If need be I can eliminate the dependency, but for now I just release it as a pack instead.

# Contents
- **The Job Can Wait**
- **The Northern Job**
- **PDA Taskboard Fix** (Only available within this pack)

# PDA Taskboard Fix
So let's talk about this one. There is a bug with the PDA taskboard.  
Sometimes tasks can appear in the wrong place resulting in you accepting a task you didn't intend to.  
This probably has to do something with map blacklisting.   
When I tested what can cause it I basically blacklisted all maps from the map pool and the bug occured 90% of the time.  
  
**The Job Can Wait** and **The Northern Job** enhanced this bug and made it appear more frequently. I spent the last 2 days troubleshooting, thinking about the best solution.  
The original implementation relied on an array having items in the same order as a different array. This is a very brittle thing I'm surprised it doesn't break more often.  

My solution to this problem: I modified all methods (ones I could find at least) that can affect the second array and gave it the TaskId as the key. This way I can just give it a TaskId when I need additional info about a task and it will always return the correct information.  

# Installation instructions
If you have any of these enabled: **The Job Can Wait**, **The Northern Job** disable them.
Drop this mod at highest priority as it overwrites a lot of files.

# Compatibility
No manual patching needed. Scripts will check if you have any of the below mods installed and will auto patch if the mod.
- New levels 0.53 (2023.07.25)
- Disabled `G.A.M.M.A. Psy Fields in the North`.
- PDA Back button integrated thanks to @monstercatty a.k.a. cXy

# MCM Options
- Standalone **The Job Can Wait** had MCM options. These can still be found under MCM -> **The Job Can Wait**.
