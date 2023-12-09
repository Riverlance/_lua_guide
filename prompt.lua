
dofile('print_r.lua')

-- Lua prompt - The Stand-Alone Interpreter

--
--[=[
  The usage of lua is
  lua [options] [script [args]]
]=]

-- Enter prompt
--[[
  lua --> Entering the Lua prompt interpreter (Ctrl+C or type `os.exit()` to leave)

  = 5 + 2
  7
  = math.pi
  3.1415926535898
--]]

-- Execute mode (-e) - Enter command on prompt directly
--[[
PS D:\River\code\Lua\_lua_guide> lua -e 'print(7)'
7
]]

-- Interactive mode (-i) - Writing code directly on Lua prompt
--[[
  -- Do this in the VS code terminal:
  PS D:\River\code\Lua\_lua_guide> lua -i
  Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
  > function fact(n)
  >> return n == 0 and 1 or n * fact(n - 1)
  >> end
  > print(fact(7))
  5040
  > --> Called Ctrl+C to leave
--]]

-- Interactive mode (-i) - Lua prompt using functions from a file
--[[
  -- Type this chunk (piece of code) in this file and save it:
  function factorial(n)
    return n == 0 and 1 or n * factorial(n - 1)
  end

  -- Then do this in the VS code terminal:
  PS D:\River\code\Lua\_lua_guide> lua -i .\prompt.lua
  Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
  > print(factorial(7))
  5040
  > --> Called Ctrl+C to leave
--]]

-- Interactive mode (-i) - Lua prompt using functions from a file setting x = 7 before execute it
--[[
  PS D:\River\code\Lua\_lua_guide> lua -i -lprompt -e 'x = 7'
  Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
  > print(x)
  7
  > --> Called Ctrl+C to leave
--]]

-- arg
--[[
  A script can retrieve its arguments through the predefined global variable arg.
  In a call like `lua script a b c`, the interpreter creates the table arg with all the command-line arguments,
  before running any code.
  The script name goes into index 0; its first argument ("a" in the example) goes to index 1, and so on.
  Preceding options go to negative indices, as they appear before the script.
]]
--[[
  -- Type this chunk (piece of code) in this file and save it:
  print(arg) --> table: 00D49940
  print(arg[-3]) --> C:\Program Files (x86)\Lua\5.1\lua.exe
  print(arg[-2]) --> -e
  print(arg[-1]) --> sin=math.sin
  print(arg[0]) --> prompt.lua
  print(arg[1]) --> hello
  print(arg[2]) --> world
  print(...) --> hello world (... is a vararg expression)
  args = {...} --> unpack all arguments of `arg` inside a table, then assign this value to the `args` variable
  print(args) --> table: 00CC9D38
  print(args[1]) --> hello
  print(args[2]) --> world

  -- Then do this in the VS code terminal:
  lua -e 'sin=math.sin' prompt.lua hello world
--]]
