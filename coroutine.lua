
dofile('print_r.lua')



-- Basics

--[[
  Lua packs all its coroutine-related functions in the table coroutine.
  The function create creates new coroutines.
  It has a single argument, a function with the code that the coroutine will run (the coroutine body).
  It returns a value of type "thread", which represents the new coroutine.
  Often, the argument to create is an anonymous function, like here:
]]
--[[
  local co = coroutine.create(function() print('hi') end)
  print_r(co) --> (thread: 00D089C8)
--]]

--[[
  A coroutine can be in one of four states: suspended, running, normal, and dead.
  We can check the state of a coroutine with the function coroutine.status:
]]
--[[
  local co = coroutine.create(function() print('hi') end)
  print(coroutine.status(co)) --> suspended
--]]

--[[
  When we create a coroutine, it starts in the suspended state; a coroutine does not run its body automatically when we create it.
  The function `coroutine.resume` (re)starts the execution of a coroutine, changing its state from suspended to running:
  (If you run this code in interactive mode, you may want to finish the previous line with a semicolon, to suppress the display of the result from resume.)
]]
--[[
  local co = coroutine.create(function() print('hi') end)
  coroutine.resume(co) --> hi
--]]

--[[
  In this first example, the coroutine body simply prints "hi" and terminates, leaving the coroutine in the dead state:
]]
--[[
  local co = coroutine.create(function() print('hi') end)
  coroutine.resume(co) --> hi
  print(coroutine.status(co)) --> dead
--]]

--[[
  Until now, coroutines look like nothing more than a complicated way to call functions.
  The real power of coroutines stems from the function yield, which allows a running coroutine to suspend its own execution, so that it can be resumed later.
  Let us see a simple example below:
]]
--[[
  -- Now, the coroutine body does a loop, printing numbers and yielding after each print.
  local co = coroutine.create(function()
    for i = 1, 5 do
      print('co', i)
      coroutine.yield()
    end
  end)

  -- When we resume this coroutine, it starts its execution and runs until the first yield.
  coroutine.resume(co) --> co 1

  -- If we check its status, we can see that the coroutine is suspended and, therefore, can be resumed:
  print(coroutine.status(co)) --> suspended

  -- From the coroutine's point of view, all activity that happens while it is suspended is happening inside its call to yield.
  -- When we resume the coroutine, this call to yield finally returns and the coroutine continues its execution until the next yield or until its end:
  coroutine.resume(co) --> co 2
  coroutine.resume(co) --> co 3
  coroutine.resume(co) --> co 4
  coroutine.resume(co) --> co 5
  print(coroutine.status(co)) --> suspended
  coroutine.resume(co) -- prints nothing, because it is the 5th call to yield (after print), lefting the 'for' loop
  print(coroutine.status(co)) --> dead

  -- During the last call to resume, the coroutine body finishes the loop and then returns, without printing anything.
  -- If we try to resume it again, resume returns false plus an error message:
  print(coroutine.resume(co)) --> false    cannot resume dead coroutine
--]]

--[[
  Note that `resume` runs in protected mode, like `pcall`.
  Therefore, if there is any error inside a coroutine, Lua will not show the error message, but, instead, will return it to the `resume` call.

  When a coroutine resumes another, it is not suspended; after all, we cannot resume it.
  However, it is not running either, because the running coroutine is the other one.
  So, its own status is what we call the normal state.
]]

--[[
  A useful facility in Lua is that a pair resume–yield can exchange data.
  The first resume, which has no corresponding yield waiting for it, passes its extra arguments to the coroutine main function:
]]
--[[
  local co = coroutine.create(function(a, b, c)
    print('co', a, b, c + 2) --> co    1    2    5
  end)
  coroutine.resume(co, 1, 2, 3)
--]]

--[[
  A call to coroutine.resume returns, after the true that signals no errors, any arguments passed to the corresponding yield:
]]
--[[
  local co = coroutine.create(function(a, b)
    coroutine.yield(a + b, a - b)
  end)
  print(coroutine.resume(co, 20, 10)) --> true    30    10 -- `resume` sent (20, 10) to the anonymous function as (a, b) and received (30, 10) from `yield`
--]]

