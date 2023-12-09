
dofile('print_r.lua')



function createClass(class, ...) -- (class[, ...parents...])
  class            = class or { }
  local parents    = {...} -- List of parents (superclasses)
  local allClasses = { } -- Same as the list of parents, but with class as first

  -- Fill allClasses
  allClasses[#allClasses + 1] = class
  for i = 1, #parents do
    allClasses[#allClasses + 1] = parents[i]
  end

  -- Prepare class and its parents
  for i = 1, #allClasses do
    local _class = allClasses[i]
    _class.__onNew = _class.__onNew or function() end
    _class.__is    = _class.__is or function(classOrObj, _classOrObj, classCheck)
      if classCheck then
        return classOrObj == _classOrObj
      end
      local mt = getmetatable(classOrObj)
      if mt then
        return mt.__index == _classOrObj
      end
      return false
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
print(acc.id) --> 7
print(acc.aDefaultValue) --> 8
print(acc.customValue) --> 9

-- Working with a private variable
print(balance) --> nil -- (because it is private to the do-end chunk above)
print(acc:balance()) --> 0
-- balance[account] = 2860 -- attempt to index global 'balance' (a nil value)
acc:deposit(2860)
print(acc:balance()) --> 2860

-- Using SpecialAccount (inherits from Account)

local sAcc = SpecialAccount:new{ id = 70 }
print(sAcc.id) --> 70
print(sAcc.aDefaultValue) --> 8
print(sAcc.customValue) --> 9

-- __is
print(acc:__is(Account)) --> true
print(acc:__is(SpecialAccount)) --> false
print(Account:__is(Account, true)) --> true
print(SpecialAccount:__is(Account, true)) --> false
