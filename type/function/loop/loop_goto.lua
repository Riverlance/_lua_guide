
-- The code below won't work in here (here is normal Lua 5.1), but for Kingdom Age or Lua 5.2+.

dofile('print_r.lua')

-- Goto (can simulate 'continue' statement, multi-level continue, multi-level break, redo, etc)
-- Important: It does not works on Lua 5.1, but works with LuaJIT (so it works for Kingdom Age).
--[[
  A typical and well-behaved use of a goto is to simulate some construction that you learned from another
  language but that is absent from Lua, such as continue, multi-level break, multi-level continue, redo, local
  error handling, etc.

  A continue statement is simply a goto to a label at the end of a loop block;
  a redo statement jumps to the beginning of the block:

  while some_condition do
    ::redo::
    if some_other_condition then
      goto continue
    else if yet_another_condition then
      goto redo
    end
    some code
    ::continue::
  end
]]
--[[
  local i = 0
  while true do
    i = i + 1

    if i == 7 then
      print('yay!')
      goto continue -- Jump to continue, instead of print(i)
    end

    print(i)

    if i >= 10 then
      break
    end

    ::continue::
  end
--]]
--[[
  A useful detail in the specification of Lua is that the scope of a local variable ends on the last non-void statement of the block
  where the variable is defined; labels are considered void statements
  To see the usefulness of this detail, consider the next fragment:

  while some_condition do
    if some_other_condition then
      goto continue
    end

    local var = something

    some code

    ::continue::
  end

  You may think that this goto jumps into the scope of the variable var.
  However, the continue label appears after the last non-void statement of the block, and therefore it is not inside the scope of var.

  local i = 0
  while true do
    i = i + 1

    -- local x = 7 -- Solution 1: x declaration before 'goto'

    if i == 2 then
      print('yay!')
      goto continue -- Error: <goto continue> jumps into the scope of local 'x'
    end

    print(i)

    if i >= 3 then
      break
    end

    local x = 7 -- <goto continue> will try to jump inside this scope of local 'x' (and fail)
    ::continue::
    -- local x = 7 -- Solution 2: x declaration after ::continue::

    print(x)
  end
]]

--[[
  The goto is also useful for writing state machines:
  There are better ways to write this specific program, but this technique is useful if we want to translate a
  finite automaton into Lua code automatically (think about dynamic code generation).
]]
--[[
  ::s1:: do
    local c = io.read(1)
    if c == '0' then goto s2
    elseif c == nil then print'ok'; return
    else goto s1
    end
  end

  ::s2:: do
    local c = io.read(1)
    if c == '0' then goto s1
    elseif c == nil then print'not ok'; return
    else goto s2
    end
  end

  goto s1
--]]

--[[
  As another example, let us consider a simple maze game.
  The maze has several rooms, each with up to four doors: north, south, east, and west.
  At each step, the user enters a movement direction.
  If there is a door in this direction, the user goes to the corresponding room; otherwise, the program prints a warning.
  The goal is to go from an initial room to a final room.

  This game is a typical state machine, where the current room is the state.
  We can implement this maze with one block for each room, using a goto to move from one room to another.

  For this simple game, you may find that a data-driven program, where you describe the rooms and movements with tables, is a better design.
  However, if the game has several special situations in each room, then this state-machine design is quite appropriate.

  The following example follows this model:
  [Room 1] [Room 2]
  [Room 3] [Room 4]
  - Start at the `Room 1`.
  - Move to reach at the `Room 4` to win.
]]
--[[
  goto room1 -- Initial room

  ::room1:: do
    local move = io.read()
    if move == 'south' then goto room3
    elseif move == 'east' then goto room2
    else print('invalid move'); goto room1 -- Stay in the same room
    end
  end

  ::room2:: do
    local move = io.read()
    if move == 'south' then goto room4
    elseif move == 'west' then goto room1
    else print('invalid move'); goto room2 -- Stay in the same room
    end
  end

  ::room3:: do
    local move = io.read()
    if move == 'north' then goto room1
    elseif move == 'east' then goto room4
    else print('invalid move'); goto room3 -- Stay in the same room
    end
  end

  ::room4:: do
    print('Congratulations, you won!')
  end
--]]
--[[ -- Without `goto` (but, for example, the `continue` simulation is not possible without `goto`)
  do
    local room1, room2, room3, room4

    room1 = function()
      local move = io.read()
      if move == 'south' then room3()
      elseif move == 'east' then room2()
      else print('invalid move'); room1() -- Stay in the same room
      end
    end

    room2 = function()
      local move = io.read()
      if move == 'south' then room4()
      elseif move == 'west' then room1()
      else print('invalid move'); room2() -- Stay in the same room
      end
    end

    room3 = function()
      local move = io.read()
      if move == 'north' then room1()
      elseif move == 'east' then room4()
      else print('invalid move'); room3() -- Stay in the same room
      end
    end

    room4 = function()
      print('Congratulations, you won!')
    end

    room1() -- Initial room
  end
--]]
