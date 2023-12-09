# Module & Package

dofile('print_r.lua')



-- Common way to call a function from a module
--[[
  local myMod = require '_mod' -- Same as require('_mod')
  myMod.foo()
--]]

-- Alternative names for a specific function
--[[
  local m = require '_mod'
  local f = m.foo
  f() -- Execute foo()
--]]

-- Import a single function
--[[
  local f = require '_mod'.foo -- Same as (require('_mod')).foo
  f() -- Execute foo()
--]]



-- In case you want your module to have parameters, create an explicit function to set them, like here:
--[[
  local mod = require '_mod'
  mod.init(8)
  mod.foo()
--]]


-- Another approach to write modules (readmore at _mod_2.lua)
-- Note: I prefer the 1st model.
--[[
  local mod = require '_mod_2'
  mod.init(8)
  mod.foo()
--]]
