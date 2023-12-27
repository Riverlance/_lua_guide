--[[
The Boolean type has two values, false and true, which represent the traditional Boolean values.
However, Booleans do not hold a monopoly of condition values: in Lua, any value can represent a condition.
Conditional tests (e.g., conditions in control structures) consider both the Boolean false and nil as false
and anything else as true.
In particular, Lua considers both zero and the empty string as true in conditional tests.
]]



-- Ternary operand

--[[
Lua supports a conventional set of logical operators: and, or, and not.
Like control structures, all logical operators consider both the Boolean false and nil as false,
and anything else as true.
The result of the and operator is its first operand if that operand is false;
otherwise, the result is its second operand.
The result of the or operator is its first operand if it is not false;
otherwise, the result is its second operand.
]]
--[[
  print(4 and 5) --> 5
  print(nil and 13) --> nil
  print(false and 13) --> false
  print(0 or 5) --> 0
  print(false or 'hi') --> 'hi'
  print(nil or false) --> false
--]]

-- A useful Lua idiom is `x = x or v`, which is equivalent to `if not x then x = v end`.
-- Another useful idiom is ((a and b) or c) or simply (a and b or c) (given that and has a higher precedence than or).
-- E.g., x > y and x or y results x if x is higher than y, otherwise results y.

-- The `not` operation always gives a Boolean value:
--[[
  print(not nil) --> true
  print(not false) --> true
  print(not 0) --> false
  print(not not 1) --> true
  print(not not nil) --> false
--]]
