
dofile('print_r.lua')



-- Important note of 'repeat-until' loop
--[[
  -- computes the square root of 'x' using Newton-Raphson method
  local x = 7
  local sqr = x / 2
  repeat
    sqr = (sqr + x/sqr) / 2
    print(sqr)
    local error = math.abs(sqr^2 - x)
  until error < x / 10000 -- local 'error' still visible here
--]]



-- Important note of 'for' loop
--[[
  for i = 1, math.huge do -- Same as while-true-do, but incrementing 'i'
    if i > 7 then
      break
    end
    print(i) --> 1 2 3 4 5 6 7
  end

  for i = -1, -math.huge, -1 do
    if i < -7 then
      break
    end
    print(i) --> -1 -2 -3 -4 -5 -6 -7
  end

  -- for i = math.huge, 1, -1 do print(i) end --> 1.#INF (always)
  -- for i = -math.huge, -1, 1 do print(i) end --> -1.#INF (always)
--]]
--[[
  The for loop has some subtleties that you should learn in order to make good use of it.
  - First, all three expressions are evaluated once, before the loop starts.
  - Second, the control variable (tipically 'i') is a local variable automatically declared by the for statement,
  and it is visible only inside the loop.

  A typical mistake is to assume that the variable still exists after the loop ends:
  -- for i = 1, 10 do print(i) end
  -- print(i) --> nil

  - Third, you should not change the value of the control variable: the effect of such changes is unpredictable.
  If you want to end a for loop before its normal termination, use break.
]]



-- Generic 'for' loop
--[=[
  Unlike the numerical for, the generic for can have multiple variables, which are all updated at each iteration.
  The loop stops when the first variable gets nil.
  As in the numerical loop, the loop variables are local to the loop body and you should not change their values inside each iteration.

  -- for k, v in ipairs(table) do -- Traverses the table sequentially (faster)
  --   ...
  -- end

  -- for k, v in pairs(table) do -- Traverses the table in a random order
  --   ...
  -- end

  When the value of 'k' or 'v' are not in use, tipically it is overwritten by '_', as the following:
  for _, v in ipairs(table) do --[[...]] end
  for k, _ in pairs(table) do --[[...]] end
]=]



--[[
  A common idiom in Lua is `local foo = foo`.

  This code creates a local variable, foo, and initializes it with the value of the global variable foo.
  (The local foo becomes visible only after its declaration.)
  This idiom is useful to speed up the access to foo.
  It is also useful when the chunk needs to preserve the original value of foo even if later some other function changes the value of the global foo;
  in particular, it makes the code resistant to monkey patching.
  Any piece of code preceded by `local print = print` will use the original function print even if print is monkey patched to something else.
]]
--[[
  require 'socket'

  local function globalVariableAsParameter(var)
    local init = socket.gettime() * 1000
    for i=1, 700000000 do
      if var == 7 then
        -- Do something with MyGlobalVar
      end
    end
    print(socket.gettime() * 1000 - init) --> 6836.2827148438 (6.8 seconds)
  end

  MyGlobalVar = 7
  do
    -- local using the global value
    local MyGlobalVar = MyGlobalVar -- This speed up the access to MyGlobalVar; useful when the global variable is used multiple times

    local init = socket.gettime() * 1000
    for i=1, 700000000 do
      if MyGlobalVar == 7 then
        -- Do something with MyGlobalVar
      end
    end
    print(socket.gettime() * 1000 - init) --> 6781.5627441406 (6.8 seconds)

    globalVariableAsParameter(MyGlobalVar) --> 6833.1376953125 (6.8 seconds)
  end

  -- global
  local init = socket.gettime() * 1000
  for i=1, 700000000 do
    if MyGlobalVar == 7 then
      -- Do something with MyGlobalVar
    end
  end
  print(socket.gettime() * 1000 - init) --> 13759.885742188 (13.7 seconds) -- Worst way, since it uses the global variable directly

  globalVariableAsParameter(MyGlobalVar) --> 6767.6828613281 (6.8 seconds)
--]]

-- Above code simplified:
--[[
  MyGlobalVar = 7
  do
    -- local using the global value
    local MyGlobalVar = MyGlobalVar -- This speed up the access to MyGlobalVar; useful when the global variable is used multiple times
    -- Do something with MyGlobalVar
  end
--]]
