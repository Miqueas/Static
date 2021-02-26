local SetMT  = setmetatable
local GetMT  = getmetatable
local Unpack = table.unpack or unpack

local Err = {
  Basic = "Static [ERROR]: Type mismatch, %s expected, got %s",
  New = {
    "Static [ERROR]: Bad argument #1, @Table or @Str expected, got %s",
    "Static [ERROR]: Length of argument #1 is 0",
    "Static [ERROR]: @Nil type isn't supported",
    "Static [ERROR]: Bad argument #2, @Str expected, got %s",
    "Static [ERROR]: '%s' already exists",
    "Static [ERROR]: Bad argument #1, erroneous type declaration"
  },
  Key = "Static [ERROR]: '%s' doesn't exists",
  Args = "Static [ERROR]: No arguments",
  Struct = {
    "Static [ERROR]: Bad argument #2, @Table expected, got %s",
    "Static [ERROR]: Key/index '%s' don't match the type %s"
  },
  Return = {
    "Static [ERROR]: Bad argument #2, @Func expected, got %s",
    "Static [ERROR]: Something's went wrong calling the given function",
    "Static [ERROR]: Function must return at least 1 value",
    "Static [ERROR]: Returned value #%d don't match the type %s"
  },
  Mixed = "Static.lua [ERROR]: Value don't match with any of specified types",
  VarArgs = "Static.lua [ERROR]: At least 1 argument expected"
}

-- This table contains the equivalent "Static" types of
-- supported Lua types by "Static"
local LTypes = {
  ["nil"]      = "@Nil",
  ["string"]   = "@Str",
  ["number"]   = "@Num",
  ["boolean"]  = "@Bool",
  ["userdata"] = "@User",
  ["function"] = "@Func",
  ["table"]    = "@Table",
  ["thread"]   = "@Thread"
}

-- Same as the above table, but inversed
local STypes = {
  -- Basic types
  ["@Str"]    = "string",
  ["@Num"]    = "number",
  ["@Bool"]   = "boolean",
  ["@User"]   = "userdata",
  ["@Func"]   = "function",
  ["@Table"]  = "table",
  ["@Thread"] = "thread",
  -- Struct types
  ["@Str{}"]    = "string",
  ["@Num{}"]    = "number",
  ["@Bool{}"]   = "boolean",
  ["@User{}"]   = "userdata",
  ["@Func{}"]   = "function",
  ["@Table{}"]  = "table",
  ["@Thread{}"] = "thread",
  -- Return types
  ["@Str()"]    = "string",
  ["@Num()"]    = "number",
  ["@Bool()"]   = "boolean",
  ["@User()"]   = "userdata",
  ["@Func()"]   = "function",
  ["@Table()"]  = "table",
  ["@Thread()"] = "thread"
}

-- Registry were Typed store all created values
local Reg = {}

-- The Static class
local Static = {}

-- Returns the type declaration mode
local function Parse(Dec)
  local Basic  = "^ *@%a+ *$"
  local Struct = "^ *@%a+ *%{ *%} *$"
  local Return = "^ *@%a+ *%( *%) *$"

  if type(Dec) == "string" then
    if Dec:match(Basic) then
      return "Basic"
    elseif Dec:match(Struct) then
      return "Struct"
    elseif Dec:match(Return) then
      return "Return"
    else
      return nil
    end
  elseif type(Dec) == "table" then
    return "Mixed"
  else
    return nil
  end
end

-- Constructs a table for a "Basic" type value
local function Build_Basic(T, V)
  assert(type(V) == STypes[T], Err.Basic:format(T, LTypes[type(V)]))
  return { _type = STypes[T], _val = V, _is = "Basic" }
end

