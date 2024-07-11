## List of Fixes:
1. [Negative Goodwill when Completing Tasks](#f1)
2. [Blood Pool Initialization](#f2)
3. [Fluid Aim Initialization](#f3)
4. [Armor Repair Like WPO Initialization](#f4)
5. [GAMMA UI Faction Prices Initialization](#f5)

---
<h3 id="f1">1. Negative Goodwill when Completing Tasks</h3>

#### Error
```
~ STACK TRACEBACK:
  gamedata\scripts\_g.script (line: 672) in function 'abort'
  gamedata\scripts\xr_logic.script (line: 631) in function 'abort_syntax_error_in_cond'
  gamedata\scripts\xr_logic.script (line: 758) in function 'extract_conditions'
  gamedata\scripts\xr_logic.script (line: 802) in function 'r_string_to_condlist'
  gamedata\scripts\task_objects.script (line: 74) in function <gamedata\scripts\task_objects.script:34>
  [C]: in function 'CGeneralTask'
  gamedata\scripts\task_manager.script (line: 276) in function 'load_state'
  gamedata\scripts\bind_stalker.script (line: 474) in function 'load_state'
  gamedata\scripts\bind_stalker.script (line: 362) in function <gamedata\scripts\bind_stalker.script:357>
~ ------------------------------------------------------------------------
section 'nil': field 'nil': syntax error in switch condition [...sic...]
```

#### Cause
`xr_logic.extract_conditions()` can't parse negative values in conditions.

#### Effect
Dynamic Tasks don't reward negative goodwill as intended.


#### Fix
1. Intercept the extract_conditions() call
2. Replace minus signs with tokens
3. Call the original function
4. Restore the minus signs

---
<h3 id="f2">2. Blood Pool Initialization</h3>

#### Error
```
![axr_main callback_set] callback npc_on_foot_step doesn't exist!
~ ------------------------------------------------------------------------
~ STACK TRACEBACK:
  c:/anomaly\gamedata\scripts\axr_main.script (line: 254) in function 'callback_set'
  c:/anomaly\gamedata\scripts\_g.script (line: 104) in function 'RSC'
  c:/anomaly\gamedata\scripts\dxml_core.script (line: 253) in function 'RegisterScriptCallback'
  c:/anomaly\gamedata\scripts\blood_pool.script (line: 349) in main chunk
  [C]: in function '__index'
  c:/anomaly\gamedata\scripts\axr_main.script (line: 312) in function 'on_game_start'
  c:/anomaly\gamedata\scripts\_g.script (line: 82) in function <c:/anomaly\gamedata\scripts\_g.script:73>
~ ------------------------------------------------------------------------
```

#### Cause
`blood_pool.script` doesn't call `AddScriptCallback("npc_on_foot_step")` if "9- Exo Servomotor Sounds" is enabled, so subsuqent calls to `RegisterScriptCallback("npc_on_foot_step", ...)` are invalid.

#### Effect
I haven't specifically tested, but my guess is that NPCs don't leave bloody footsteps after stepping in blood pools when they in fact should.

#### Fix
Call `AddScriptCallback("npc_on_foot_step")` beforehand if the above mod is enabled so that it's always a thing.

---
<h3 id="f3">3. Fluid Aim Initialization</h3>

#### Error
```
![axr_main callback_set] callback on_actor_first_update doesn't exist!
~ ------------------------------------------------------------------------
~ STACK TRACEBACK:
  c:/anomaly\gamedata\scripts\axr_main.script (line: 254) in function 'callback_set'
  c:/anomaly\gamedata\scripts\_g.script (line: 104) in function 'RSC'
  c:/anomaly\gamedata\scripts\dxml_core.script (line: 253) in function 'RegisterScriptCallback'
  c:/anomaly\gamedata\scripts\fluid_aim.script (line: 181) in function 'on_game_start'
  c:/anomaly\gamedata\scripts\axr_main.script (line: 320) in function 'on_game_start'
  c:/anomaly\gamedata\scripts\_g.script (line: 82) in function <c:/anomaly\gamedata\scripts\_g.script:73>
~ ------------------------------------------------------------------------
```

#### Cause
`fluid_aim.on_game_start()` tries to register the "on_actor_first_update" callback, but that is not a thing (it should be "actor_on_first_update" instead).

#### Effect
`fluid_aim.ignore_fire_key_press()` doesn't get called when first loading. I'm not entirely sure what effect this has but it looks like some sort of QOL fix for an initial keypress doesn't trigger.

#### Fix
Replace `fluid_aim.on_game_start()` with one that registers the correct script callbacks.

---
<h3 id="f4">4. Armor Repair Like WPO Initialization</h3>

#### Error
```
![axr_main callback_set] trying to set callback actor_item_to_slot to nil function!
~ ------------------------------------------------------------------------
~ STACK TRACEBACK:
  c:/anomaly\gamedata\scripts\axr_main.script (line: 247) in function 'callback_set'
  c:/anomaly\gamedata\scripts\_g.script (line: 104) in function 'RSC'
  c:/anomaly\gamedata\scripts\dxml_core.script (line: 253) in function 'RegisterScriptCallback'
  c:/anomaly\gamedata\scripts\item_exo_device.script (line: 466) in function 'on_game_start'
  c:/anomaly\gamedata\scripts\axr_main.script (line: 320) in function 'on_game_start'
  c:/anomaly\gamedata\scripts\_g.script (line: 82) in function <c:/anomaly\gamedata\scripts\_g.script:73>
~ ------------------------------------------------------------------------

![axr_main callback_set] trying to set callback actor_item_to_ruck to nil function!
~ ------------------------------------------------------------------------
~ STACK TRACEBACK:
  c:/anomaly\gamedata\scripts\axr_main.script (line: 247) in function 'callback_set'
  c:/anomaly\gamedata\scripts\_g.script (line: 104) in function 'RSC'
  c:/anomaly\gamedata\scripts\dxml_core.script (line: 253) in function 'RegisterScriptCallback'
  c:/anomaly\gamedata\scripts\item_exo_device.script (line: 467) in function 'on_game_start'
  c:/anomaly\gamedata\scripts\axr_main.script (line: 320) in function 'on_game_start'
  c:/anomaly\gamedata\scripts\_g.script (line: 82) in function <c:/anomaly\gamedata\scripts\_g.script:73>
~ ------------------------------------------------------------------------
```

#### Cause
`item_exo_device.on_game_start()` tries to register 2 script callbacks to an `on_move()` function, but that function isn't a thing.

#### Effect
As far as I can tell, no effect besides the error message in the log.

#### Fix
`item_exo_device.on_move()` is commented out in the original code, as are some other things it uses. So I assume it's not supposed to be enabled or do anything. Therefore just create an empty `item_exo_device.on_move()` function to get rid of the error message in the log, then clean up both callbacks by unregistering them.

---
<h3 id="f5">5. GAMMA UI Faction Prices Initialization</h3>

#### Error
```
! [LUA] SCRIPT RUNTIME ERROR
! [LUA]  0 : [C  ] __index
! [LUA]  1 : [Lua] c:/anomaly\gamedata\scripts\axr_main.script(312) : on_game_start
! [LUA]  2 : [Lua] c:/anomaly\gamedata\scripts\_g.script(82) :
! [LUA] c:/anomaly\gamedata\scripts\a_faction_prices.script:16: attempt to index global 'faction_stocks' (a nil value)
! [LUA]  0 : [C  ] __index
! [LUA]  1 : [Lua] c:/anomaly\gamedata\scripts\axr_main.script(312) : on_game_start
! [LUA]  2 : [Lua] c:/anomaly\gamedata\scripts\_g.script(82) :
! [SCRIPT ERROR]: c:/anomaly\gamedata\scripts\a_faction_prices.script:16: attempt to index global 'faction_stocks' (a nil value)
! [ERROR] --- Failed to load script a_faction_prices
```

#### Cause
`a_faction_prices.script` tries to call `faction_stocks.get_trader_community()`, but there is no `faction_stocks.script` in GAMMA.

#### Effect
I don't think there is any effect besides the error in the log and the script file crashing.

#### Fix
My hunch is that `a_faction_prices.script` is a WIP and shouldn't be enabled anyway. Therefore create a `faction_stocks.script` with what I think is the correct version of `get_trader_community()` in it just to account for it and remove the error. But also unregister the callback to disable until I find out otherwise.
