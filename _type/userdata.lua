
dofile('print_r.lua')



--[=[
  The userdata type allows arbitrary C data to be stored in Lua variables.
  It has no predefined operations in Lua, except assignment and equality test.
  Userdata are used to represent new types created by an application program or a library written in C.
  For instance, the standard I/O library uses them to represent open files.
]=]

-- 1st usage idea
-- Not a good idea; use { } instead (or function() end, but { } is more legible)
--[[
  -- This creates 2 values with unique keys individually
  -- You can use either { } or newproxy() ({ } is ligther, so it is a better approach)
  local keyA = newproxy()
  local keyB = { } -- Better approach
  local t = {
    [keyA] = 7,
    [keyB] = 8,
  }

  -- The bad news is that you still can find these values by traversing it, like below:
  for k, v in pairs(t) do
    print(('[%s] = %s'):format(dumpvar(k), dumpvar(v))) --> [(userdata: 00BFCBA0)] = 7 (number); [(table: 00C01580) { }] = 8 (number) -- Same idea, but { } is lighter (better approach)
  end
--]]

-- 2nd usage idea
-- Good idea if you don't need to put values inside a table
--[[
  -- Support to table parameter on newproxy
  --[=[
    local proxy = newproxy{ }
    proxy.x = 7
    print(proxy.x) --> 7
    print((newproxy{y=8}).y) --> 8
    print(newproxy(proxy).x) --> 7
  ]=]
  do
    local proxiesData = { }
    setmetatable(proxiesData, { __mode = 'k' }) -- Make keys weak

    local _newproxy = newproxy
    ---@version 5.1
    ---@param proxy boolean|table|userdata
    ---@return userdata
    ---@nodiscard
    function newproxy(proxy)
      if type(proxy) ~= 'table' then
        return _newproxy(proxy)
      end

      local values = proxy

      proxy    = _newproxy(true)
      local mt = getmetatable(proxy)

      function mt.__index(self, k)
        return proxiesData[proxy] and proxiesData[proxy][k] or nil
      end

      function mt.__newindex(self, k, v)
        proxiesData[proxy]    = proxiesData[proxy] or { }
        proxiesData[proxy][k] = v
      end

      -- Copy values to proxiesData
      for k, v in pairs(values) do
        proxy[k] = v
      end

      return proxy
    end
  end

  local myValues = newproxy{ }

  myValues.keyA = 7
  myValues.keyB = 8

  -- The good news is that you cannot find these values by traversing it, like below:
  -- for k, v in pairs(myValues) do end -- attempt to index local 'myValues' (a userdata value)

  print(myValues.keyA) --> 7
  print(myValues.keyB) --> 8

  print((newproxy{keyC=9}).keyC) --> 9
  print(newproxy(myValues).keyA) --> 7
  print(newproxy(myValues).keyB) --> 8
--]]
