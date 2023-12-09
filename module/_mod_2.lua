--[[
  Advantages of this approach to write a module:
  - We do not need to write "mod." for each function.
  - There is an explicit export list.
  - We define and use exported and internal functions in the same way inside the module.

  Disadvantages of this approach to write a module:
  - The export list is at the end of the module instead of at the beginning, where it would be more useful as a quick documentation.
  - The export list is somewhat redundant, as we must write each name twice.

  * I prefer the first model.
]]

local customValue

local function setCustomValue(v) -- Private function
  customValue = v
end

local function init(customValue)
  setCustomValue(customValue)
end



local function foo()
  print(customValue or 7)
end

return { -- The module
  _version = '7.0.8',

  init = init,
  foo = foo,
}
