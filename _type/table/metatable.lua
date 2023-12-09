
dofile('print_r.lua')

-- Support to __len metamethod
do
  -- string (works only for `string:len()`, not for # symbol)
  local stringLenDefault = string.len
  string.len = function(data)
    data     = tostring(data)
    local mt = getmetatable(data)
    if mt and mt.__len then
      return mt.__len(data)
    end
    return stringLenDefault(data)
  end

  -- table (works only for `table.getn`, not for # symbol)
  local tableGetnDefault = table.getn
  table.getn = function(t)
    local mt = getmetatable(t)
    if mt and mt.__len then
      return mt.__len(t)
    end
    return tableGetnDefault(t)
  end
end



--[[
  Each value in Lua can have a metatable.
  Tables and userdata have individual metatables; values of other types share one single metatable for all values of that type.
  Lua always creates new tables without metatables:

  t = { } -- Arbitrary table
  print(getmetatable(t)) --> nil

  We can use setmetatable to set or change the metatable of a table:
  t  = { } -- Arbitrary table
  t1 = { } -- metatable
  setmetatable(t, t1)
  print(getmetatable(t) == t1) --> true

  The string library sets a metatable for strings; all other types by default have no metatable:
  print(getmetatable('hi')) --> table: 00709CF0
  print(getmetatable('xoxo')) --> table: 00709CF0

  Any table can be the metatable of any value;
  a group of related tables can share a common metatable, which describes their common behavior;
  a table can be its own metatable, so that it describes its own individual behavior.
  Any configuration is valid.
]]



--[[
  The functions setmetatable and getmetatable also use a metafield, in this case to protect metatables, so that users can neither see nor change their metatables.
  If we set a __metatable field in the metatable, getmetatable will return the value of this field, whereas setmetatable will raise an error:
]]
--[[
  local t  = { } -- Arbitrary table
  local mt = { } -- metatable

  setmetatable(t, mt)
  print(getmetatable(t)) --> table: 00AA9D18

  mt.__metatable = 'This metatable is protected.' -- Protects the metatable
  print(getmetatable(t)) --> This metatable is protected.

  -- setmetatable(t, { }) --> error: cannot change a protected metatable
--]]



-- The __index metamethod

--[[
  When we access an absent field in a table, the result is nil.
  This is true, but it is not the whole truth.
  Actually, such accesses trigger the interpreter to look for an __index metamethod:
  if there is no such method, as usually happens, then the access results in nil; otherwise, the metamethod will provide the result.
]]
--[[
  Window           = { } -- Create namespace
  Window.prototype = { x = 0, y = 0, width = 100, height = 100 } -- Create the prototype with default values
  Window.mt        = { } -- Metatable

  function Window.mt.__index(self, key) -- Provides default values for any object of Window
    return Window.prototype[key]
  end

  function Window.new(obj)
    setmetatable(obj, Window.mt)
    return obj
  end

  local w = Window.new{ x = 10, y = 20 }

  print(w.x, w.y) --> 10 20
  print(w.width, w.height) --> 100 100
--]]

-- Or like this:
--[[
  Window            = { } -- Create namespace
  Window.prototype  = { x = 0, y = 0, width = 100, height = 100 } -- Create the prototype with default values
  Window.mt         = { } -- Metatable
  Window.mt.__index = Window.prototype

  function Window.new(obj)
    setmetatable(obj, Window.mt)
    return obj
  end

  local w = Window.new{ x = 10, y = 20 }

  print(w.x, w.y) --> 10 20
  print(w.width, w.height) --> 100 100
--]]

--[[
  The use of a table as an __index metamethod provides a fast and simple way of implementing single inheritance.
  A function, although more expensive, provides more flexibility: we can implement multiple inheritance, caching, and several other variations.
]]

--[[
  When we want to access a table without invoking its __index metamethod, we use the function rawget.
  The call rawget(t, i) does a raw access to table t, that is, a primitive access without considering metatables.
  Doing a raw access will not speed up our code (the overhead of a function call kills any gain we could have), but sometimes we need it, as we will see later.
]]

--[[
  Window            = { } -- Create namespace
  Window.prototype  = { x = 0, y = 0, width = 100, height = 100 } -- Create the prototype with default values
  Window.mt         = { } -- Metatable
  Window.mt.__index = Window.prototype

  function Window.new(obj)
    setmetatable(obj, Window.mt)
    return obj
  end

  local w = Window.new{ x = 10, y = 20 }

  print(w.x, w.y) --> 10 20
  print(w.width, w.height) --> 100 100
  print(rawget(w, 'x'), rawget(w, 'y')) --> 10 20
  print(rawget(w, 'width'), rawget(w, 'height')) --> nil nil -- Get the real value, ignoring the default values of our prototype
--]]



-- The __newindex metamethod

--[[
  The __newindex metamethod does for table updates what __index does for table accesses.
  When we assign a value to an absent index in a table, the interpreter looks for a __newindex metamethod:
  if there is one, the interpreter calls it instead of making the assignment.
  Like __index, if the metamethod is a table, the interpreter does the assignment in this table, instead of in the original one.
  Moreover, there is a raw function that allows us to bypass the metamethod: the call rawset(t, k, v) does the equivalent to t[k] = v without invoking any metamethod.

  The combined use of the __index and __newindex metamethods allows several powerful constructs in Lua,
  such as read-only tables, tables with default values, and inheritance for object-oriented programming.
]]

--[[
  Window            = { } -- Create namespace
  Window.prototype  = { x = 0, y = 0, width = 100, height = 100 } -- Create the prototype with default values
  Window.mt         = { } -- Metatable
  Window.mt.__index = Window.prototype

  function Window.mt.__newindex(self, k, v)
    print(('Setting key `%s` with the value `%s`'):format(k, v)) --> Setting key `z` with the value `0`
    -- self[k] = v -- Do not do that, it would cause a stackoverflow calling __newindex repeatedly. Do the following code below instead:
    rawset(self, k, v) -- Set value without invoking __newindex (without, it would be read-only, since you would not be allowed to edit values)
  end

  function Window.new(obj)
    setmetatable(obj, Window.mt)
    return obj
  end

  local w = Window.new{ x = 10, y = 20 }

  print(w.x, w.y) --> 10 20
  print(w.width, w.height) --> 100 100
  print(rawget(w, 'x'), rawget(w, 'y')) --> 10 20
  print(rawget(w, 'width'), rawget(w, 'height')) --> nil nil -- Get the real value, ignoring the default values of our prototype

  w.z = 0
  print(w.z) --> 0
  w.z = nil
  print(w.z) --> nil
  Window.prototype.z = 0
  print(w.z) --> 0
--]]



-- Read-only tables (only for simple tables, not classes)

--[[
  It is easy to adapt the concept of proxies to implement read-only tables.
  All we have to do is to raise an error whenever we track any attempt to update the table.
  For the __index metamethod, we can use a table — the original table itself — instead of a function, as we do not need to track queries;
  it is simpler and rather more efficient to redirect all queries to the original table.
  This use demands a new metatable for each read-only proxy, with __index pointing to the original table:
]]
--[[
  function readOnly(t)
    local proxy = { }
    setmetatable(proxy, {
      __index = t,
      __newindex = function(self, k, v)
        error('attempt to update a read-only table')
      end,
      __len = function (_t)
        return #t
      end,
    })
    return proxy
  end

  days = readOnly{'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'}

  -- Read a value
  print(days[1]) --> Sunday

  -- Attempt to set a value
  -- days[2] = 'Noday' --> attempt to update a read-only table

  -- Size - table.getn
  -- print(#days) --> 0 (wrong; don't use it if you use a proxy table; use `table.getn(t)` instead)
  print(table.getn(days)) --> 7
--]]