--[[
  Symmetrically, coroutine.yield returns any extra arguments passed to the corresponding resume:
]]
--[[
  local co = coroutine.create(function(x)
    print('co1', x) --> co1    hi
    print('co2', coroutine.yield()) --> co2    4    5 -- `yield` returns extra arguments from the corresponding `resume`
    print('co3', x) --> co3    hi -- x of anonymous function is still 'hi'
    return 7
  end)
  print(coroutine.resume(co, 'hi')) --> true -- x = 'hi'
  print()
  print(coroutine.resume(co, 4, 5)) --> true    7 -- Send (4, 5) making `yield` return them
  print()
  print(coroutine.resume(co)) --> false    cannot resume dead coroutine
--]]

--[[
  Finally, when a coroutine ends, any values returned by its main function go to the corresponding resume:
]]
--[[
  local co = coroutine.create(function()
    return 6, 7
  end)
  print(coroutine.resume(co)) --> true 6 7
--]]

--[[
  We seldom use all these facilities in the same coroutine, but all of them have their uses.

  Although the general concept of coroutines is well understood, the details vary considerably.
  So, for those that already know something about coroutines, it is important to clarify these details before we go on.
  Lua offers what we call asymmetric coroutines.
  This means that it has a function to suspend the execution of a coroutine and a different function to resume a suspended coroutine.
]]



-- Resume of above

--[[
  local co = coroutine.create(function(x, y) -- (x, y) == ('X', 'Y')
    -- 1st `resume`
    print(x, y) --> 1st print:    X    Y
    local a, b = coroutine.yield('hi') -- (a, b) == (7, 8)

    -- 2nd `resume`
    print(a, b) --> 3rd print:    7    8
    local c = coroutine.yield(x:lower(), y:lower()) -- (c) == (nil)

    print(c) --> 5th print:    nil
    print(x, y) --> 6th print:    X    Y

    return 9
  end)

  -- 1st `resume`
  --[=[
    1. Start the coroutine. The `resume` extra arguments ('X', 'Y') will be arguments of anonymous function (x, y).
    2. Continue execution of coroutine until find 1st `yield`. Get arguments of 1st `yield` ('hi') as extra return values of `resume`.
    3. Stop the coroutine execution at the 1st `yield` position.
  ]=]
  print(coroutine.resume(co, 'X', 'Y')) --> 2nd print:    true    'hi'
  print()

  -- 2nd `resume`
  --[=[
    1. Start the coroutine at the 1st `yield` position, still using ('X', 'Y') as arguments of anonymous function (x, y).
    2. 1st `yield` returns the `resume` extra arguments (7, 8), which is assigned to (a, b).
    3. Continue execution of coroutine until find 2nd `yield`. Get arguments of 2nd `yield` (x:lower(), y:lower()) as extra return values of `resume`.
    4. Stop the coroutine execution at the 2nd `yield` position.
  ]=]
  print(coroutine.resume(co, 7, 8)) --> 4th print:    true    x    y
  print()

  -- 3rd `resume`
  --[=[
    1. Start the coroutine at the 2nd `yield` position, still using ('X', 'Y') as arguments of anonymous function (x, y).
    2. 2nd `yield` returns the `resume` extra arguments (nil), which is assigned to (c).
    3. Continue execution of coroutine until find `return`. Get arguments of `return` (9) as extra return values of `resume`.
    4. Kill the coroutine.
  ]=]
  print(coroutine.resume(co)) --> 7th print:    true    9
  print()

  -- 4th `resume`: The coroutine is already dead.
  print(coroutine.resume(co)) --> 8th print:    false    cannot resume dead coroutine
--]]

-- Example - Coroutines which counts by themselves

--[[
  -- Coroutine A which counts up to 4
  local coA = coroutine.create(function()
    for i = 1, 4 do
      print(('coA %d'):format(i))
      coroutine.yield()
    end
  end)

  -- Coroutine B which counts up to 4
  local coB = coroutine.create(function()
    for i = 1, 4 do
      print(('coB %d'):format(i))
      coroutine.yield()
    end
  end)

  for i = 1, 4 do
    coroutine.resume(coA) -- coA 1; coA 2; coA 3; coA 4
    coroutine.resume(coB) -- coB 1; coB 2; coB 3; coB 4
  end
--]]
--[[
  -- Coroutine A which counts up to 4
  local coA = coroutine.create(function()
    for i = 1, 4 do
      coroutine.yield(i)
    end
  end)

  -- Coroutine B which counts up to 4
  local coB = coroutine.create(function()
    for i = 1, 4 do
      coroutine.yield(i)
    end
  end)

  for i = 1, 4 do
    local statusA, iA = coroutine.resume(coA)
    local statusB, iB = coroutine.resume(coB)
    print(('coA %d'):format(iA)) -- coA 1; coA 2; coA 3; coA 4
    print(('coB %d'):format(iB)) -- coB 1; coB 2; coB 3; coB 4
  end
--]]
--[[
  -- Coroutine A which counts up to 4
  local coA = coroutine.wrap(function()
    for i = 1, 4 do
      coroutine.yield(i)
    end
  end)

  -- Coroutine B which counts up to 4
  local coB = coroutine.wrap(function()
    for i = 1, 4 do
      coroutine.yield(i)
    end
  end)

  for i = 1, 4 do
    print(('coA %d'):format(coA())) -- coA 1; coA 2; coA 3; coA 4
    print(('coB %d'):format(coB())) -- coB 1; coB 2; coB 3; coB 4
  end
--]]

