--[[
  To compile, use this:
  luac -o .\_precompiled_code.lc .\_precompiled_code.lua
  To execute, use this:
  lua .\_precompiled_code.lc

  You can also import it inside another file with:
  dofile('_precompiled_code.lc')
]]

function foo(x)
  return x
end

print(foo(7)) --> 7
