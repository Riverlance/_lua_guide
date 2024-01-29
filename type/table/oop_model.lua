
dofile('print_r.lua')

function string:starts(start)
  return self:sub(1, #start) == start
end

function table.copy(t, keys) -- (t[, keys])
  local ret = { }

  if keys then
    for _, k in ipairs(keys) do
      local v = t[k]
      if type(v) == 'table' then
        ret[k] = table.copy(v)
      else
        ret[k] = v
      end
    end
  else
    for k, v in pairs(t) do
      if type(v) == 'table' then
        ret[k] = table.copy(v)
      else
        ret[k] = v
      end
    end
  end

  local metaTable = getmetatable(t)
  if metaTable then
    setmetatable(ret, metaTable)
  end

  return ret
end



do
  local metaValues    = { } -- Table for the class to alloc meta values that won't be copied with table.copy; internal usage only
  local privateValues = { } -- Table for the user to alloc values that won't be copied with table.copy; useful for subclasses

  function createClass(class, ...) -- (class[, ...parents...])
    local rawValues  = class
    local parents    = {...} -- List of parents (superclasses)
    local allClasses = { } -- Same as the list of parents, but with class as first

    class = table.copy(rawValues) or { }

    assert(type(class) == 'table', "Attempt to create a class with non-table value.")
    do
      local mt = getmetatable(class)
      assert(not mt or not mt.__index, "Attempt to create a class with an index already assigned.")
    end

    metaValues[class]    = { }
    privateValues[class] = { }

    -- Attach raw values
    metaValues[class].rawValues = rawValues

    -- Attach parents
    metaValues[class].parents = parents

    -- Fill allClasses
    allClasses[#allClasses + 1] = class
    for i = 1, #parents do
      allClasses[#allClasses + 1] = parents[i]
    end

    -- Prepare class and its parents
    do
      -- Method - getPrivateValue(key)
      if not class.getPrivateValue then
        function class.getPrivateValue(key)
          return privateValues[class][key]
        end
      end

      -- Method - setPrivateValue(key, value)
      if not class.setPrivateValue then
        function class.setPrivateValue(key, value)
          privateValues[class][key] = value
        end
      end

      -- Method - getRawValues()
      if not class.getRawValues then
        function class.getRawValues()
          return metaValues[class].rawValues
        end
      end

      -- Method - __isInstanceOf
      if not class.__isInstanceOf then
        function class.__isInstanceOf(obj, classToCompare)
          local mt = getmetatable(obj)
          if mt then
            return mt.__index == classToCompare
          end
          return false
        end
      end

      -- Method - __isChildOf
      if not class.__isChildOf then
        function class.__isChildOf(classToCompare)
          local _parents = metaValues[class] and metaValues[class].parents or { }
          for i = 1, #_parents do
            -- The parent list of actual class contains classToCompare
            if _parents[i] == classToCompare then
              return true
            end
          end
          return false
        end
      end

      -- Method - __isParentOf
      if not class.__isParentOf then
        function class.__isParentOf(classToCompare)
          local _parents = metaValues[classToCompare] and metaValues[classToCompare].parents or { }
          for i = 1, #_parents do
            -- Actual class is inside the parent list of classToCompare
            if class == _parents[i] then
              return true
            end
          end
          return false
        end
      end
    end
    for i = 1, #allClasses do -- move to class instead of _class
      local _class = allClasses[i]

      -- Callback - __onCall
      if not _class.__onCall then
        function _class.__onCall()
          return nil
        end
      end

      -- Callback - __onCheckNew
      if not _class.__onCheckNew then
        function _class.__onCheckNew()
          return true
        end
      end

      -- Callback - __onNew
      if not _class.__onNew then
        function _class.__onNew()
          -- Do nothing
        end
      end
    end

    -- Metatable of class
    setmetatable(class, {
      __metatable = 'This metatable is protected.',

      __call = function(self, ...)
        -- Callback - __onCall
        local ret = self:__onCall(...)
        if ret ~= nil then
          return ret
        end
        for i = 1, #parents do
          ret = parents[i].__onCall(self, ...)
          if ret ~= nil then
            return ret
          end
        end
      end,

      -- Class searches for absent methods in its list of parents
      __index = function(self, k)
        -- Look up for 'k' in list of tables 'parents'
        for i = 1, #parents do
          if parents[i][k] then -- If key exists in this parent, return the value of it
            return parents[i][k]
          end
        end
      end
    })

    -- Prepare 'class' to be the metatable of its instances
    class.__index = class

    -- Define a new constructor for this new class
    function class:new(obj, ...) -- (obj[, ...optionalData...])
      obj = obj or { }

      -- obj has to be a table
      assert(type(obj) == 'table', "Attempt to instantiate an object with non-table value.")

      -- Callback - __onCheckNew
      for i = 1, #parents do
        if not parents[i]:__onCheckNew(obj, ...) then
          return nil
        end
      end
      if not class:__onCheckNew(obj, ...) then
        return nil
      end

      setmetatable(obj, class) -- Metatable of object is its class

      -- Duplicate tables of obj (except from variables that the key name starts with '__' and from tables with metatable)
      for k, v in pairs(class) do
        if type(k) == 'string' and not k:starts('__') and type(v) == 'table' and
           not getmetatable(v) and obj[k] == v -- Has not metatable and has v is original value of class
        then
          obj[k] = table.copy(v)
        end
      end

      -- Callback - __onNew
      for i = 1, #parents do
        parents[i]:__onNew(obj, ...)
      end
      class:__onNew(obj, ...)

      return obj
    end

    return class
  end
end

function isInstanceOf(class, classToCompare)
  return getmetatable(class) and class.__isInstanceOf and class:__isInstanceOf(classToCompare)
end

function isChildOf(class, classToCompare)
  return getmetatable(class) and class.__isChildOf and class:__isChildOf(classToCompare)
end

function isParentOf(class, classToCompare)
  return getmetatable(class) and class.__isParentOf and class:__isParentOf(classToCompare)
end



---[[
  -- Account
  do -- Needed only if you intent to use private variables like `balance`
    local balance = { } -- Private

    Account = {
      id            = 0,
      aDefaultValue = 8,
      __classTable  = { 7 },
      objTable      = { 8 },

      __onCall = function(self, value)
        if type(value) == 'number' then
          self.classAttributeValue = value
          return
        end
        return self.classAttributeValue
      end,

      __onCheckNew = function(self, obj, ...)
        -- Cannot have accounts with negative id
        if obj.id < 0 then
          return false
        end
        return true
      end,

      __onNew = function(self, obj, ...)
        balance[obj] = 0
      end
    }

    -- Used to remove the private variables when this account is not used anymore
    function Account:onDestroy()
      balance[self] = nil
    end

    function Account:deposit(v)
      balance[self] = balance[self] + v
    end

    function Account:withdraw(v)
      if v > balance[self] then
        error 'Insufficient funds'
      end

      balance[self] = balance[self] - v
    end

    function Account:balance()
      return balance[self]
    end

    Account = createClass(Account)
  end

  -- SpecialAccount
  -- do-end not needed, because it uses no private variables

  SpecialAccount = { limit = 1000. }

  SpecialAccount = createClass(SpecialAccount, Account)

  -- Named

  Named = { }

  function Named:getname()
    return self.name
  end

  function Named:setname(n)
    self.name = n
  end

  Named = createClass(Named)

  -- NamedAccount (child of both Account and Named)

  NamedAccount = { }
  NamedAccount = createClass(NamedAccount, Account, Named)



  -- Using Account (no inherits)

  local acc  = Account:new{ id = 7, customValue = 9 }
  local acc2 = Account:new{ id = 8 }
  local acc3 = Account:new{ id = -7 } -- Cannot have accounts with negative id, so it will return nil

  print('\n> acc values')
  print(acc.id) --> 7
  print(acc.aDefaultValue) --> 8
  print(acc.customValue) --> 9

  print('\n> Working with a private variable')
  print(balance) --> nil -- (because it is private to the do-end chunk above)
  print(acc:balance()) --> 0
  -- balance[account] = 2860 -- attempt to index global 'balance' (a nil value)
  acc:deposit(2860)
  print(acc:balance()) --> 2860

  print('\n> Function that only the object acc have')
  function acc:getCustomValueStr()
    return ('My custom value is %d.'):format(self.customValue)
  end
  print(acc:getCustomValueStr()) --> My custom value is 9.

  print('\n> Checking a class table')
  print_r(Account.__classTable, acc.__classTable) --> (table: 00B2A5C0){ 7 } (table: 00B2A5C0){ 7 } -- Same table reference
  table.insert(acc.__classTable, 9)
  print_r(Account.__classTable, acc.__classTable) --> (table: 00B2A5C0){ 7, 9 } (table: 00B2A5C0){ 7, 9 } -- Same table reference

  print('\n> Checking a normal table (which is duplicated from class)')
  print_r(Account.objTable, acc.objTable) --> (table: 0092AA58){ 8 } (table: 009206D8){ 8 } -- Different table reference
  table.insert(acc.objTable, 9)
  print_r(Account.objTable, acc.objTable) --> (table: 0092AA58){ 8 } (table: 009206D8){ 8, 9 } -- Different table reference

  print('\n> Usage example of Account.__onCall (Account() to get Account.classAttributeValue; Account(value) to set Account.classAttributeValue)')
  print(Account(), Account.classAttributeValue, acc.classAttributeValue) --> nil nil nil
  Account(777)
  print(Account(), Account.classAttributeValue, acc.classAttributeValue) --> 777 777 777

  print('\n> Usage example of Account.__onCheckNew')
  print(acc3) --> nil



  -- Using SpecialAccount (inherits from Account)

  local sAcc = SpecialAccount:new{ id = 70 }
  print('\n> sAcc values')
  print(sAcc.id) --> 70
  print(sAcc.aDefaultValue) --> 8
  print(sAcc.customValue) --> nil



  -- Using NamedAccount (inherits from Account and Named)

  local nAcc = NamedAccount:new{ id = 777, name = 'River' }
  print('\n> nAcc values')
  print(nAcc:getname()) --> River
  nAcc:deposit(2860)
  print(nAcc:balance()) --> 2860



  print('\n> __isInstanceOf')
  print(acc:__isInstanceOf(Account)) --> true
  print(acc:__isInstanceOf(SpecialAccount)) --> false
  print(Account == Account) --> true
  print(SpecialAccount == Account) --> false

  print('\n> __isChildOf')
  print(SpecialAccount.__isChildOf(Account)) --> true
  print(Account.__isChildOf(SpecialAccount)) --> false

  print('\n> __isParentOf')
  print(Account.__isParentOf(SpecialAccount)) --> true
  print(SpecialAccount.__isParentOf(Account)) --> false

  print('\n> Errors')
  print(getmetatable(acc)) --> table: 00A710B8
  print(getmetatable(Account)) --> This metatable is protected.
  -- setmetatable(Account, { }) --> cannot change a protected metatable
  -- createClass(true) --> Attempt to create a class with non-table value.
  -- Account:new(true) --> Attempt to instantiate an object with non-table value.

  print('\n> Removing acc')
  acc:onDestroy()
  print(acc:balance()) --> nil
  acc = nil
  print(acc) --> nil
--]]
