
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
    allClasses[i].__onNew = allClasses[i].__onNew or function() end
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

  -- Prepare 'c' to be the metatable of its instances
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

do -- Needed only if you intent to use private variables like `balance`

  -- Account

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
    balance[self] = balance[self] - v
  end

  function Account:balance()
    return balance[self]
  end

  Account = createClass(Account)
end



local account = Account:new{ id = 7, customValue = 9 }
print(account.id) --> 7
print(account.aDefaultValue) --> 8
print(account.customValue) --> 9

-- Working with a private variable
print(balance) --> nil -- (because it is private to the do-end chunk above)
print(account:balance()) --> 0
-- balance[account] = 2860 -- attempt to index global 'balance' (a nil value)
account:deposit(2860)
print(account:balance()) --> 2860
