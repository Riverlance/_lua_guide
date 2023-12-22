
dofile('print_r.lua')



-- Weak tables
-- Metatable with __mode = 'k' == table with weak keys
-- Metatable with __mode = 'v' == table with weak values
-- Metatable with __mode = 'kv' == table with weak keys and values

--[[
  Weak tables are the mechanism that we use to tell Lua that a reference should not prevent the reclamation (being collected by the garbage collector) of an object.
  A weak reference is a reference to an object that is not considered by the garbage collector (which means it will collect them if they are not in use).
  If all references pointing to an object are weak, the collector will collect the object and delete these weak references.
  Lua implements weak references through weak tables: a weak table is a table whose entries are weak.
  This means that, if an object is held only in weak tables, Lua will eventually collect the object.

  Tables have keys and values, and both can contain any kind of object.
  Under normal circumstances, the garbage collector does not collect objects that appear as keys or as values of an accessible table.
  That is, both keys and values are strong references, as they prevent the reclamation of objects they refer to.
  In a weak table, both keys and values can be weak.
  This means that there are three kinds of weak tables:
  1. tables with weak keys,
  2. tables with weak values,
  3. and tables where both keys and values are weak.
  Irrespective of the kind of table, when a key or a value is collected, the whole entry disappears from the table.

  The weakness of a table is given by the field __mode of its metatable.
  The value of this field, when present, should be a string:
  if this string is "k", the keys in the table are weak;
  if this string is "v", the values in the table are weak;
  if this string is "kv", both keys and values are weak.
]]
--[[
  local a = { }
  setmetatable(a, { __mode = 'k' }) -- Now 'a' has weak keys

  local key = { } -- Creates first key
  a[key] = 1
  key = { } -- Creates second key (overwriting the reference of previous 'key' variable)
  a[key] = 2

  collectgarbage() -- Forces a garbage collection cycle (which will collect the overwritten reference of first key)
  for k, v in pairs(a) do
    print(v) --> 2
  end
--]]
--[[
  In this example, the second assignment key = { } overwrites the reference to the first key.
  The call to collectgarbage forces the garbage collector to do a full collection.
  As there is no other reference to the first key, Lua collects this key and removes the corresponding entry in the table.
  The second key, however, is still anchored in the variable key, so Lua does not collect it.

  Notice that only objects can be removed from a weak table.
  Values, such as numbers and Booleans, are not collectible.
  For instance, if we insert a numeric key in the table a (from our previous example), the collector will never remove it.
  Of course, if the value corresponding to a numeric key is collected in a table with weak values, then the whole entry is removed from the table.
]]



-- Weak tables - Memorizing function

--[[
  A common programming technique is to trade space for time.
  We can speed up a function by memorizing its results so that, later, when we call the function with the same argument, the function can reuse that result.
  If the results table has weak values, each garbage-collection cycle will remove all translations not in use at that moment (which means virtually all of them).
  Actually, because the indices are always strings, we can make this table fully weak, if we want (__mode = 'kv'), but the net result is the same.
]]
--[[
  local results = { }
  setmetatable(results, { __mode = 'v' }) -- Make values weak

  function mem_loadstring(s)
    local res = results[s]

    if res == nil then -- Result is not available?
      res = assert(loadstring(s)) -- Assign new result
      results[s] = res -- Save result for later reuse
    end

    return res
  end
  --]]

--[[
  The memorization technique is useful also to ensure the uniqueness of some kind of object.
]]
--[[
  -- function createRGB(r, g, b)
  --   return { red = r, green = g, blue = b }
  -- end

  local results = { }
  setmetatable(results, { __mode = 'v' }) -- Make values weak

  function createRGB(r, g, b)
    local key   = ('%d-%d-%d'):format(r, g, b)
    local color = results[key]

    if color == nil then
      color        = { red = r, green = g, blue = b }
      results[key] = color
    end

    return color
  end

  local a = createRGB(0, 0, 255)
  local b = createRGB(0, 0, 255)
  local c = createRGB(0, 0, 0)
  print(a == b) --> true
  print(a == c) --> false
--]]
--[[
  An interesting consequence of this implementation is that the user can compare colors using the primitive equality operator,
  because two coexistent equal colors are always represented by the same table.
  Any given color can be represented by different tables at different times, because from time to time the garbage collector clears the results table.
  However, as long as a given color is in use, it is not removed from results.
  So, whenever a color survives long enough to be compared with a new one, its representation also has survived long enough to be reused by the new color.
]]



