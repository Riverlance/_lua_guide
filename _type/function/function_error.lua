
dofile('print_r.lua')



-- Error - Introduction

--[[
  Any unexpected condition that Lua encounters, raises an error.
  Errors occur, for example, when a program tries to add values that are not numbers, call values that are not functions, index values that are not tables, and so on.
  (We can modify this behavior using metatables, as we will see later.)
  We can also explicitly raise an error calling the function `error`, with an error message as an argument.
  Usually, this function is the appropriate way to signal errors in our code:
]]

--[[
  print 'enter a number:'
  n = io.read('*n')
  if not n then
    error('invalid input')
  end
  print(('You typed: %d'):format(n)) --> You typed: 7
--]]

-- Or with assertion:
--[[
  print 'enter a number:'
  n = assert(io.read('*n'), 'invalid input')
  print(('You typed: %d'):format(n)) --> You typed: 7
--]]

--[[
  When a function finds an unexpected situation (an exception), it can assume two basic behaviors:
  it can return an error code (typically nil or false) or it can raise an error, calling `error`.

  There are no fixed rules for choosing between these two options, but I use the following guideline:
  an exception that is easily avoided should raise an error; otherwise, it should return an error code.

  For instance, let us consider math.sin. How should it behave when called on a table?
  Suppose it returns an error code. If we need to check for errors, we would have to write something like this:

  local res = math.sin(x)
  if not res then -- error
    -- error-handling code

  However, we could as easily check this exception before calling the function:
  if not tonumber(x) then -- x is not a number
    -- error-handling code
  local res = math.sin(x)
  -- Do something

  Frequently we check neither the argument nor the result of a call to sin;
  if the argument is not a number, it means that probably there is something wrong in our program.
  In such situations, the simplest and most practical way to handle the exception is to stop the computation and issue an error message.
  It means, you don't really need to handle cases like that; let them raise an exception (without checking if x is not a number), so you will be able to know where is something wrong in our program.
]]



-- Error codes handling (like `io.open`) -- Best when there are few errors to implement and those has only information of messages/ids
-- > No error is raised, but we can force to raise it with `assert` to find where the error was raised

function fooErrorCode() -- Function that returns an error message and code
  -- Like `io.open`: print(io.open('non-existent-file', 'r')) --> nil    non-existent-file: No such file or directory    2

  -- If you type 1, raises an error 'No such file or directory'.
  -- If you type negative numbers, raises an error 'Permission denied'.
  -- Else, return number 7.

  -- Do something
  if true then -- Simulates an unexpected condition
    local errcode = io.read('*n') -- Type 1 or any other number

    if errcode == 1 then
      return nil, 'No such file or directory', 1 -- nil to indicate an error, error message, error code to handle if not used with assertion
    elseif errcode < 1 then
      return nil, 'Permission denied', 0 -- nil to indicate an error, error message, error code to handle if not used with assertion
    end
  end
  -- Do something
  return 7
end

-- Option A - Handling each error code (of a function that has an error style like `io.open`)
--[[
  local ret, err, errcode = fooErrorCode()
  if not ret then
    if errcode == 1 then
      print('Error found:', err, errcode) --> Error found:    No such file or directory    1
    else
      print(('Unknown error (%s; code: %d)'):format(err, errcode)) --> Unknown error (Permission denied; code: 0)
    end
    return
  end

  -- Do something
  print(ret)
  -- Do something
--]]

-- Option B - Not handling any error code (of a function that has an error style like `io.open`), but still playing safe
--[[
  local ret = fooErrorCode()
  if not ret then
    return
  end

  -- Do something
  print(ret)
  -- Do something
--]]

-- Option C - Not handling any error code (of a function that has an error style like `io.open`), but still playing safe with `assert`
-- `assert` raises an error if first parameter is nil/false, with the optional message as second parameter
-- With this way, you can also find where the error was raised
--[[
  local ret = assert(fooErrorCode()) --> C:\Program Files (x86)\Lua\5.1\lua.exe: .\function_error.lua:102: No such file or directory
  -- local ret = assert(fooErrorCode(), 'My custom message for fooErrorCode()') --> C:\Program Files (x86)\Lua\5.1\lua.exe: .\function_error.lua:104: My custom message for foo()
--]]



--[[
  For many applications, we do not need to do any error handling in Lua; the application program does this handling.
  All Lua activities start from a call by the application, usually asking Lua to run a chunk.
  If there is any error, this call returns an error code, so that the application can take appropriate actions.
  In the case of the stand-alone interpreter, its main loop just prints the error message and continues showing the prompt and running the given commands.
  However, if we want to handle errors inside the Lua code, we should use the function pcall (protected call) to encapsulate our code.

  The function pcall calls its first argument in protected mode, so that it catches any errors while the function is running.
  The function pcall never raises any error, no matter what, so the code keeps running after that.
  If there are no errors, pcall returns true, plus any values returned by the call.
  Otherwise, it returns false, plus the error message.

  These mechanisms provide all we need to do exception handling in Lua.
  We throw an exception with error and catch it with pcall.
  The error message identifies the kind of error.

  > pcall(...)
  Calls the function `f` with the given arguments in *protected mode*.
  This means that any error inside `f` is not propagated; instead, `pcall` catches the error and returns a status code.
  Its first result is the status code (a boolean), which is true if the call succeeds without errors.
  In such case, `pcall` also returns all results from the call, after this first result.
  In case of any error, `pcall` returns `false` plus the error object.
]]

