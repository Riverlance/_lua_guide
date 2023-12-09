
dofile('print_r.lua')



-- If the function has one single argument and that argument is either a literal string or a table constructor, then the parentheses are optional.
--[[
local function foo(stringOrTable)
  return type(stringOrTable)
end

local s1 = foo 'hello'
local s2 = foo { }

print_r(s1) --> 'string' (string)
print_r(s2) --> 'table' (string)

for _, v in ipairs{ 7, 8, 9 } do
  print(v) --> 7 8 9
end

print(unpack{ 7, 8, 9 }) --> 7 8 9
--]]



-- Base

--[[
  function foo0() end
  function foo1() return 'a' end
  function foo2() return 'a', 'b' end

  function foo(i)
    if i == 0 then
      return foo0()
    elseif i == 1 then
      return foo1()
    elseif i == 2 then
      return foo2()
    end
  end

  local x, y, z -- reset
  x, y = foo2()
  print(x, y) --> a b

  local x, y, z -- reset
  x = foo2()
  print(x, y) --> a nil ('b' is discarded)

  local x, y, z -- reset
  x, y, z = 10, foo2()
  print(x, y, z) --> 10 a b

  local x, y, z -- reset
  x, y = foo0()
  print(x, y) --> nil nil

  local x, y, z -- reset
  x, y = foo1()
  print(x, y) --> a nil

  local x, y, z -- reset
  x, y, z = foo2()
  print(x, y, z) --> a b nil

  local x, y, z -- reset
  x, y = foo2(), 20
  print(x, y) --> a 20 ('b' is discarded)

  local x, y, z -- reset
  x, y = foo0(), 20, 30
  print(x, y) --> nil 20 (30 is discarded)

  print(foo0()) --> (no results)
  print(foo1()) --> a
  print(foo2()) --> a b
  print(foo2(), 1) --> a 1
  print(foo2() .. 'x') --> ax

  print_r({ foo0() }) --> { } (empty table)
  print_r({ foo1() }) --> { 'a' }
  print_r({ foo2() }) --> { 'a', 'b' }
  print_r({ foo0(), foo2(), 4 }) --> { [1] = nil, [2] = 'a', [3] = 4 }

  print(foo(1)) --> a
  print(foo(2)) --> a b
  print(foo(0)) --> (no results)
  print(foo(3)) --> (no results)

  -- We can force a call to return exactly one result by enclosing it in an extra pair of parentheses.
  -- A statement like return (f(x)) always returns one single value, no matter how many values f returns.
  print((foo0())) --> nil
  print((foo1())) --> a
  print((foo2())) --> a

--]]



-- Important note of 'return' statement
--[[
  For syntactic reasons, a return can appear only as the last statement of a block:
  in other words, as the last statement in our chunk or just before an end, an else, or an until.
  For instance, in the next example, return is the last statement of the then block:
  -- if true then return 7 end

  Usually, these are the places where we use a return, because any statement following it would be unreachable.
  Sometimes, however, it may be useful to write a return in the middle of a block;
  for instance, we may be debugging a function and want to avoid its execution.
  In such cases, we can use an explicit do block around the statement:
]]
--[[
  -- Syntax error
  function foo()
    return
    if true then -- unexpected symbol near 'if' (because of the previous 'return' statement)
      print(7)
    end
  end

  -- Syntax OK
  function foo()
    do return end -- OK
    if true then -- unexpected symbol near 'if' (because of the previous 'return' statement)
      print(7)
    end
  end
--]]



-- Protected call
--[[
  function foo()
    local b = false
    if b then
      print(1)
    else
      error('Custom error')
    end
  end

  -- foo()
  -- print(7) -- Cannot print, because foo() has thrown `Custom error`

  pcall(foo)
  print(7) --> 7 -- Prints even knowing that foo() has thrown `Custom error`
--]]



-- As first-class values, higher-order function (callback as parameter, e.g, `table.sort`)

--[[
  _print = print -- Copy `print` callback to `_print`
  print = math.sin -- `print` receives another callback

  _print('Hello, world!') --> Hello, world!
  _print(print(1)) --> 0.8414709848079

  print = _print -- `print` gets the original callback (from `_print`)
  print(math.sin(1)) --> 0.8414709848079
--]]
--[[
  function foo(x) return 2 * x end -- Syntatic sugar - simply pretty way to write the following code:
  foo = function(x) return 2 * x end -- Statement (in the right-side) that creates a value of type `function` and assings it to a variable (`foo`)
--]]

--[[
  Note that, in Lua, all functions are anonymous. Like any other value, they do not have names.
  When we talk about a function name, such as print, we are actually talking about a variable that holds that function.
  Although we often assign functions to global variables, giving them something like a name, there are several occasions when functions remain anonymous (e.g, callback as argument).
  For example, a callback as argument: `table.sort(_table, function(a, b) return a.name > b.name end)` -- Second argument is a callback
  A function that takes another function as an argument, such as table.sort, is what we call a higher-order function, but they have no special rights.
]]



-- Lexical scoping, non-local variable (upvalue), function closure

