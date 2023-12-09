
dofile('print_r.lua')

function pack(...)
  return {...}
end



-- pack & unpack

--[[
  -- Table to return list
  local vars = {'a', 'b', 'c'}
  print_r(vars) --> { 'a', 'b', 'c' }
  print(unpack(vars)) --> a b c

  -- Return list to table
  local varsNew1 = pack('a', 'b', 'c')
  local varsNew2 = pack(unpack(vars))
  print_r(varsNew1) --> { 'a', 'b', 'c' }
  print_r(varsNew2) --> { 'a', 'b', 'c' }

  -- Limiting unpack from positions 2 to 3
  print(unpack({'Sun', 'Mon', 'Tue', 'Wed'}, 2, 3)) --> Mon Tue
--]]

--[[
  Although the predefined function unpack is written in C, we could write it also in Lua, using recursion.
  The first time we call it, with a single argument, the parameter i gets 1 and n gets the length of the sequence.
  Then the function returns t[1] followed by all results from unpack(t, 2, n),
  which in turn returns t[2] followed by all results from unpack(t, 3, n), and so on, stopping after n elements.
]]
--[[
  function _unpack(t, i, n)
    i = i or 1
    n = n or #t
    if i <= n then
      return t[i], _unpack(t, i + 1, n)
    end
  end
  local vars = {'a', 'b', 'c'}
  print(_unpack(vars)) --> a b c
  print(_unpack({'Sun', 'Mon', 'Tue', 'Wed'}, 2, 3)) --> Mon Tue
--]]



-- select

--[[
  -- select(index, ...)
  local vars = {'a', 'b', 'c'}
  print(select(1, 'a', 'b', 'c')) --> a b c
  print(select(2, 'a', 'b', 'c')) --> b c
  print(select(3, 'a', 'b', 'c')) --> c
  print(select(1, unpack(vars))) --> a b c
  print(select(2, unpack(vars))) --> b c
  print(select(3, unpack(vars))) --> c
  print(select('#', unpack(vars))) --> 3 (count of arguments, including the nil values)
  print((select(1, unpack(vars)))) --> a
  print((select(2, unpack(vars)))) --> b
  print((select(3, unpack(vars)))) --> c
--]]

--[[
  For few arguments, this second version of add is faster, because it avoids the creation of a new table at each call.
  For more arguments, however, the cost of multiple calls to select with many arguments outperforms the cost of creating a table,
  so the first version becomes a better choice.
  (In particular, the second version has a quadratic cost, because both the number of iterations and the number of arguments
  passed in each iteration grow with the number of arguments.)
]]
--[[
  function addWithSelect(...)
    local s = 0
    for i = 1, select('#', ...) do
      s = s + select(i, ...)
    end
    return s
  end
  print(addWithSelect(3, 4, 10, 25, 12)) --> 54
--]]
