
dofile('print_r.lua')



--[[
  The effect of the colon is to add an extra argument in a method call and to add an extra hidden parameter in a method definition.
  The colon is only a syntactic facility, although a convenient one; there is nothing really new here.
  We can define a function with the dot syntax and call it with the colon syntax, or viceversa, as long as we handle the extra parameter correctly:
]]
--[[
  Account = {
    balance = 0,
    withdraw = function(self, v)
      self.balance = self.balance - v
    end
  }

  function Account:deposit(v)
    self.balance = self.balance + v
  end

  print(Account.balance) --> 0
  Account.deposit(Account, 200.00)
  Account:withdraw(100.00)
  print(Account.balance) --> 100
  Account.balance = 0
  print(Account.balance) --> 0



  local mt = { __index = Account }

  function Account.new(o)
    o = o or { } -- Create table if user does not provide one
    setmetatable(o, mt)
    return o
  end

  local a = Account.new{ balance = 0 }
  a:deposit(100.00) -- Same as a.deposit(a, 100.0) (the colon is only syntactic sugar)
  print(a.balance) --> 100
  print(Account.balance) --> 0

  --[=[
    Lua cannot find a "deposit" entry in the table a; hence, Lua looks into the __index entry of the metatable.
    The situation now is more or less like this:
  ]=]
  getmetatable(a).__index.deposit(a, 100.00) -- Same as Account.deposit(a, 100.00) or a:deposit(100.0)
  print(a.balance) --> 200
  --[=[
    The metatable of `a` is `mt`, and `mt.__index` is `Account`.
    That is, Lua calls the original deposit function, but passing a as the self parameter.
    So, the new account a inherited the function deposit from Account.
    By the same mechanism, it inherits all fields from Account.

    We can make two small improvements on this scheme.
    The first one is that we do not need to create a new table for the metatable role;
    instead, we can use the Account table itself for that purpose.
    The second one is that we can use the colon syntax for the new method, too.
  ]=]

  function Account:new(o)
    o = o or { }

    self.__index = self
    setmetatable(o, self)

    return o
  end
  --[=[
    Now, when we call Account:new(), the hidden parameter self gets Account as its value,
    we make Account.__index also equal to Account, and set Account as the metatable for the new object.
  ]=]

  local b = Account:new()
  print(b.balance) --> 0

  -- When we call the deposit method on b, it runs the equivalent of the following code, because self is b:
  b.balance = b.balance + 7 -- 7 as an example value
  --[=[
    The expression b.balance (after the assignment) evaluates to 0
    (it is the value from its metatable -- getmetatable(b).__index.balance, which is Account.balance, in this case),
    and the method assigns an initial deposit (7, in this case) to b.balance.
    Before that, balance was not attached to b (getting 0 as the value from its metatable),
    and, now, b has its own balance value, as 7.
    It means, subsequent accesses to b.balance will not invoke the __index metamethod, because now b has its own balance field.
  ]=]
--]]



-- Inheritance

--[[
  Account = { balance = 0 }

  function Account:new(o)
    o = o or { }

    self.__index = self
    setmetatable(o, self)

    return o
  end

  function Account:deposit(v)
    self.balance = self.balance + v
  end

  function Account:withdraw(v)
    if v > self.balance then
      error 'Insufficient funds'
    end

    self.balance = self.balance - v
  end

  --[=[
    From this class, we want to derive a subclass SpecialAccount that allows the customer to withdraw more than his balance.
    We start with an empty class that simply inherits all its operations from its base class:
  ]=]
  SpecialAccount = Account:new()

  -- Up to now, SpecialAccount is just an instance of Account. The magic happens now:
  s = SpecialAccount:new{ limit=1000.00 }
  print(getmetatable(s).__index == Account) --> false
  print(getmetatable(s).__index == SpecialAccount) --> true

  --[=[
    SpecialAccount inherits new from Account, like any other method.
    This time, however, when new executes, its self parameter will refer to SpecialAccount.
    Therefore, the metatable of s will be SpecialAccount, whose value at field __index is also SpecialAccount.
    So, s inherits from SpecialAccount, which inherits from Account.

    Later, when we evaluate s:deposit(100.00), Lua cannot find a deposit field in s,
    so it looks into SpecialAccount; it cannot find a deposit field there, too,
    so it looks into Account; there it finds the original implementation for a deposit.

    What makes a SpecialAccount special is that we can redefine any method inherited from its superclass.
    All we have to do is to write the new method:
  ]=]

  function SpecialAccount:withdraw(v)
    if v - self.balance >= self:getLimit() then
      error 'Insufficient funds'
    end
    self.balance = self.balance - v
  end

  function SpecialAccount:getLimit()
    return self.limit or 0
  end

  --[=[
    Now, when we call s:withdraw(200.00), Lua does not go to Account, because it finds the new withdraw method in SpecialAccount first.
    As s.limit is 1000.00 (remember that we set this field when we created s), the program does the withdrawal, leaving s with a negative balance.

    An interesting aspect of objects in Lua is that we do not need to create a new class to specify a new behavior.
    If only a single object needs a specific behavior, we can implement that behavior directly in the object.
    For instance, if the account s represents some special client whose limit is always 10% of her balance, we can modify only this single account:
  ]=]

  function s:getLimit()
    return self.balance * 0.10
  end

  --[=[
    After this declaration, the call s:withdraw(200.00) runs the withdraw method from SpecialAccount,
    but when withdraw calls self:getLimit, it is this last definition that it invokes.
  ]=]
--]]