-- Weak tables - Object attributes

--[[
  Another important use of weak tables is to associate attributes with objects.
  There are endless situations where we need to attach some attribute to an object:
  names to functions, default values to tables, sizes to arrays, and so on.

  When the object is a table, we can store the attribute in the table itself, with an appropriate unique key.
  (As we saw before, a simple and error-proof way to create a unique key is to create a new table and use it as the key.)
  However, if the object is not a table, it cannot keep its own attributes.
  Even for tables, sometimes we may not want to store the attribute in the original object.
  For instance, we may want to keep the attribute private, or we do not want the attribute to disturb a table traversal.
  In all these cases, we need an alternative way to map attributes to objects.

  Of course, an external table provides an ideal way to map attributes to objects.
  It is what we called a dual representation.
  We use the external table with objects as keys, and their attributes as values.
  Moreover, attributes kept in an external table do not interfere with other objects, and can be as private as the table itself.

  However, this seemingly perfect solution has a huge drawback: once we use an object as a key in a table, we lock the object into existence.
  Lua cannot collect an object that is being used as a key.
  As you might expect, we can avoid this drawback by using a weak table.
  This time, however, we need weak keys.
  The use of weak keys does not prevent any key from being collected, once there are no other references to it.
  On the other hand, the table cannot have weak values; otherwise, attributes of live objects could be collected.
]]



-- Weak tables - Default values (similarly the metamethod __index, but with weak tables)

-- First solution
--[[
  This is a typical use of a dual representation, where we use defaults[t] to represent a default value of t.
  If the table defaults did not have weak keys, it would anchor all tables with default values into permanent existence.
]]
--[[
local defaults = { }
setmetatable(defaults, { __mode = 'k' }) -- Make keys weak

local mt = {
  __index = function(t)
    return defaults[t]
  end
}
function setDefault(t, d)
  defaults[t] = d
  setmetatable(t, mt)
end

local foo             = { }
local fooDefaultValue = tostring(foo)
setDefault(foo, fooDefaultValue)

print_r(foo.x) --> table: 00A11720
print_r(foo.y) --> table: 00A11720
print_r(defaults) --> (table: 009E11F8) { [table: 009E1270] = "table: 009E1270" (string) }

foo = { } -- Old foo is not in use anymore
collectgarbage() -- Collect garbage, including the old foo
print_r(defaults) --> (table: 009E11F8) { } -- 'defaults' has not the default value of old foo anymore
--]]

-- Second solution
--[[
  In the second solution, we use distinct metatables for distinct default values,
  but we reuse the same metatable whenever we repeat a default value.
  In this case, we use weak values to allow the collection of metatables that are not being used anymore.
]]
--[[
  local metas = { }
  setmetatable(metas, { __mode = 'v' }) -- Make values weak

  function setDefault(t, d)
    metas[d] = metas[d] or { __index = function() return d end } -- Memorize
    setmetatable(t, metas[d])
  end

  local foo             = { }
  local fooDefaultValue = tostring(foo)
  setDefault(foo, fooDefaultValue)

  print_r(foo.x) --> table: 00AC1810
  print_r(foo.y) --> table: 00AC1810
  print_r(metas) --> (table: 00AC1658) { ["table: 00AC1810"] = (table: 00AC1630) { ["__index"] = (function: 009FCD48) } }

  foo = { } -- Old foo is not in use anymore
  collectgarbage() -- Collect garbage, including the old foo
  print_r(metas) --> (table: 00AC1658) { } -- 'metas' has not the default value of old foo anymore
--]]

--[[
  Given these two implementations for default values, which is best?
  As usual, it depends. Both have similar complexity and similar performance.
  The first implementation needs a few memory words for each table with a default value (an entry in defaults).
  The second implementation needs a few dozen memory words for each distinct default value (a new table, a new closure, plus an entry in the table metas).
  So, if your application has thousands of tables with a few distinct default values, the second implementation is clearly superior.
  On the other hand, if few tables share common defaults, then you should favor the first implementation.
]]



-- Weak tables - Ephemeron tables (IMPORTANT!)
-- This is a problem that happens up to Lua 5.1, but was fixed for Lua 5.2+ (with ephemeron tables) -- so it's important to know about this problem, since we still use Lua 5.1.

