# When the interpreter loads a file, it ignores its first line if this line starts with a hash (#).
--[[
  This feature allows the use of Lua as a script interpreter in POSIX systems.
  If we start our script with something like:
  #!/usr/local/bin/lua
  (assuming that the stand-alone interpreter is located at /usr/local/bin)
  then we can call the script directly, without explicitly calling the Lua interpreter.
]]

--[[
  This study is based in the book 'Programming in Lua - 4ed'.

  Subjects that is useful to take a look on book 'Programming in Lua - 4ed' when needed:
  - Part II. Real Programming - Chapter 10. Pattern Matching
  - Part II. Real Programming - Chapter 11. Interlude: Most Frequent Words
  - Part II. Real Programming - Chapter 12. Date and Time
  - Part II. Real Programming - Chapter 14. Data Structures
]]

dofile('print_r.lua')



-- Hello world

--[[
  print('Hello, world.') --> Hello, world.
  print("Hello, world.") --> Hello, world.
  print 'Hello, world.' --> Hello, world.
  print "Hello, world." --> Hello, world.
  os.write('Hello, world.') --> Hello, world. (same as print, but without the endline `\n`)
--]]



-- With or without semicolon

--[[
  print(7) --> 7
  print(8) --> 7

  print(7); print(8) --> 7 8
  x = 7 y = 8 --> ugly, but still valid
  print(x) print(y) --> 7 8
  print(x)print(y) --> 7 8
--]]



-- Commenting chunks (pieces of code)
-- Note: You can easily understand what are chunks by noticing that the 'return' statement can only be at the last line of a chunk.

--[=[
  -- A common trick that we use to comment out a chunk is to enclose the code between --[[ and --]], like here:
  --[[
    print(7)
  --]]

  -- To reactivate the code, we add a single hyphen to the first line:
  ---[[
    print(7)
  --]]
--]=]



-- Include an external file into this file

-- dofile('lib.lua')



-- Precedence

--[[
  Operator precedence in Lua follows the table below, from the higher to the lower priority:

  ^
  unary operators (not # -)
  *     /     %
  +     -
  .. (concatentation)
  <     >     <=    >=    ~=    ==
  and
  or

  When in doubt, always use explicit parentheses.
  It is easier than looking it up in the manual and others will probably have the same doubt when reading your code.
]]



-- Scope

--[[
  local x1, x2 = 7, 8

  do
    local localVar = 100
    print(localVar) --> 100
    print(x1, x2) --> 7 8

    local x3 = 9 -- Local to this scope too
    print(x3) --> 9

    -- Edit x1 and x2
    x1 = localVar + x1
    x2 = localVar + x2
    print(x1, x2) --> 107 108
  end
  print(x1, x2) --> 7 8
  print(localVar) --> nil
  print(x3) --> nil
--]]



-- Local variable

--[[
  local a, b = 1, 10
  if a < b then
    print(a) --> 1
    local a -- '= nil' is implicit
    print(a) --> nil
  end -- ends the block started at 'then'
  print(a, b) --> 1 10 -- Note that `a` is still 1, not `nil`
--]]



-- Set a value on table with an unique key (useful if you are worried about name clashes)

--[[
  local uniquekey = { }
  print(uniquekey) --> table: 00A11308

  local t = { }
  print(t[uniquekey]) --> nil
  t[uniquekey] = 7
  print(t[uniquekey]) --> 7

  print_r(t) --> (table: 00A11420) { [table: 00A11308] = 7 (number) }
--]]



-- Environment

-- Prints all variable of the global environment
--[[
  print(_G._G == _G) --> true

  for k, v in pairs(_G) do
    print(k, v)
  end
--]]

-- loadstring
--[[
  x = 7
  print(loadstring('return x')()) --> 7

  local y = 8
  print(loadstring('return y')()) --> nil -- Because 'y' is not in the _G environment
--]]

-- _G
--[[
  x = 7
  print(_G['x']) --> 7
  print(_G.x) --> 7

  _G.x = 8
  print(x) --> 8

  _G['y'] = 9
  _G['x'] = _G['y'] -- Don't do this. It is just a complicated way to write `x = y`.
  print(x) --> 9
--]]

-- getfield
-- The pattern iterates over all identifiers in f.
--[[
  x = { y = { z = 7 } }
  print(_G['x.y.z']) --> nil

  function getfield(field)
    local value = _G -- Start with the table of globals
    for k in field:gmatch('[%a_][%w_]*') do
      value = value[k]
    end
    return value
  end
  print(getfield('x.y.z')) --> 7
--]]

-- setfield
--[[
  The pattern there captures the field name in the variable w and an optional following dot in the variable d.
  If a field name is not followed by a dot, then it is the last name.
  ]]
--[[
  function getfield(field)
    local value = _G -- Start with the table of globals
    for k in field:gmatch('[%a_][%w_]*') do
      value = value[k]
    end
    return value
  end
  function setfield(field, value)
    local t = _G -- Start with the table of globals
    for k, v in field:gmatch('([%a_][%w_]*)(%.?)') do
      if v == '.' then -- Not last name
        t[k] = t[k] or { } -- Create table if absent
        t = t[k] -- Get above table
      else -- Last name
        t[k] = value -- Do the assignment
      end
    end
  end

  setfield('x.y.z', 7)
  print(x.y.z) --> 7
  print(getfield('x.y.z')) --> 7
--]]



-- Reflection

--[[
  Reflection refers to the ability to dynamically examine and manipulate the structure and behavior of objects, variables, and functions during runtime.
  It allows developers to obtain information about Lua objects, such as their type, methods, properties, and other characteristics, and perform operations based on that knowledge.
  Reflection features include the ability to iterate over tables, query the metatable of an object, access and modify fields dynamically,
  and invoke functions indirectly using their names as strings.

  Reflection is a powerful technique that enables dynamic and flexible programming by allowing Lua scripts to adapt and respond to changing conditions at runtime.
  Usage examples:
  - You could debug, for example, when the code C++ code crashed and you need to debug the values of Lua code through prompt commands.
  - You want to take some extra informations about your code, like how many times a function is executed.
  - Maybe even to build your own debugger.

  Readmore about it in 'Part III. Lua-isms - Chapter 25. Reflection'.
]]










-- Downloading an image from Twitter

--[[
  local http = require('socket.http')

  -- Retrieve the content of a URL
  function downloadFile(address)
    local body, status, header, request = http.request(address) -- address: HTTP support only, not HTTPS
    if body == '' then
      error(('[Error %d] %s'):format(status, request))
    end

    -- Save the content to a file
    local filename = address:match('/(%w+[.]jpg)')
    local file     = assert(io.open(('data/downloads/%s'):format(filename), 'wb')) -- Open in 'binary' mode
    file:write(body)
    file:close()
  end

  downloadFile('https://pbs.twimg.com/media/FdcXkObUAAEDnk3.jpg')
--]]