-- Error exception handling (like `???`) -- Best when there are multiple errors to implement or those has more information than messages/ids
-- > pcall deals with `error` raises

function fooException(x) -- Function that raises an error exception
  -- Like `???`: print(io.open('non-existent-file', 'r')) --> nil    non-existent-file: No such file or directory    2

  -- If you type 1, raises an error 'No such file or directory'.
  -- If you type negative numbers, raises an error 'Permission denied'.
  -- Else, return number 7 (sent by parameter from pcall).

  -- Do something
  if true then -- Simulates an unexpected condition
    local errcode = io.read('*n') -- Type 1 or any other number

    if errcode == 1 then
      error({code = 1, msg = 'No such file or directory'}) -- or error('My message')
    elseif errcode < 1 then
      error({code = 0, msg = 'Permission denied'})
    end
  end
  -- Do something
  return x
end

-- Option A - Handling each error exception (of a function that has an error style like `???`)
--[[
  local ok, ret = pcall(fooException, 7)
  if not ok then
    if ret.code == 1 then
      print('Error found:', ret.msg, ret.code) --> Error found:    No such file or directory    1
    else
      print(('Unknown error (%s; code: %d)'):format(ret.msg, ret.code)) --> Unknown error (Permission denied; code: 0)
    end
    return
  end

  -- Do something
  print(ret) --> 7
  -- Do something
--]]

-- Option B - Not handling any error exception (of a function that has an error style like `???`), but still playing safe
--[[
  local ok, ret = pcall(fooException, 7)
  if not ok then
    print(ret.msg) --> No such file or directory
    return
  end

  -- Do something
  print(ret) --> 7
  -- Do something
--]]
--[[
  local ok, ret = pcall(fooException, 7)
  if not ok then
    print('My custom message for fooException()') --> My custom message for fooException()
    return
  end

  -- Do something
  print(ret) --> 7
  -- Do something
--]]



-- pcall with an anonymous function

--[[
-- If you type any number different from 7, raises an error 'Permission denied'.
-- If you type 7, prints 8.
  function fooAnonymousPcall() -- Any function
    -- Do something
    if true then
      return io.read('*n')
    end
    -- Do something
  end

  local ok, ret = pcall(function() -- Your function to creating rules to test fooAnonymousPcall raising exceptions
    if fooAnonymousPcall() ~= 7 then
      error({code = 0, msg = 'Permission denied'})
    end
    return 8
  end)
  if not ok then
    print(ret.msg) --> Permission denied
    return
  end

  -- Do something
  print(ret) --> 8
  -- Do something
--]]



--[[
  Important:
    As it's difficult to send values to first parameter function, we will not use this, despite the good part of having a message handler.
    This difficulty was fixed on version Lua 5.2+, but, here, we are learning Lua 5.1, for Kingdom Age.

  > xpcall
  Calls function f with the given arguments in protected mode with a new message handler.
  - Does the same as pcall, but with a message handler function callback.
  - (*1) There is no way to pass a value as parameters to the first parameter function callback.
    But there is a trick in which we call an anonymous function as the first parameter calling the function we want with the established values.
]]

--[[
  function fooMsgHandler(ret)
    if ret.code == 1 then
      print('Error found:', ret.msg, ret.code) --> Error found:    No such file or directory    1
    else
      print(('Unknown error (%s; code: %d)'):format(ret.msg, ret.code)) --> Unknown error (Permission denied; code: 0)
    end
  end

  local ok, ret = xpcall(function() return fooException(7) end --[=[ See (*1) ]=], fooMsgHandler)
  if not ok then
    return
  end

  -- Do something
  print(ret) --> 7
  -- Do something
--]]

--[[
  local ok, ret = xpcall(function() return fooException(7) end --[=[ See (*1) ]=], function(ret) print(debug.traceback(ret.msg)) end)
  if not ok then
    return
  end

  -- Do something
  print(ret) --> 7
  -- Do something
--]]



-- Debug

-- debug.debug()
  --[[ Enters an interactive mode with the user, running each string that the user enters. ]]

-- debug.traceback(message, level) or debug.traceback(thread, message, level)
  --[[ Returns a string with a traceback of the call stack. The optional message string is appended at the beginning of the traceback. ]]

  -- print(debug.traceback())
  -- print(debug.traceback('My message'))
  --[[
    My message
    stack traceback:
            .\function.lua:488: in main chunk
            [C]: ?
  ]]
