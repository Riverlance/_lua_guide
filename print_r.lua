function table.empty(t)
  if t and type(t) == 'table' then
    return next(t) == nil
  end
  return true
end

function dumpvar(data)
  local tablecache = { }
  local buffer = ''
  local padder = '  '

  local function _dumpvar(d, depth)
    local t   = type(d)
    local str = tostring(d)
    if t == 'table' then
      if tablecache[str] then
        buffer = string.format('%s<%s>\n', buffer, str) -- Table dumped already: don't dump it again, mention it instead
      else
        tablecache[str] = (tablecache[str] or 0) + 1
        buffer = string.format('%s(%s)\n%s{\n', buffer, str, padder:rep(depth))
        for k, v in pairs(d) do
          buffer = string.format('%s%s[%s] = ', buffer, padder:rep(depth + 1), type(k) == 'string' and string.format('"%s"', k) or tostring(k))
          _dumpvar(v, depth + 1)
        end
        buffer = string.format('%s%s}\n', buffer, padder:rep(depth))
      end
    elseif t == 'number' then
      buffer = string.format('%s%s (%s)\n', buffer, str, t)
    elseif t == 'userdata' or t == 'function' or t == 'thread' then
      buffer = string.format('%s(%s)\n', buffer, str)
    elseif t == 'nil' then
      buffer = string.format('%snil (%s)\n', buffer, t)
    else
      buffer = string.format('%s"%s" (%s)\n', buffer, str, t)
    end
  end

  _dumpvar(data, 0)
  return buffer
end

function print_r(...) -- Supports nil parameters
  for i = 1, select('#', ...) do
    print(dumpvar((select(i, ...))))
  end
  return true
end

function print_traceback(msg)
  print(debug.traceback(msg))
end
