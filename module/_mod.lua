
local mod = { _version = '7.0.8' } -- The module

local customValue

local function setCustomValue(v) -- Private function
  customValue = v
end

function mod.init(customValue)
  setCustomValue(customValue)
end



function mod.foo()
  print(customValue or 7)
end

return mod