-- Example - Coroutines with temporary actions (just for simulation)

--[[
  local function sleep(seconds)
    os.execute(('ping -n %d 127.0.0.1 >NUL'):format(tonumber(seconds)))
  end

  -- Coroutine A with temporary actions
  local coA = coroutine.wrap(function()
    local time = 9
    print('coA - Initialized.\n')

    print(('coA - Waiting %d seconds...\n'):format(time))
    sleep(time)

    print('coA - Doing something and, then, stops.\n')
    coroutine.yield()

    print(('coA - Back to work, waiting %d seconds again...\n'):format(time))
    sleep(time)

    print(('coA - Printing time value: %d\n'):format(time))
  end)

  -- Coroutine B with temporary actions
  local coB = coroutine.wrap(function()
    local time = 11
    print('coB - Initialized.\n')

    print(('coB - Waiting %d seconds...\n'):format(time))
    sleep(time)

    print('coB - Doing something and, then, stops.\n')
    coroutine.yield()

    print(('coB - Back to work, waiting %d seconds again...\n'):format(time))
    sleep(time)

    print('coB - Doing something again and, then, stops.\n')
    coroutine.yield()

    print(('coB - Printing time value: %d\n'):format(time))
  end)

  coA()
  coB()

  coA()
  coB()

  coB()
--]]



-- Example - 'Who is the boss?'

--[[
  One of the most paradigmatic examples of coroutines is the producer–consumer problem.
  Let us suppose that we have a function that continually produces values (e.g., reading them from a file)
  and another function that continually consumes these values (e.g., writing them to another file).
  These two functions could look like the code below.

  (To simplify this example, both the producer and the consumer run forever.
  It is not hard to change them to stop when there is no more data to handle.)

  The problem here is how to match send with receive.
  It is a typical instance of the “who-has-the-main-loop” problem.
  Both the producer and the consumer are active, both have their own main loops, and both assume that the other is a callable service.
  For this particular example, it is easy to change the structure of one of the functions, unrolling its loop and making it a passive agent.
  However, this change of structure may be far from easy in other real scenarios.

  Coroutines provide an ideal tool to match producers and consumers without changing their structure,
  because a resume–yield pair turns upside-down the typical relationship between the caller and its callee.
  When a coroutine calls yield, it does not enter into a new function; instead, it returns a pending call (to resume).
  Similarly, a call to resume does not start a new function, but returns a call to yield.
  This property is exactly what we need to match a send with a receive in such a way that each one acts as if it were the master and the other the slave.
  (That is why I called this the "who-is-the-boss" problem.)
  So, receive resumes the producer, so that it can produce a new value; and send yields the new value back to the consumer.

  In this design, the program starts by calling the consumer.
  When the consumer needs an item, it resumes the producer, which runs until it has an item to give to the consumer,
  and, then, stops until the consumer resumes it again.
  Therefore, we have what we call a consumer-driven design.

  Another way to write the program is to use a producer-driven design, where the consumer is the coroutine (instead of the producer, as in the previous example).
  Although the details seem reversed, the overall idea of both designs is the same.
]]
--[[
  function receive()
    local status, value = coroutine.resume(producer)
    return value
  end

  function send(x)
    coroutine.yield(x)
  end

  function producer()
    while true do
      local x = io.read() -- Produce new value
      send(x) -- Send it to consumer
    end
  end

  function consumer()
    while true do
      local x = receive() -- Receive value from producer
      print(x) -- Consume it
    end
  end

  -- Of course, the producer must now run inside a coroutine
  producer = coroutine.create(producer)

  -- Starts program
  consumer() -- Main, while the producer is the coroutine
--]]



-- Example - 'Who is the boss?' with filters