--[[
  A tricky situation occurs when, in a table with weak keys, a value refers to its own key
  (when the value uses the key reference, like `table[key] = function() return key end` which the function value uses a reference to 'key').

  Let's use an example of a factory (generator) which takes an object and returns a function that, whenever called, returns that object:
  function factory(o)
    return function() return o end
  end
  This factory is a good candidate for memorization, to avoid the creation of a new closure each time used with same parameter value,
  since, with the same parameter value, it would take the memorized return value instead of creating a new function again.

  We can transform it using memorization with weak tables:
]]
--[[
  local mem = { } -- Memorization table
  setmetatable(mem, { __mode = 'k' }) -- Make keys weak

  function factory(o)
    mem[o] = mem[o] or function() return o end -- Solution would be not referencing to `o`, like: function() return 7 end
    return mem[o]
  end

  local k = { }
  local v = factory(k)
  print(v, v()) --> function: 00A81D20    7
  print_r(mem) --> (table: 00A80FF8) { [7] = (function: 00A81D20) }

  k = nil
  v = nil

  collectgarbage()

  print_r(mem) --> (table: 00A80FF8) { [7] = (function: 00A81D20) } -- (not garbage collected, because `factory` has a reference to `o`, which is its own key in `mem` -- mem[o])
--]]
--[[
  There is a catch, however.
  Note that the value (the constant function) associated with an object in mem refers back to its own key (the object itself).
  Although the keys in that table are weak, the values are not.
  These objects would not be collected, despite the weak keys.

  Lua solves the above problem with the concept of ephemeron tables.
  In Lua, a table with weak keys and strong values is an ephemeron table.
  In an ephemeron table, the accessibility of a key controls the accessibility of its corresponding value.
  More specifically, consider an entry (k,v) in an ephemeron table.
  The reference to v is only strong if there is some other external reference to k.
  Otherwise, the collector will eventually collect k and remove the entry from the table, even if v refers (directly or indirectly) to k.

  Note: If you still need to refer the value to its own key, you can use `__mode = 'kv'`, which will force the values to be weak too.
]]



-- Finalizers (__gc metamethod in metatables for Lua 5.2+, but I overwrited the setmetatable to support __gc in Lua 5.1)

--[[
  Although the goal of the garbage collector is to collect Lua objects, it can also help programs to release external resources.
  A finalizer is a function associated with an object that is called when that object is about to be collected.

  Lua implements finalizers through the metamethod __gc, as the following example illustrates:
]]

-- Support to __gc metamethod
do
  local gcProxies = { }

  -- The values in gcProxies are strong because they refer to their own keys.
  -- So, it needs to be forced to have weak values, since we want to remove each entry from gcProxies if its key (metatable) is not in use anymore anywhere.
  setmetatable(gcProxies, { __mode = 'kv' }) -- Make keys and values weak

  local _setmetatable = setmetatable
  function setmetatable(table, metatable)
    if metatable.__gc then
      -- Create an empty userdata (the only values in Lua 5.1 that work with __gc metamethod is userdata).
      -- Then, we insert it in gcProxies (weak table); so when mt is not in use anymore, it will also remove it from gcProxies.
      gcProxies[metatable] = newproxy(true)
      getmetatable(gcProxies[metatable]).__gc = function()
        if type(metatable.__gc) == 'function' then
          metatable.__gc(table) -- __gc from metatable of gcProxies[mt] call __gc from mt
        end
      end
    end
    return _setmetatable(table, metatable)
  end
end

--[[
  In this example, we first create a table and give it a metatable that has a __gc metamethod.
  Then we erase the only link to the table (the global variable o) and force a complete garbage collection.
  During the collection, Lua detects that the table is no longer accessible and, therefore, calls its finalizer -- the __gc metamethod.
]]
--[[
  o = { x = 'hi' }
  setmetatable(o, { __gc = function(o) print(o.x) end })
  o = nil

  collectgarbage() --> hi
--]]

