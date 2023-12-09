
dofile('print_r.lua')

--[[
  All trigonometric functions work in radians.
  We can use the functions deg and rad to convert between degrees and radians.
]]

--[[
  print(math.sin(math.pi / 2 )) --> 1
  print(math.max(10.4, 7, -3, 20)) --> 20
--]]



-- Huge

--[[
  print(math.huge) --> inf
  for i = 1, math.huge do -- Similar to `while true do`
    if i > 1000 then
      break
    end
    print(i)
  end
--]]



-- Random

-- Pseudo-random generator - randomseed
math.randomseed(os.time())
--[[
  We can set a seed for the pseudo-random generator with the function randomseed;
  its numeric sole argument is the seed.
  When a program starts, the system initializes the generator with the fixed seed 1.
  Without another seed, every run of a program will generate the same sequence of pseudo-random numbers.
  For debugging, this is a nice property; but in a game, we will have the same scenario over and over.
  A common trick to solve this problem is to use the current time as a seed, with the call math.randomseed(os.time()).
]]

--[[
  print(math.random()) --> pseudo-random real number in the interval [0, 1)
  print(math.random(7)) --> pseudo-random integer in the interval [1, 7]
  print(math.random(3, 7)) --> pseudo-random integer in the interval [3, 7]
--]]



-- Rounding functions

--[[
  print(math.floor(3.3)) --> 3
  print(math.floor(-3.3)) --> 4
  print(math.ceil(3.3)) --> 4
  print(math.ceil(-3.3)) --> -3
  print(math.modf(3.3)) --> 3
  print(math.modf(-3.3)) --> -3
  print(math.floor(2 ^ 70)) --> 1.1805916207174e+021
]]

-- print(math.maxinteger)