-- Constructs a table for a "Struct" type value
local function Build_Struct(T, ...)
  local va = { ... }
  local struct = { _type = STypes[T], _is = "Struct" }
  assert(#va > 0, Err.Args)

  if #va == 1 then
    assert(type(va[1]) == "table", Err.Struct[1]:format(LTypes[type(va[1])]))

    for k, v in pairs(va[1]) do
      assert(type(v) == STypes[T], Err.Struct[2]:format(k, T))
    end

    struct._val = va[1]
  else
    struct._val = {}

    for i, v in ipairs(va) do
      assert(type(v) == STypes[T], Err.Struct[2]:format(i, T))
      table.insert(struct._val, v)
    end
  end

  return struct
end

-- Constructs a table for a "Return" type value
local function Build_Return(T, F, ...)
  assert(type(F) == "function", Err.Return[1]:format(LTypes[type(F)]))

  local ret = { _type = STypes[T], _is = "Return" }
  local Val = { pcall(F, ...) }
  local Ok  = table.remove(Val, 1)

  assert(Ok, Err.Return[2])
  assert(#Val > 0, Err.Return[3])

  for i, v in ipairs(Val) do
    assert(type(v) == STypes[T], Err.Return[4]:format(i, T))
  end

  ret._val = F
  return ret
end

-- Constructs a table for a "Mixed" type value
local function Build_Mixed(Types, ...)
  local temp
  local va    = { ... }
  local match = false
  local multi = { _type = Types, _is = "Mixed" }

  for _, t in ipairs(Types) do
    if Parse(t) == "Basic" and type(va[1]) == STypes[t] then
      temp  = Build_Basic(t, va[1])
      match = true
      break
    elseif Parse(t) == "Struct" and ((type(va[1]) == "table" and #va == 1) or #va > 1) then
      temp  = Build_Struct(t, ...)
      match = true
      break
    elseif Parse(t) == "Return" and type(va[1]) == "function" then
      temp  = Build_Return(t, table.remove(va, 1), Unpack(va))
      match = true
      break
    elseif Parse(t) == "Mixed" then
      temp  = Build_Mixed(t, ...)
      match = true
      break
    end
  end

  assert(match, Err.Mixed)
  multi._val = temp._val
  temp       = nil
  return multi
end

-- Creates and store a new value
function Static:new(Dec, Key, ...)
  local va = { ... }

  assert(type(Dec) == "string" or type(Dec) == "table", Err.New[1]:format(LTypes[type(Dec)]))
  assert(#Dec > 0, Err.New[2])
  assert(not Dec:match("[Nn]il"), Err.New[3])
  assert(type(Key) == "string", Err.New[4]:format(LTypes[type(Key)]))
  assert(not Reg[Key], Err.New[5]:format(Key))
  assert(#va > 0, Err.VarArgs)

  if Parse(Dec) == "Basic" then
    Reg[Key] = Build_Basic(Dec, va[1])
  elseif Parse(Dec) == "Struct" then
    Reg[Key] = Build_Struct(Dec, ...)
  elseif Parse(Dec) == "Return" then
    Reg[Key] = Build_Return(Dec, table.remove(va, 1), Unpack(va))
  elseif Parse(Dec) == "Mixed" then
    Reg[Key] = Build_Mixed(Dec, ...)
  else
    return error(Err.New[6])
  end
end

-- Get the value registered with 'Key'
function Static:get(Key)
  assert(Reg[Key], Err.Key:format(Key))
  return Reg[Key]._val
end

-- Set a new value for the registered entry with 'Key'
function Static:set(Key, ...)
  local temp
  local va = { ... }
  assert(Reg[Key], Err.Key:format(Key))
  assert(#va > 0, Err.VarArgs)

  if Reg[Key]._is == "Basic" then
    temp = Build_Basic(LTypes[Reg[Key]._type], va[1])
    Reg[Key]._val = temp._val
    temp = nil
  elseif Reg[Key]._is == "Struct" then
    temp = Build_Struct(LTypes[Reg[Key]._type], ...)
    Reg[Key]._val = temp._val
    temp = nil
  elseif Reg[Key]._is == "Return" then
    temp = Build_Return(LTypes[Reg[Key]._type], table.remove(va, 1), Unpack(va))
    Reg[Key]._val = temp._val
    temp = nil
  elseif Reg[Key]._is == "Mixed" then
    temp = Build_Mixed(Reg[Key]._type, ...)
    Reg[Key]._val = temp._val
    temp = nil
  end
end

return SetMT(Static, {
  __call     = Static.new,
  __index    = Static.get,
  __newindex = Static.set
})