-- Multiple inheritance

--[[
  Multiple inheritance means that a class does not have a unique superclass.
  Therefore, we should not use a (super)class method to create subclasses.
  Instead, we will define an independent function for this purpose, createClass, which has as arguments all superclasses of the new class;
  see the code below.

  This function creates a table to represent the new class and sets its metatable with an __index metamethod that does the multiple inheritance.
  Despite the multiple inheritance, each object instance still belongs to one single class, where it looks for all its methods.
  Therefore, the relationship between classes and superclasses is different from the relationship between instances and classes.

  Particularly, a class cannot be the metatable for its instances and for its subclasses at the same time.
  In the code below, we keep the class as the metatable for its instances (as we saw already), and create another table to be the metatable of the class.
]]
--[[
  function createClass(...)
    local class   = { } -- New class
    local parents = {...} -- List of parents (superclasses)

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
    function class:new(o)
      o = o or { }
      setmetatable(o, class) -- Metatable of object is its class
      return o
    end

    return class
  end

  -- Account

  Account = { balance = 0 }

  function Account:deposit(v)
    self.balance = self.balance + v
  end

  function Account:withdraw(v)
    if v > self.balance then
      error 'Insufficient funds'
    end

    self.balance = self.balance - v
  end

  Account = createClass(Account)

  -- Named

  Named = { }

  function Named:getname()
    return self.name
  end

  function Named:setname(n)
    self.name = n
  end

  Named = createClass(Named)

  -- NamedAccount (subclass of both Account and Named)

  NamedAccount = createClass(Account, Named)

  local account = NamedAccount:new{ name = 'River' }
  print(account:getname()) --> River
  account:deposit(2860)
  print(account.balance) --> 2860

  --[=[
    Now let us follow how Lua evaluates the expression account:getname(); more specifically, let us follow the evaluation of account['getname'].

    Lua cannot find the field 'getname' in account (normal table value assigned to `local account`);
    so, it looks for the field __index on the account's metatable, which is NamedAccount in our example.

    But NamedAccount also cannot provide a 'getname' field,
    so Lua looks for the field __index of NamedAccount's metatable.
    Because this field contains a function, Lua calls it.

    This function then looks for 'getname' first in Account, without success,
    and, then, in Named, where it finds a non-nil value, which is the final result of the search.

    Of course, due to the underlying complexity of this search, the performance of multiple inheritance is not the same as single inheritance.
  ]=]
--]]