--[[
  We can extend this design with filters, which are tasks that sit between the producer and the consumer doing some kind of transformation in the data.
  A filter is a consumer and a producer at the same time, so it resumes a producer to get new values and yields the transformed values to a consumer.
  As a trivial example, we can add to our previous code a filter that inserts a line number at the beginning of each line.

  Its last line simply creates the components it needs, connects them, and starts the final consumer.

  If you thought about POSIX pipes after reading the previous example, you are not alone.
  After all, coroutines are a kind of (non-preemptive) multithreading.

  With pipes, each task runs in a separate process; with coroutines, each task runs in a separate coroutine.
  Pipes provide a buffer between the writer (producer) and the reader (consumer) so there is some freedom in their relative speeds.

  This is important in the context of pipes, because the cost of switching between processes is high.
  With coroutines, the cost of switching between tasks is much smaller (roughly equivalent to a function call), so the writer and the reader can run hand in hand.
]]
--[[
  function receive(producer)
    local status, value = coroutine.resume(producer)
    return value
  end

  function send(x)
    coroutine.yield(x)
  end

  function producer()
    return coroutine.create(function()
      while true do
        local x = io.read() -- Produce new value
        send(x)
      end
    end)
  end

  function filter(producer)
    return coroutine.create(function()
      for line = 1, math.huge do
        local x = receive(producer) -- Get new value
        x = ('%5d %s'):format(line, x)
        send(x) -- Send it to consumer
      end
    end)
  end

  function consumer(prod)
    while true do
      local x = receive(prod) -- Get new value
      io.write(x, '\n') -- Consume new value
    end
  end

  consumer(filter(producer()))
--]]



-- Coroutines as iterators

--[[
  We can see loop iterators as a particular example of the producer–consumer pattern:
  an iterator produces items to be consumed by the loop body.
  Therefore, it seems appropriate to use coroutines to write iterators.
  Indeed, coroutines provide a powerful tool for this task.
  Again, the key feature is their ability to turn inside out the relationship between caller and callee.

  With this feature, we can write iterators without worrying about how to keep state between successive calls.
]]

--[[
  To illustrate this kind of use, let us write an iterator to traverse all permutations of a given array.
  It is not an easy task to write directly such an iterator, but it is not so difficult to write a recursive function that generates all these permutations.
  The idea is simple: put each array element in the last position, in turn, and recursively generate all permutations of the remaining elements.
]]
--[[
  local function printResult(a)
    print(table.concat(a, ' '))
  end

  function permutationsGenerator(a, n)
    n = n or #a -- Default for 'n' is size of 'a'

    if n > 1 then -- Anything to change?
      for i = 1, n do
        -- Put i-th element as the last one
        a[n], a[i] = a[i], a[n]

        -- Generate all permutations of the other elements
        permutationsGenerator(a, n - 1)

        -- Restore i-th element
        a[n], a[i] = a[i], a[n]
      end
      return
    end

    --[=[
      > After we have the generator ready, it is an automatic task to convert it to an iterator.
      First, we change printResult to yield.
    ]=]
    -- printResult(a) -- old
    coroutine.yield(a) -- new
  end

  --[=[
    > Then, we define a factory that arranges for the generator to run inside a coroutine and creates the iterator function.
    The iterator simply resumes the coroutine to produce the next permutation:
  ]=]
  --[=[
  function permutations(a)
    local co = coroutine.create(function() permutationsGenerator(a) end)
    return function() -- iterator
      local code, res = coroutine.resume(co)
      return res
    end
  end
  --]=]

  --[=[
    > The function permutations uses a common pattern in Lua, which packs a call to resume with its corresponding coroutine inside a function.
    This pattern is so common that Lua provides a special function for it: coroutine.wrap.
    Like create, wrap creates a new coroutine.
    Unlike create, wrap does not return the coroutine itself; instead, it returns a function that, when called, resumes the coroutine.
    Unlike the original resume, that function does not return an error code as its first result; instead, it raises the error in case of error.
    Using wrap, we can write permutations as follows:

    Usually, coroutine.wrap is simpler to use than coroutine.create.
    It gives us exactly what we need from a coroutine: a function to resume it.
    However, it is also less flexible.
    There is no way to check the status of a coroutine created with wrap.
    Moreover, we cannot check for runtime errors.
  ]=]
  function permutations(a)
    return coroutine.wrap(function() permutationsGenerator(a) end)
  end

  -- -- With this machinery in place, it is trivial to iterate over all permutations of an array with a `for` statement:
  -- for p in permutations{ 1, 2, 3 } do
  --   printResult(p)
  -- end
--]]
