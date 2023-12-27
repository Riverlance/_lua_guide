
dofile('print_r.lua')



-- Generic `for` syntax

--[[
  for var-list in exp-list do
    body
  end

  - var-list is a list of one or more variable names (separated by commas).
  - exp-list is a list of the iterator function, the invariant state, and the initial value for the control variable (separated by commas).
]]
--[[
  for var_1, ..., var_n in exp_list(...) do
    block
  end

  is equivalent to the following code:

  do
    local _func, _state, _var = exp_list(...)
    while true do
      local var_1, ..., var_n = _func(_state, _var)
      _var = var_1

      if _var == nil then
        break
      end

      block
    end
  end
]]



-- First examples

-- My first iterator
--[[
  function values(t) -- Like `ipairs`, but returning its values only
    local i = 0 -- Non-local variable
    return function()
      i = i + 1
      return t[i]
    end
  end

  local t = { 7, 8, ['x'] = 9 }

  -- With `while` (harder)
  local iter = values(t) -- Creates the iterator
  while true do
    local v = iter() -- Call the iterator, returning the next value
    if v == nil then
      break
    end

    print(v) --> 7; 8
  end

  -- With `for` (easier)
  for v in values(t) do
    print(v) --> 7; 8
  end
--]]

-- My first (stateless iterator, meaning we don't use non-local variables)
--[[
  function myiterator(t)
    return function(t, i) -- Same as `ipairs`
      i = i + 1
      if t[i] then
        return i, t[i]
      end
    end, t, 0
  end

  local t = { 7, 8, ['x'] = 9 }

  for i, v in myiterator(t) do
    print(i, v) --> 1 7; 2 8
  end
--]]

-- Linked list (stateless iterator too)
--[[
  function traverseLinkedList(list) -- Like as `pairs`
    return function(list, node)
      if not node then
        return list
      else
        return node.next
      end
    end, list --, nil
  end

  local node1 = { value = 7 }
  local node2 = { value = 8 }
  local node3 = { value = 9 }
  node1.next = node3
  node3.next = node2

  for node in traverseLinkedList(node1) do
    print(node.value, node.next and 'Has next' or 'End of linked list') --> 7 Has next; 9 Has next; 8 End of linked list
  end
--]]

-- Words iterator
--[[
  function string:words()
    local pos = 1 -- Current position in the string
    return function() -- Iterator function
      local word, _pos = self:match('(%w+)()', pos) -- '()' returns the position after the word
      if word then
        pos = _pos -- Next position is after this word
        return word
      end
      return nil
    end
  end

  for w in ('Lorem ipsum dolor sit amet.'):words() do
    print(w) --> Lorem; ipsum; dolor; sit; amet
  end

  local applesCount = 0
  for word in ('apple banana coconut apple coconut banana apple coconut'):words() do
    if word == 'apple' then
      applesCount = applesCount + 1
    end
  end
  print(applesCount) --> 3
--]]



-- True iterator
--[[
  True iterators were popular in older versions of Lua, when the language did not have the for statement.
  How do they compare with generator-style (it means, with `for` keyword) iterators?
  Both styles have approximately the same overhead: one function call per iteration.

  On the one hand, it is easier to write the iterator with true iterators
  (although we can recover this easiness with coroutines, as we will see in the section called “Coroutines as Iterators”).

  On the other hand, the generator style is more flexible.
    First, it allows two or more parallel iterations. (For instance, consider the problem of iterating over two files comparing them word by word.)
    Second, it allows the use of break and return inside the iterator body.

  With a true iterator, a return returns from the anonymous function, not from the function doing the iteration.
  For these reasons, overall I usually prefer generators.
]]

-- Words as a true iterator -- Best option if you need full control of the iterator in an easier way
--[[
  function string:words(f)
    for word in self:gmatch('%w+') do
      f(word) -- Call the function with word as parameter
    end
  end

  ('Lorem ipsum dolor sit amet.'):words(function(word)
    print(word) --> Lorem; ipsum; dolor; sit; amet
  end)

  local applesCount = 0
  ('apple banana coconut apple coconut banana apple coconut'):words(function(word)
    if word == 'apple' then
      applesCount = applesCount + 1
    end
  end)
  print(applesCount) --> 3
--]]



-- next(...)

-- pairs - Option 1 (directly calling `next`)
--[[
  local t = { 7, 8, ['x'] = 9 }

  for k, v in next, t do
    print(k, v) --> 1 7; 2 8; 'x' 9
  end
--]]

-- pairs - Option 2 (short example of pairs implementation)
--[[
  function _pairs(t)
    return next, t, nil
  end

  local t = { 7, 8, ['x'] = 9 }

  for k, v in _pairs(t) do
    print(k, v) --> 1 7; 2 8; 'x' 9
  end
--]]



-- My own `ipairs`

-- ipairs - Option 1 (full implementation) -- Best option if you don't need an implementation of `_ipairs_next`
--[[
  function _ipairs(t)
    return function(t, i)
      i = i + 1

      -- Implement your own `key`/`value` selection logic in place of `next`
      if t[i] then
        return i, t[i]
      end
    end, t, 0 -- iterator, table, starting point
  end

  local t = { 7, 8, ['x'] = 9 }

  for i, v in _ipairs(t) do
    print(i, v) --> 1 7; 2 8
  end
--]]

-- ipairs - Option 2 (full implementation; with `_ipairs_next`) -- Best option if you need an implementation of `_ipairs_next`
--[[
  function _ipairs_next(t, i)
    i = i + 1

    -- Implement your own `key`/`value` selection logic in place of `next`
    if t[i] then
      return i, t[i]
    end
  end
  function _ipairs(t)
    return _ipairs_next, t, 0 -- iterator, table, starting point
  end

  local t = { 7, 8, ['x'] = 9 }

  for i, v in _ipairs(t) do
    print(i, v) --> 1 7; 2 8
  end
  for i, v in _ipairs_next, t, 0 do
    print(i, v) --> 1 7; 2 8
  end
--]]



-- My own `pairs`

-- pairs - Option 1 (full implementation) -- Best option if you don't need an implementation of `_pairs_next`
--[[
  function _pairs(t)
    return function(t, k)
      local v

      -- Implement your own `key`/`value` selection logic in place of `next`
      k, v = next(t, k)
      if v then
        return k, v
      end
    end, t, nil -- iterator, table, starting point
  end

  local t = { 7, 8, ['x'] = 9 }

  for k, v in _pairs(t) do
    print(k, v) --> 1 7; 2 8; 'x' 9
  end
--]]

-- pairs - Option 2 (full implementation; with `_pairs_next`) -- Best option if you need an implementation of `_pairs_next`
--[[
  function _pairs_next(t, k)
    local v

    -- Implement your own `key`/`value` selection logic in place of `next`
    k, v = next(t, k)
    if v then
      return k, v
    end
  end
  function _pairs(t)
    return _pairs_next, t, nil -- iterator, table, starting point
  end

  local t = { 7, 8, ['x'] = 9 }

  for k, v in _pairs(t) do
    print(k, v) --> 1 7; 2 8; 'x' 9
  end
  for k, v in _pairs_next, t do
    print(k, v) --> 1 7; 2 8; 'x' 9
  end
--]]



-- Iterator (not passing table, nor starting point)
--[[
  function table.reverse(t)
    local i = 0
    local n = #t
    return function()
      i = i + 1
      if i <= n then
        local k = n - i + 1
        return k, t[k]
      end
    end
  end

  local t = { 7, 8, ['x'] = 9 }

  for i, v in table.reverse(t) do
    print(i, v) --> 2 8; 1 7
  end

  -- for i, v in table.reverse, t do -- Won't work (infinity loop)
  --   print(i, v)
  -- end
--]]



-- My own iterator (not passing table, nor starting point)
-- Since we don't return `i` (instead of `for i, v in ...`, we use `for v in ...`), it should be implemented internally and is not possible to implement a `next` function

-- ituples
--[[
  function ituples(t) -- Returns tuple as {i, v}
    local i = 0
    return function()
      i = i + 1
      if t[i] then
        return {i, t[i]}
      end
    end
  end

  local t = { 7, 8, ['x'] = 9 }

  for tuple in ituples(t) do
    print_r(tuple) --> {1, 7}; {2, 8}
  end
--]]

-- tuples
--[[
  function tuples(t) -- Returns tuple as {k, v}
    local k
    return function()
      local v
      k, v = next(t, k)
      if v then
        return {k, v}
      end
    end
  end

  local t = { 7, 8, ['x'] = 9 }

  for tuple in tuples(t) do
    print_r(tuple) --> {1, 7}; {2, 8}; {'x', 9}
  end
--]]



-- Traversing tables in order

--[=[
  function sortedpairs(t, sortCallback)
    local mt = getmetatable(t)
    if mt and mt.__sortedpairs then
      return mt.__sortedpairs(t, sortCallback)
    end

    local keys = { }
    for k in pairs(t) do
      keys[#keys + 1] = k
    end

    table.sort(keys, sortCallback)

    local i = 0
    return function()
      i = i + 1
      return keys[i], t[keys[i]] -- key, value
    end
  end

  local t = { ['coconut'] = 8, ['apple'] = 7, ['banana'] = 9 }

  for k, v in sortedpairs(t) do
    print(k, v) --> apple 7; banana 9; coconut 8
  end

  for k, v in sortedpairs(t, function(a, b) return a > b end) do
    print(k, v) --> coconut 8; banana 9; apple 7
  end
--]=]



-- Lua 5.1 - Support to metamethods __ipairs & __pairs

--[[
  -- Support to __ipairs metamethod
  do
    local ipairsDefault = ipairs
    ipairs = function(t)
      local metatable = getmetatable(t)
      if metatable and metatable.__ipairs then
        return metatable.__ipairs(t)
      end
      return ipairsDefault(t)
    end
  end

  -- Support to __pairs metamethod
  do
    local pairsDefault = pairs
    pairs = function(t)
      local mt = getmetatable(t)
      if mt and mt.__pairs then
        return mt.__pairs(t)
      end
      return pairsDefault(t)
    end
  end

  -- Example

  TupleList = { }

  TupleList.__ipairs = function(t) -- Returns tuple as {i, v}
    local i = 0
    return function()
      i = i + 1
      if t[i] then
        return {i, t[i]}
      end
    end
  end

  TupleList.__pairs = function(t) -- Returns tuple as {k, v}
    local k
    return function()
      local v
      k, v = next(t, k)
      if v then
        return {k, v}
      end
    end
  end

  local tupleList = setmetatable({ 7, 8, ['x'] = 9 }, TupleList) -- Object of TupleList

  for tuple in ipairs(tupleList) do
    print_r(tuple) --> {1, 7}; {2, 8}
  end

  for tuple in pairs(tupleList) do
    print_r(tuple) --> {1, 7}; {2, 8}; {'x', 9}
  end
--]]
