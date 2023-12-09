
dofile('print_r.lua')

math.randomseed(os.time())

f = string.format

---
---Return file size in bytes.
---
---@param file file*
---@return number
function getFileSize(file)
  local currentPos = file:seek()
  local finalPos = file:seek('end')
  file:seek('set', currentPos)
  return finalPos
end



-- io.write

-- Don't make concatenations explicitly with '..' using io.write.
--[[
  -- io.write('sin(3) = ' .. math.sin(3) .. '\n') --> sin(3) = 0.14112000805987 -- Don't do this
  io.write('sin(3) = ', math.sin(3), '\n') --> sin(3) = 0.14112000805987 -- Do this instead
  io.write(string.format('sin(3) = %.4f\n', math.sin(3))) --> sin(3) = 0.1411
  io.write(('sin(3) = %.4f\n'):format(math.sin(3))) --> sin(3) = 0.1411
  io.write(('sin(3) = %.4f\n'):format(math.sin(3))) --> sin(3) = 0.1411
  io.write(f('sin(3) = %.4f\n', math.sin(3))) --> sin(3) = 0.1411
--]]



-- io.read

--[[
  The function io.read reads strings from the current input stream.
  Its arguments control what to read.
  In Lua 5.2 and before, all string options should be preceded by an asterisk.
  Lua 5.3 still accepts the asterisk for compatibility.

  '*a' -- reads the whole file
  '*l' -- reads the next line (dropping the newline)
  '*L' -- reads the next line (keeping the newline)
  '*n' -- reads a number
  num -- reads num characters as a string
]]

io.input('data/assets/file.txt')

-- Read whole file at once
--[[
  text = io.read('*a') -- Read the whole file
  print_r(text) --> Hello, wórld! Hello!
  text = text:gsub('Hello', 'Hail') -- Overwrite Hello with Hail
  print_r(text) --> Hail, wórld! Hail!
--]]

-- Read whole file at once
--[[
  text = io.read('*all') -- Read the whole file
  print_r(text) --> Hello, wórld! Hello!
  text = text:gsub('([\128-\255=])', function(c)
    return f('=%02X', c:byte())
  end)
  print_r(text) --> Hello, w=C3=B3rld! Hello!
--]]

-- Reading line by line
--[[
  for count = 1, math.huge do
    local line = io.read('*l')
    if line == nil then
      break
    end

    print(f('%8d ', count), line)
  end
--]]

-- Reading line by line (simpler code)
--[[
  local count = 0
  for line in io.lines() do
    count = count + 1
    print(f('%8d ', count), line)
  end
--]]

