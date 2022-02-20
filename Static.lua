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
    "Static [ERROR]: Length of argument #2 is 0",
    "Static [ERROR]: '%s' already exists",
    "Static [ERROR]: Bad argument #1, erroneous type declaration"
  },
  Key = {
    "Static [ERROR]: '%s' doesn't exists",
    "Static [ERROR]: Bad argument #1, @Str expected got %s"
  },
  Struct = {
    "Static [ERROR]: Bad argument #2, @Table expected, got %s",
    "Static [ERROR]: Key/index '%s' don't match the type %s",
    "Static [ERROR]: Trying to set a %s into a table of type %s"
  },
  Return = {
    "Static [ERROR]: Bad argument #2, @Func expected, got %s",
    "Static [ERROR]: Something's went wrong calling the given function",
    "Static [ERROR]: Function must return at least 1 value",
    "Static [ERROR]: Returned value #%d don't match the type %s"
  },
  Mixed = "Static.lua [ERROR]: Something went wrong, please check the value that you're trying to set."
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
  local VT = type(V)
  assert(VT == STypes[T], Err.Basic:format(T, LTypes[VT]))
  return { _type = STypes[T], _val = V, _is = "Basic" }
end

-- Constructs a table for a "Struct" type value
local function Build_Struct(T, Val)
  local struct = { _type = STypes[T], _is = "Struct" }
  local ValT = type(Val)
  assert(ValT == "table", Err.Struct[1]:format(LTypes[ValT]))

  for k, v in pairs(Val) do
    assert(type(v) == STypes[T], Err.Struct[2]:format(k, T))
  end

  struct._val = Val
  SetMT(struct._val, {
    __newindex = function (s, k, v)
      local vt = type(v)
      assert(vt == struct._type, Err.Struct[3]:format(LTypes[vt], LTypes[struct._type]))
      rawset(s, k, v)
    end
  })

  return struct
end

-- Constructs a table for a "Return" type value
local function Build_Return(T, Fn, ...)
  local FnT = type(Fn)
  assert(FnT == "function", Err.Return[1]:format(LTypes[FnT]))

  local ret = { _type = STypes[T], _is = "Return" }
  local Val = { pcall(Fn, ...) }
  local Ok  = table.remove(Val, 1)

  assert(Ok, Err.Return[2])
  assert(#Val > 0, Err.Return[3])

  for i, v in ipairs(Val) do
    assert(type(v) == STypes[T], Err.Return[4]:format(i, T))
  end

  ret._val = Fn
  return ret
end

-- Constructs a table for a "Mixed" type value
local function Build_Mixed(Types, Val, ...)
  local temp, ok
  local match = false
  local mixed = { _type = Types, _is = "Mixed" }

  for _, t in ipairs(Types) do
    if Parse(t) == "Basic" then
      ok, temp = pcall(Build_Basic, t, Val)

      if ok then
        match = true
        break
      end
    elseif Parse(t) == "Struct" then
      ok, temp = pcall(Build_Struct, t, Val)

      if ok then
        match = true
        break
      end
    elseif Parse(t) == "Return" then
      ok, temp = pcall(Build_Return, t, Val, ...)

      if ok then
        match = true
        break
      end
    elseif Parse(t) == "Mixed" then
      ok, temp = pcall(Build_Mixed, t, Val, ...)

      if ok then
        match = true
        break
      end
    end
  end

  assert(match, Err.Mixed)
  mixed._val = temp._val
  temp       = nil
  return mixed
end

-- Creates and store a new value
function Static:new(Dec, Key, Val, ...)
  local DecT, KeyT = type(Dec), type(Key)
  assert(DecT == "string" or DecT == "table", Err.New[1]:format(LTypes[DecT]))
  assert(#Dec > 0, Err.New[2])
  assert((DecT == "string") and not Dec:match("[Nn]il") or true, Err.New[3])
  assert(KeyT == "string", Err.New[4]:format(LTypes[KeyT]))
  assert(#Key > 0, Err.New[5])
  assert(not Reg[Key], Err.New[6]:format(Key))

  if Parse(Dec) == "Basic" then
    Reg[Key] = Build_Basic(Dec, Val)
  elseif Parse(Dec) == "Struct" then
    Reg[Key] = Build_Struct(Dec, Val)
  elseif Parse(Dec) == "Return" then
    Reg[Key] = Build_Return(Dec, Val, ...)
  elseif Parse(Dec) == "Mixed" then
    Reg[Key] = Build_Mixed(Dec, Val, ...)
  else
    return error(Err.New[7])
  end
end

-- Get the value registered with 'Key'
function Static:get(Key)
  local KeyT = type(Key)
  assert(KeyT == "string", Err.Key[2]:format(LTypes[KeyT]))
  assert(Reg[Key], Err.Key[1]:format(Key))
  return Reg[Key]._val
end

-- Set a new value for the registered entry with 'Key'
function Static:set(Key, Val, ...)
  local KeyT = type(Key)
  assert(KeyT == "string", Err.Key[2]:format(LTypes[KeyT]))
  assert(Reg[Key], Err.Key[1]:format(Key))
  local temp

  if Reg[Key]._is == "Basic" then
    temp = Build_Basic(LTypes[Reg[Key]._type], Val)
    Reg[Key]._val = temp._val
  elseif Reg[Key]._is == "Struct" then
    temp = Build_Struct(LTypes[Reg[Key]._type], Val)
    Reg[Key]._val = temp._val
  elseif Reg[Key]._is == "Return" then
    temp = Build_Return(LTypes[Reg[Key]._type], Val, ...)
    Reg[Key]._val = temp._val
  elseif Reg[Key]._is == "Mixed" then
    temp = Build_Mixed(Reg[Key]._type, Val, ...)
    Reg[Key]._val = temp._val
  end

  temp = nil
end

return SetMT(Static, {
  __call     = Static.new,
  __index    = Static.get,
  __newindex = Static.set
})