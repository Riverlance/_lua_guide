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





























































--------------------------------------------------------

--[[

-- Inheritance

function setClass(class, parentClass) -- (class[, parentClass])
  -- class.__className is required
  assert(class.__className, "Parameter '__className' is required.")

  -- Set class metatable
  setmetatable(class, {
    __index = parentClass,
    __call = function(self, instance)
      return setmetatable(instance, { __index = class })
    end
  })

  -- Attach 'is' function
  class[string.format('is%s', class.__className)] = true
end



A = {
  __className = 'A',

  x = 0,
  y = 0,
}

setClass(A)

function A:foo1()
  return string.format('Position(%d, %d)', self.x, self.y)
end



B = {
  __className = 'B',

  kills = 0,
}

setClass(B, A)

function B:foo2()
  return string.format('Kills(%d)', self.kills)
end



C = {
  __className = 'C',

  deaths = 0,
}

setClass(C, A)

function C:foo3()
  return string.format('Deaths(%d)', self.deaths)
end



D = {
  __className = 'D',

  points = 0,
}

setClass(D, C)

function D:foo4()
  return string.format('Points(%d)', self.points)
end



function A:foo5()
  return 'Hello'
end

A.foo = 'Foo'



local a = A{ x = 7 }
print(a.x) -- Prints 7
print(a.y) -- Prints 0
print(a.kills) -- Prints nil
print(a.deaths) -- Prints nil
print(a.points) -- Prints nil
print(a:foo1()) -- Prints Position(7, 0)

local b = B{ x = 8, y = 1 }
print(b.x) -- Prints 8
print(b.y) -- Prints 1
print(b.kills) -- Prints 0
print(b.deaths) -- Prints nil
print(b.points) -- Prints nil
print(b:foo1()) -- Prints Position(8, 1)
print(b:foo2()) -- Prints Kills(0)

local c = C{ x = 9, y = 2 }
print(c.x) -- Prints 9
print(c.y) -- Prints 2
print(c.kills) -- Prints nil
print(c.deaths) -- Prints 0
print(c.points) -- Prints nil
print(c:foo1()) -- Prints Position(9, 2)
print(c:foo3()) -- Prints Deaths(0)

local d = D{ x = 10, y = 3 }
print(d.x) -- Prints 10
print(d.y) -- Prints 3
print(d.kills) -- Prints nil
print(d.deaths) -- Prints 0
print(d.points) -- Prints 0
print(d:foo1()) -- Prints Position(10, 3)
print(d:foo4()) -- Prints Points(0)

print(a:foo5()) -- Prints Hello
print(b:foo5()) -- Prints Hello
print(c:foo5()) -- Prints Hello
print(d:foo5()) -- Prints Hello
print(a.foo) -- Prints Foo
print(b.foo) -- Prints Foo
print(c.foo) -- Prints Foo
print(d.foo) -- Prints Foo

print(a.isA) -- Prints true
print(a.isB) -- Prints nil
print(a.isC) -- Prints nil
print(a.isD) -- Prints nil

print(b.isA) -- Prints true
print(b.isB) -- Prints true
print(b.isC) -- Prints nil
print(b.isD) -- Prints nil

print(c.isA) -- Prints true
print(c.isB) -- Prints nil
print(c.isC) -- Prints true
print(c.isD) -- Prints nil

print(d.isA) -- Prints true
print(d.isB) -- Prints nil
print(d.isC) -- Prints true
print(d.isD) -- Prints true

]]



--[[

function table.copy(t) -- In case you don't have it within your libs
  local ret = { }
  for k,v in pairs(t) do
    if type(v) ~= 'table' then
      ret[k] = v
    else
      ret[k] = table.copy(v)
    end
  end
  local metaTable = getmetatable(t)
  if metaTable then
    setmetatable(ret, metaTable)
  end
  return ret
end

MyClass = {
  t = {},

  new = function()
    local obj = setmetatable({}, { __index = MyClass })

    -- If you don't do that, the table 't' will be the same table for all objects
    -- This happens because tables are copied by reference, so it will not clone it's value; instead, it will get same reference to this table (same table to all)
    -- You need to worry about it just for table values by "fixing" it like that:
    obj.t = table.copy(obj.t) -- Clone table 't'

    return obj
  end,

  insert = function(self, value)
    table.insert(self.t, value)
  end,
}

local player1Cid = 268435457
local player2Cid = 268435458
local player3Cid = 268435459

local obj1 = MyClass.new()
obj1:insert(player1Cid)
obj1:insert(player2Cid)

local obj2 = MyClass.new()
obj2:insert(player1Cid)
obj2:insert(player2Cid)
obj2:insert(player3Cid)

print(#obj1.t) -- value is 2 (without table.copy in "new" function, it would be 5 since is the same table for all objects)
print(#obj2.t) -- value is 3 (without table.copy in "new" function, it would be 5 since is the same table for all objects)

]]
