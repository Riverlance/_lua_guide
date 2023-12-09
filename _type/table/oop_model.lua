
dofile('print_r.lua')



do
  local parentsKey = { } -- Key id to alloc parents on class

  function createClass(class, ...) -- (class[, ...parents...])
    class            = class or { }
    local parents    = {...} -- List of parents (superclasses)
    local allClasses = { } -- Same as the list of parents, but with class as first

    -- Attach parents on class
    class[parentsKey] = parents

    -- Fill allClasses
    allClasses[#allClasses + 1] = class
    for i = 1, #parents do
      allClasses[#allClasses + 1] = parents[i]
    end

    -- Prepare class and its parents
    for i = 1, #allClasses do
      local _class = allClasses[i]

      if not _class.__onNew then
        function _class.__onNew()
          -- Do nothing
        end
      end

      -- __isInstanceOf
      if not _class.__isInstanceOf then
        function _class.__isInstanceOf(obj, classToCompare)
          local mt = getmetatable(obj)
          if mt then
            return mt.__index == classToCompare
          end
          return false
        end
      end

      -- __isChildOf
      if not _class.__isChildOf then
        function _class.__isChildOf(classToCompare)
          local _parents = _class[parentsKey]
          for i = 1, #_parents do
            -- The parent list of actual class contains classToCompare
            if _parents[i] == classToCompare then
              return true
            end
          end
          return false
        end
      end

      -- __isParentOf
      if not _class.__isParentOf then
        function _class.__isParentOf(classToCompare)
          local _parents = classToCompare[parentsKey]
          for i = 1, #_parents do
            -- Actual class is inside the parent list of classToCompare
            if _class == _parents[i] then
              return true
            end
          end
          return false
        end
      end
    end

    -- Metatable of class
    setmetatable(class, {
      -- Class searches for absent methods in its list of parents
      __index = function(t, k)
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
    function class:new(obj, ...) -- (o[, ...optionalData...])
      obj = obj or { }
      setmetatable(obj, class) -- Metatable of object is its class

      -- Callback - on new
      for i = 1, #parents do
        parents[i]:__onNew(obj, ...)
      end
      class:__onNew(obj, ...)

      return obj
    end

    return class
  end
end



---[[
  -- Account
  do -- Needed only if you intent to use private variables like `balance`
    local balance = { } -- Private

    Account = {
      id = 0,
      aDefaultValue = 8,

      __onNew = function(self, obj)
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



  -- Using Account (no inherits)

  local acc = Account:new{ id = 7, customValue = 9 }

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

  -- Using SpecialAccount (inherits from Account)

  local sAcc = SpecialAccount:new{ id = 70 }
  print('\n> sAcc values')
  print(sAcc.id) --> 70
  print(sAcc.aDefaultValue) --> 8
  print(sAcc.customValue) --> nil

  print('\n> __isInstanceOf')
  print(acc:__isInstanceOf(Account)) --> true
  print(acc:__isInstanceOf(SpecialAccount)) --> false
  print(Account == Account) --> true
  print(SpecialAccount == Account) --> false

  print('\n> __isChildOf')
  print(SpecialAccount.__isChildOf(Account)) --> true
  print(Account.__isChildOf(SpecialAccount)) --> false

  print('\n__isParentOf')
  print(Account.__isParentOf(SpecialAccount)) --> true
  print(SpecialAccount.__isParentOf(Account)) --> false



  print('\n> Removing acc')
  acc:onDestroy()
  print(acc:balance()) --> nil
  acc = nil
  print(acc) --> nil
--]]