--[[
  When we write a function enclosed in another function, it has full access to local variables from the enclosing function; we call this feature lexical scoping.
  Suppose we have a list of student names and a table that maps names to grades; we want to sort the list of names according to their grades, with higher grades first.
  We can do this task as follows:
]]
--[[
  names = {"Peter", "Paul", "Mary"}
  grades = {Mary = 10, Paul = 7, Peter = 8}
  function sortbygrade(names, grades)
    table.sort(names, function (n1, n2)
      return grades[n1] > grades[n2] -- compare the grades
    end)
  end
--]]
--[[
  The interesting point in this last example is that the anonymous function given to `sort` accesses `grades`, which is a parameter to the enclosing function `sortbygrade`.
  Inside this anonymous function, `grades` is neither a global variable nor a local variable, but what we call a non-local variable (or upvalue).

  Functions, being first-class values, can escape the original scope of their variables.
  Consider the following code:
]]
--[[
  function newCounter()
    local count = 0 -- non-local variable (or upvalue)
    return function() -- anonymous function
      count = count + 1
      return count
    end
  end

  c1 = newCounter()
  print(c1()) --> 1
  print(c1()) --> 2
  c2 = newCounter() -- See (*1) below
  print(c2()) --> 1
  print(c1()) --> 3
  print(c2()) --> 2
--]]
--[[
  In this code, the anonymous function (in return) refers to a non-local variable (`count`) to keep its counter.
  However, by the time we call the anonymous function, the variable count seems to be out of scope,
  because the function that created this variable (`newCounter`) has already returned.
  Nevertheless, Lua handles this situation correctly, using the concept of closure.
  Simply put, a closure is a function plus all it needs to access non-local variables correctly.
  (*1) If we call newCounter again, it will create a new local variable `count` and a new closure, acting over this new variable.
  So, `c1` and `c2` are different closures. Both are built over the same function, but each acts upon an independent instantiation of the local variable count.
]]

-- Redefinition of a function (like a function decorator of Python)

--[[
  Because functions are stored in regular variables, we can easily redefine functions in Lua, even predefined functions.
  This facility is one of the reasons why Lua is so flexible.
  Frequently, when we redefine a function, we need the original function in the new implementation.
  As an example, suppose we want to redefine the function sin to operate in degrees instead of radians.
  This new function converts its argument and then calls the original function sin to do the real work.
  Our code could look like this:
--]]
--[[
  print(math.sin( math.pi / 2 )) --> 1
  do
    -- Makes a copy (of `math.sin`), but turns it visible only to the `do` scope.
    -- It keeps the old version (maybe an insecure or incomplete version) as a private variable in a closure, inaccessible from the outside.
    -- So the only way to access it, is through the new function of `math.sin`.
    local oldSin = math.sin

    local k = math.pi / 180
    math.sin = function(x)
      return oldSin(x * k)
    end
  end
  print(math.sin(90)) --> 1
--]]
--[[
  We can use this same technique to create secure environments, also called sandboxes.
]]

-- Function decorator (like a function decorator of Python)
-- Note: This is another way to do the same explained in the previous section.

--[[
  function squareResult(callback) -- Acts like a function decorator, as Python
    return function(...)
      local ret = callback(...)
      return ret * ret
    end
  end

  squaredFloor = squareResult(math.floor)
  squaredCeil  = squareResult(math.ceil) -- Function decorator, as Python
  print(squaredFloor(3.5)) --> 9 -- Executes math.floor, then returns its square value
  print(squaredCeil(3.5)) --> 16 -- Executes math.ceil, then returns its square value
--]]



-- Recursion

--[=[
  Lua supports such uses of local functions with a syntactic sugar for them:
  local function f(...) --[[...]] end

  A subtle point arises in the definition of recursive local functions, because the naive approach does not work here.
  Consider the next definition:
]=]
--[[
  local fact = function(n)
    if n == 0 then return 1
    else return n * fact(n - 1) -- buggy - attempt to call global 'fact' (a nil value)
    end
  end
  -- When Lua compiles the call fact(n - 1) in the function body, the local fact is not yet defined.
  -- Therefore, this expression will try to call a global fact, not the local one.
  -- We can solve this problem by first defining the local variable and then the function:
--]]
  -- Fixes:
--[[
  local factA
  factA = function(n)
    if n == 0 then return 1
    else return n * factA(n - 1)
    end
  end

  -- Or even better:
  -- When Lua expands its syntactic sugar for local functions, it does not use the naive definition.
  -- Instead, a definition like:
  local function factB(n)
    if n == 0 then return 1
    else return n * factB(n - 1)
    end
  end
  -- Expands exactly as the factA.
--]]

--[[
  Of course, this trick does not work if we have indirect recursive functions.
  In such cases, we must use the equivalent of an explicit forward declaration:
]]
--[[
    local f -- "forward" declaration

    local function g()
      -- some code
      f()
      -- some code
    end

    function f()
      -- some code
      g()
      -- some code
    end
--]]
--[[
  Beware not to write local in the last definition.
  Otherwise, Lua would create a fresh local variable f, leaving the original f (the one that g is bound to) undefined.
]]