-- Privacy
--[[
  Many people consider privacy (also called information hiding) to be an integral part of an object-oriented language:
  the state of each object should be its own internal affair. In some object-oriented languages,
  such as C++ and Java, we can control whether a field (also called an instance variable) or a method is visible outside the object.

  The standard implementation of objects in Lua, which we have shown previously, does not offer privacy mechanisms.
  Partly, this is a consequence of our use of a general structure (tables) to represent objects.
  Moreover, Lua avoids redundancy and artificial restrictions.
  If you do not want to access something that lives inside an object, just do not do it.
  A common practice is to mark all private names with an underscore at the end.
  You immediately feel the smell when you see a marked name being used in public.

  Although the basic design for objects in Lua does not offer privacy mechanisms,
  we can implement objects in a different way, to have access control.

  The basic idea of this alternative design is to represent each object through two tables:
  one for its state and another for its operations, or its interface.
  We access the object itself through the second table, that is, through the operations that compose its interface.
  To avoid unauthorized access, the table representing the state of an object is not kept in a field of the other table;
  instead, it is kept only in the closure of the methods.
]]
--[[
  function newAccount(initialBalance)
    -- Hidden, because it is not shared on the returned table
    local self = {
      balance = initialBalance,
      limit = 10000.,
    }

    local function withdraw(v)
      self.balance = self.balance - v
    end

    local function deposit(v)
      self.balance = self.balance + v
    end

    -- Hidden, because it is not shared on the returned table
    local function extra()
      return self.balance > self.limit and self.balance * 0.10 or 0 -- Extra credit of 10% for users with balances above a certain limit
    end

    local function getBalance()
      return self.balance + extra()
    end

    return {
      withdraw = withdraw,
      deposit = deposit,
      getBalance = getBalance
    }
  end

  local acc1 = newAccount(100.)
  acc1.withdraw(30.)
  print(acc1.getBalance()) --> 70

  local acc2 = newAccount(50000.)
  print(acc2.getBalance()) --> 55000 -- 50000 + 5000 (10%)
--]]
--[[
  First, the function creates a table to keep the internal object state and stores it in the local variable self.
  Then, the function creates the methods of the object.
  Finally, the function creates and returns the external object, which maps method names to the actual method implementations.
  The key point here is that these methods do not get self as an extra parameter; instead, they access self directly.
  Because there is no extra argument, we do not use the colon syntax to manipulate such objects.
  We call their methods just like regular functions.

  This design gives full privacy to anything stored in the self table.
  After the call to newAccount returns, there is no way to gain direct access to this table.
  We can access it only through the functions created inside newAccount.
]]



-- Privacy - The Single-Method Approach

--[[
  A particular case of the previous approach for object-oriented programming occurs when an object has a single method.
  In such cases, we do not need to create an interface table; instead, we can return this single method as the object representation.
  If this sounds a little weird, it is worth remembering iterators like io.lines or string.gmatch.
  An iterator that keeps state internally is nothing more than a single-method object.

  Another interesting case of single-method objects occurs when this single-method is actually a dispatch method
  that performs different tasks based on a distinguished argument. A prototypical implementation for such an object is as follows:
]]
--[[
  function newObject(value)
    return function(action, _value) -- (action[, _value])
      if action == 'get' then
        return value

      elseif action == 'set' then
        value = _value

      else
        error 'invalid action'
      end
    end
  end

  local d = newObject(0)
  print(d('get')) --> 0
  d('set', 10)
  print(d('get')) --> 10
--]]
--[[
  This unconventional implementation for objects is quite effective.
  The syntax d("set", 10), although peculiar, is only two characters longer than the more conventional d:set(10).
  Each object uses one single closure, which is usually cheaper than one table.
  There is no inheritance, but we have full privacy:
  the only way to access an object state is through its sole method.
]]



-- Privacy - Dual Representation

--[[
  Usually, we associate attributes to tables using keys, like this (it is not dual representation):
  table[key] = value

  However, we can use a dual representation: we can use a table to represent a key, and use the object itself as a key in that table:
  key = { }
  ...
  key[table] = value

  A key ingredient here is the fact that we can index tables in Lua not only with numbers and strings, but with any value —in particular with other tables.
]]
--[[
  do
    Account = { }

    local balance = { } -- Private

    function Account:withdraw(v)
      balance[self] = balance[self] - v
    end

    function Account:deposit(v)
      balance[self] = balance[self] + v
    end

    function Account:balance()
      return balance[self]
    end

    function Account:new(o)
      o = o or { }

      setmetatable(o, self)
      self.__index = self

      balance[o] = 0 -- Init balance value with a default value

      return o
    end
  end

  print(balance) --> nil

  local a = Account:new{ }
  a:deposit(100.)
  print(a:balance()) --> 100
--]]
--[[
  By keeping the table balance private to the module, this implementation ensures its safety.

  Inheritance works without modifications.
  This approach has a cost quite similar to the standard one, both in terms of time and of memory.
  New objects need one new table and one new entry in each private table being used.
  The access balance[self] can be slightly slower than self.balance, because the latter uses a local variable while the first uses an external variable.
  Usually this difference is negligible.
  As we will see later, it also demands some extra work from the garbage collector.
]]