--[[
  A subtlety of finalizers in Lua is the concept of marking an object for finalization.
  We mark an object for finalization by setting a metatable for it with a non-null __gc metamethod.
  If we do not mark the object, it will not be finalized.
  Most code we write works naturally, but some strange cases can occur, like below.

  Here, the metatable we set for o does not have a __gc metamethod, so the object is not marked for finalization.
  Even if we later add a __gc field to the metatable, Lua does not detect that assignment as something special, so it will not mark the object.
  As we said, this is seldom a problem; it is not usual to change metamethods after setting a metatable.
]]
--[[
  o  = { x = 'hi' }
  mt = { }

  setmetatable(o, mt)
  mt.__gc = function(o) print(o.x) end
  o       = nil

  collectgarbage() --> (prints nothing)
--]]

--[[
  If you really need to set the metamethod later, you can provide any value for the __gc field, as a placeholder:
  Now, because the metatable has a __gc field, o is properly marked for finalization.
  There is no problem if you do not set a metamethod later; Lua only calls the finalizer if it is a proper function.
]]
--[[
  o  = { x = 'hi' }
  mt = { __gc = true }

  setmetatable(o, mt)
  mt.__gc = function(o) print(o.x) end
  o       = nil

  collectgarbage() --> hi
--]]

--[[
  When the collector finalizes several objects in the same cycle, it calls their finalizers in the reverse order that the objects were marked for finalization.
  Consider the next example, which creates a linked list of objects with finalizers below.
  The first object to be finalized is object 3, which was the last to be marked.
]]
--[[
  mt = { __gc = function(o) print(o[1]) end }

  list = nil
  for i = 1, 3 do
    list = setmetatable({ i, link = list }, mt)
  end
  list = nil

  collectgarbage() --> 3; 2; 1
--]]

--[[
  Another tricky point about finalizers is resurrection.
  When a finalizer is called, it gets the object being finalized as a parameter.

  So, the object becomes alive again, at least during the finalization.
  I call this a transient resurrection.

  While the finalizer runs, nothing stops it from storing the object in a global variable, for instance, so that it remains accessible after the finalizer returns.
  I call this a permanent resurrection.

  Resurrection must be transitive.
  Consider the following piece of code below.
  The finalizer for B accesses A, so A cannot be collected before the finalization of B.
  Lua must resurrect both B and A before running that finalizer.

  Because of resurrection, Lua collects objects with finalizers in two phases.
  1) The first time the collector detects that an object with a finalizer is not reachable, the collector resurrects the object and queues it to be finalized.
  Once its finalizer runs, Lua marks the object as finalized.
  2) The next time the collector detects that the object is not reachable, it deletes the object.

  If we want to ensure that all garbage in our program has been actually released, we must call collectgarbage twice.
  The second call will delete the objects that were finalized during the first call.
]]
--[[
  A = { x = 'This is A' }
  B = { f = A }

  setmetatable(B, { __gc = function(o) print(o.f.x) end })
  A, B = nil

  collectgarbage() --> This is A
--]]

--[[
  If an object is not collected until the end of a program, Lua will call its finalizer when the entire Lua state is closed.
  This last feature allows a form of atexit functions in Lua, that is, functions that will run immediately before the program terminates.
  All we have to do is to create a table with a finalizer and anchor it somewhere, for instance in a global variable:
]]
--[[
do
  local t = {
    __gc = function()
      -- Your 'atexit' code comes here
      print('Finishing Lua program')
    end
  }
  setmetatable(t, t)

  _G['*ATEXIT*'] = t
end

--> Finishing Lua program
--]]

--[[
  Another interesting technique allows a program to call a given function every time Lua completes a collection cycle.
  As a finalizer runs only once, the trick here is to make each finalization create a new object to run the next finalizer, as the code below.

  The interaction of objects with finalizers and weak tables also has a subtlety.
  At each cycle, the collector clears the values in weak tables before calling the finalizers, but it clears the keys after it.
  The rationale for this behavior is that, frequently, we use tables with weak keys to hold properties of an object (as discussed in object attributes) and,
  therefore, finalizers may need to access those attributes.
  However, we use tables with weak values to reuse live objects; in this case, objects being finalized are not useful anymore.
]]
--[[
do
  local mt = {
    __gc = function(o)
      -- Executes on collectgarbage
      print('New cycle')

      setmetatable({ }, getmetatable(o)) -- Creates new object for next cycle
    end
  }

  -- Creates first object
  setmetatable({ }, mt) --> New cycle
end

collectgarbage() --> New cycle
collectgarbage() --> New cycle
collectgarbage() --> New cycle
--]]