-- Sort lines
--[[
  local lines = { }
  for line in io.lines() do
    lines[#lines + 1] = line
  end
  table.sort(lines)
  for _, line in ipairs(lines) do
    print(line)
  end
--]]

-- Read in blocks
--[[
  while true do
    local block = io.read(7) -- Read up to next 7 characters
    if not block then
      break
    end
    print(block) --> Hello, | wórld! | | Hello!
  end
--]]
  -- As a special case, io.read(0) works as a test for end of file:
  -- it returns an empty string if there is more to be read or nil otherwise.

-- Print max value of each line
--[[
  io.input('data/assets/numbers.txt')

  while true do
    local n1, n2, n3 = io.read('*n', '*n', '*n')
    if not n1 then
      break
    end
    print(math.max(n1, n2, n3))
  end
--]]



-- file

--[[
  print(io.open('non-existent-file', 'r')) --> nil	non-existent-file: No such file or directory	2
  print(io.open('C:/Windows/diagerr.xml', 'w')) --> nil	C:/Windows/diagerr.xml: Permission denied	13
--]]

--[[
  A typical idiom to check for errors is to use the function assert.
  If the open fails, the error message goes as the second argument to assert, which then shows the message.
]]
-- local file = assert(io.open('non-existent-file', 'r')) --> non-existent-file: No such file or directory
-- local file = assert(io.open('non-existent-file', 'r'), 'Custom error message.') --> non-existent-file: No such file or directory

--[[
  local file = assert(io.open('data/assets/file.txt', 'r'))
  local text = file:read('*a') -- Read all file
  file:close()
  print_r(text) --> Hello, wórld! Hello!
--]]

--[[
  The I/O library offers handles for the three predefined C streams, called io.stdin, io.stdout, and io.stderr.
  For instance, we can send a message directly to the error stream with a code like this:
  io.stderr:write('My custom error message.')

  The functions io.input and io.output allow us to mix the complete model with the simple model.
  We get the current input stream by calling io.input(), without arguments. We set this stream with the call io.input(handle).
  (Similar calls are also valid for io.output.)
  For instance, if we want to change the current input stream temporarily, we can write something like this:

  local temp = io.input() -- save current stream
  io.input("newinput") -- open a new current stream
  ... do something with new input ...
  io.input():close() -- close current stream
  io.input(temp) -- restore previous current stream

  Note that io.read(args) is actually a shorthand for io.input():read(args),
  that is, the read method applied over the current input stream.
  Similarly, io.write(args) is a shorthand for io.output():write(args).

  Instead of io.read, we can also use io.lines to read from a stream. As we saw in previous examples,
  io.lines gives an iterator that repeatedly reads from a stream.
  Given a file name, io.lines will open a stream over the file in read mode and will close it after reaching end of file.
  When called with no arguments, io.lines will read from the current input stream.
  We can also use lines as a method over handles.
]]

--[[
  -- Exited successfully
  -- os.exit(0)

  -- Exited successfully
  -- Note: The second parameter, true, means it closes the Lua state, calling all finalizers and releasing all memory used by that state.
  --       Usually this finalization is not necessary, because most operating systems release all resources used by a process when it exits.
  -- os.exit(0, true)

  -- Exited with an specific error code
  -- os.exit(1)
]]

-- Get environment variable.
--[[
  print(os.getenv('TEMP')) --> C:\Users\River\AppData\Local\Temp
  print(os.getenv('USERNAME')) --> River
--]]

-- Execute a command from OS prompt.
--[=[
  function createFolder(path)
    os.execute('mkdir ' .. path)
  end
  createFolder([[data\assets\empty_folder]])
  --]=]

--[[
  List contents of a folder.
  io.popen runs a system command, but it also connects the command output (or input) to a new local stream and returns that stream.
  So that our script can read data from (or write to) the command.
  For instance, the following script builds a table with the entries in the current directory:
]]
--[[
  local file = io.popen('dir /B', 'r') -- For POSIX systems, use 'ls' instead of 'dir'
  local dir  = { }
  for entry in file:lines() do
    dir[#dir + 1] = entry
  end
  print_r(dir) --> { '.vscode', 'data', 'function.lua', 'io_os.lua', 'math.lua', 'print_r.lua', 'prompt.lua', '_base.lua', '_type', }
--]]
  -- Note: The second parameter ("r") to io.popen means that we intend to read from the command. The default is to read, so this parameter is optional in the example.



-- Data file

--[[
  Table constructors provide an interesting alternative for file formats.
  With a little extra work when writing data, reading becomes trivial.
  The technique is to write our data file as Lua code that, when run, rebuilds the data into the program.
  With table constructors, these chunks can look remarkably like a plain data file.

  Let us see an example to make things clear.
  If our data file is in a predefined format, such as CSV (Comma-Separated Values) or XML, we have little choice.
  However, if we are going to create the file for our own use, we can use Lua constructors as our format.
  In this format, we represent each data record as a Lua constructor.

  Instead of writing in our data file something like:

  Donald E. Knuth,Literate Programming,CSLI,1992
  Jon Bentley,More Programming Pearls,Addison-Wesley,1990

  we write this:
]]
--[[
  Entry{"Donald E. Knuth","Literate Programming", "CSLI", 1992}
  Entry{"Jon Bentley","More Programming Pearls","Addison-Wesley",1990}
--]]
--[[
  Remember that Entry{code} is the same as Entry({code}), that is, a call to some function Entry with a table as its single argument.
  To read that file, we only need to run it, with a sensible definition for Entry.

  When file size is not a big concern, we can use name-value pairs for our representation:
]]
--[[
  Entry {
    author = "Donald E. Knuth",
    title = "Literate Programming",
    publisher = "CSLI",
    year = 1992
  }

  Entry {
    author = "Jon Bentley",
    title = "More Programming Pearls",
    year = 1990,
    publisher = "Addison-Wesley",
  }
--]]
--[[
  This format is what we call a self-describing data format, because each piece of data has attached to it a short description of its meaning.
  Self-describing data are more readable (by humans, at least) than CSV or other compact notations; they are easy to edit by hand, when necessary;
  and they allow us to make small modifications in the basic format without having to change the data file.
  For instance, if we add a new field we need only a small change in the reading program, so that it supplies a default value when the field is absent.

  With the name-value format, our program to collect authors becomes this:
]]
--[[
local authors = { } -- A set to collect authors
function Entry(data) -- Acts as a callback function, which is called during the `dofile` for each entry in the data file
  authors[data.author or 'unknown'] = true
end

dofile('data') -- Loads all entries from file called 'data'

for name in pairs(authors) do -- Prints all
  print(name)
end
--]]



-- Serialization
-- Convert the data into a stream of bytes or characters, to save it into a file or send it through a network connection.

--[[
  local serializationCallbacks = { -- [type] = callback
    ['nil'] = function(t, __recursive)
      return tostring(t)
    end,

    ['boolean'] = function(t, __recursive)
      return tostring(t)
    end,

    ['number'] = function(t, __recursive)
      local function isInteger(num)
        return type(num) == 'number' and num == math.floor(num)
      end
      return f(isInteger(t) and '%d' or '%a', t)
    end,

    ['string'] = function(t, __recursive)
      return f('%q', t)
    end,

    ['table'] = function(t, __recursive)
      if getmetatable(t) then
        error('Was not possible to serialize a table that has a metatable associated with it.')
      elseif table.find(__recursive, t) then -- Cannot have any table referenced twice or more
        error('Was not possible to serialize recursive tables.')
      end
      table.insert(__recursive, t)

      local s = '{ '
      for k, v in pairs(t) do
        s = f('%s[%s] = %s, ', s, table.serialize(k, __recursive), table.serialize(v, __recursive))
      end
      return f('%s}', s)
    end,
  }
  function table.serialize(t, __recursive) -- (table) -- Do not use the recursive param
    local _type = type(t)
    __recursive = __recursive or { }

    if serializationCallbacks[_type] then
      return serializationCallbacks[_type](t, __recursive)
    end

    error(f("Was not possible to serialize the value of type '%s'", _type))
  end

  function table.unserialize(str)
    return loadstring('return ' .. str)()
  end
--]]



-- Loadstring

--[[
  i = 32
  local i = 0
  f = loadstring('i = i + 1; print(i)')
  g = function() i = i + 1; print(i) end
  f() --> 33 -- loadstring always compiles its chunks in the global environment
  g() --> 1
--]]
--[[
  local line = 'x * 7'
  local f = assert(loadstring('local x = ...; return ' .. line))
  print(f(2)) --> 14 -- Because 2 * 7 = 14
--]]
--[[
  local line = 'x + y'
  local f = assert(loadstring('local x, y = ...; return ' .. line))
  print(f(5, 2)) --> 7 -- Because 5 + 2 = 7
--]]
--[[
  local f = assert(loadstring('local x, y = ...; print(x, y)'))
  f(5, 2) -- Prints: 5 2
--]]
--[[
  local f = assert(loadstring('print(...)'))
  f(5, 2, 1) -- Prints: 5 2 1
--]]
