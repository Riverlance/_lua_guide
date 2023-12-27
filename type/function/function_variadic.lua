
dofile('print_r.lua')



-- Variadic functions

--[[
  function add(...)
    local s = 0
    for _, v in ipairs{...} do
      s = s + v
    end
    return s
  end

  print(add(3, 4, 10, 25, 12)) --> 54
--]]

--[[
  function foo(...)
    local a, b, c = ...
    print(a, b, c)
  end
  foo(7, 8, 9, 10) --> 7 8 9

  -- Returns all arguments
  function id(...) return ... end
  print(id(7, 8, 9)) --> 7 8 9

  function foo1(...)
    print('printing args:', ...)
    return id(...) -- Returns all arguments
  end
  foo1(7, 8, 9) --> printing args: 7 8 9
--]]

--[[
  -- Writes the result of string.format
  function fwrite(fmt, ...)
    return io.write(string.format(fmt, ...))
  end
  fwrite('The number %d is cool.', 7) --> The number 7 is cool.
--]]
