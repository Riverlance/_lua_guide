
--[[
  Strings represent text. A string in Lua can contain a single letter or an entire book.
  Programs that manipulate strings with 100K or 1M characters are not unusual in Lua.

  Strings in Lua are immutable values.
  We cannot change a character inside a string, as we can in C; instead,
  we create a new string with the desired modifications, as in the next example:
]]

--[[
  a = 'one string'
  b = a:gsub('one', 'another') -- change strings parts
  print(a) --> one string
  print(b) -- > another string
--]]



-- Length

-- We can get the length of a string using the length operator (denoted by #):
--[[
  a = 'hello'
  print(#a) --> 5
  print(#'good bye') --> 8
--]]

--[[
  This operator always counts the length in bytes, which is not the same as characters in some encodings.
  We can concatenate two strings with the concatenation operator .. (two dots).
  If any operand is a number, Lua converts this number to a string:
]]
--[[
  print('Hello ' .. 'World') --> Hello World
  print('result is ' .. 3) --> result is
--]]
  -- (Some languages use the plus sign for concatenation, but 3 + 5 is different from 3 .. 5.)

--[[
  The concatenation operator always creates a new string, without any modification to its operands.
]]
--[[
  a = 'Hello'
  print(a .. ' World') -- Hello World
  print(a) --> Hello
--]]

--[[
  Note: The string.format(...) is faster than with '..' because it is a builtin function (using C language)
  which can, for example, concatenate multiple strings at once, instead of creating a new string
  per concatenation of two strings with '..'.
]]



-- Literal strings

--[[
  We can delimit literal strings by single or double matching quotes:
  "a line"
  'another line'
  They are equivalent; the only difference is that inside each kind of quote we can use the other quote without escapes.

  \a bell
  \b back space
  \f form feed
  \n newline
  \r carriage return
  \t horizontal tab
  \v vertical tab
  \\ backslash
  \" double quote
  \' single quote
]]



-- Long strings

--[[
  We can delimit literal strings also by matching double square brackets, as we do with long comments.
  Literals in this bracketed form can run for several lines and do not interpret escape sequences.
  Moreover, it ignores the first character of the string when this character is a newline.
  This form is especially convenient for writing strings that contain large pieces of code, as in the following example:
]]
--[=[
  page = [[
  <html>
  <head>
    <title>An HTML Page</title>
  </head>
  <body>
    <a href="http://www.lua.org">Lua</a>
  </body>
  </html>
]]
  print(page)
  --]=]

--[=[
  Sometimes, we may need to enclose a piece of code containing something like a = b[c[i]] (notice the ]] in this code),
  or we may need to enclose some code that already has some code commented out.
  To handle such cases, we can add any number of equals signs between the two opening brackets, as in [===[.
  After this change, the literal string ends only at the next closing brackets with the same number
  of equals signs in between (]===], in our example).
  The scanner ignores any pairs of brackets with a different number of equals signs.
  By choosing an appropriate number of signs, we can enclose any literal string without having to modify it in any way.

  It is better to code arbitrary binary data using numeric escape sequences either in decimal or in hexadecimal,
  such as "\x13\x01\xA1\xBB". However, this poses a problem for long strings, because they would result in quite long lines.
  ]=]



-- Coercions

--[[
  Any numeric operation applied to a string tries to convert the string to a number.
  Lua applies such coercions not only in arithmetic operators, but also in other places that expect a number, such as the argument to math.sin.
  Conversely, whenever Lua finds a number where it expects a string, it converts the number to a string.
  (When we write the concatenation operator right after a numeral, we must separate them with a space;
  otherwise, Lua thinks that the first dot is a decimal point.)
]]

--[[
  x = -'7'
  print(x, type(x)) --> -7 number
  print(10 .. 20) --> 1020
  -- print(10..20) --> malformed number near '10..20'
--]]

-- tonumber
--[[
  To convert a string to a number explicitly, we can use the function tonumber,
  which returns nil if the string does not denote a proper number.
  Otherwise, it returns integers or floats, following the same rules of the Lua scanner:
]]
--[[
  print(tonumber(' -3 ')) --> -3
  print(tonumber(' 10e4 ')) --> 100000
  print(tonumber('10e')) --> nil (not a valid number)
--]]
-- By default, tonumber assumes decimal notation, but we can specify any base between 2 and 36 for the conversion:
--[[
  print(tonumber('100101', 2)) --> 37
  print(tonumber('fff', 16)) --> 4095
  print(tonumber('987', 8)) --> nil
--]]
--[[
  In the last line, the string does not represent a proper numeral in the given base, so tonumber returns nil.
  To convert a number to a string, we can call the function tostring:
]]
--[[
  print(tostring(10) == '10') --> true
--]]
--[[
  These conversions are always valid.
  Unlike arithmetic operators, order operators never coerce their arguments. Remember that "0" is different from 0.
  Moreover, 2 < 15 is obviously true, but "2" < "15" is false (alphabetical order).
  To avoid inconsistent results, Lua raises an error when we mix strings and numbers in an order comparison,
  such as 2 < "15" ("attempt to compare number with string").
]]
