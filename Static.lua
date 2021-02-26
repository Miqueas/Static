local SetMT  = setmetatable
local GetMT  = getmetatable
local Unpack = table.unpack or unpack

--local ErrMsg = {}

--[[ Spec:

  [DONE] (Single) @Type   ==> just @Type
  [DONE] (Struct) @Type{} ==> a table of @Type
  [DONE] (Return) @Type() ==> a function that returns @Type
  [DONE] (Mixed)  { ... } ==> can be multiple types

]]

-- This table contains the equivalent Typed types of
-- supported Lua types by Typed
local LTypes = {
  ["string"]   = "@Str",
  ["number"]   = "@Num",
  ["boolean"]  = "@Bool",
  ["userdata"] = "@User",
  ["function"] = "@Func",
  ["table"]    = "@Table",
  ["thread"]   = "@Thread"
}

-- Same as the above table, but the inverse
local STypes = {
  -- Single types
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

-- The Typed class
local Static = {}

-- Returns the type declaration mode
local function Parse(Dec)
  local Single = "^ *@%a+ *$"
  local Struct = "^ *@%a+ *%{ *%} *$"
  local Return = "^ *@%a+ *%( *%) *$"

  local dt, s, t = type(Dec), "string", "table"

  if dt == s then
    if Dec:match(Single) then
      return "Single"
    elseif Dec:match(Struct) then
      return "Struct"
    elseif Dec:match(Return) then
      return "Return"
    else
      return nil
    end
  elseif dt == t then
    return "Mixed"
  else
    return nil
  end
end

-- Constructs a table for a "Single" type value
local function Build_Single(T, V)
  local ErrMsg = "Typed:new [ERROR] => Type mismatch, %s (%s) expected, got %s (%s)"

  assert(type(T) == "string", "Bad argument #1, string expected, got " .. type(T))

  assert(
    type(V) == STypes[T],
    ErrMsg:format(T, STypes[T], LTypes[type(V)], type(V))
  )

  return { _type = STypes[T], _val = V, _is = "Single" }
end

-- Constructs a table for a "Struct" type value
local function Build_Struct(T, ...)
  local va = { ... }
  local struct = { _type = STypes[T], _is = "Struct" }

  assert(type(T) == "string", "Bad argument #1, string expected, got " .. type(T))
  assert(#va > 0)

  if #va == 1 then
    assert(type(va[1]) == "table")

    for k, v in pairs(va[1]) do
      assert(type(v) == STypes[T], "Key/index '" .. k .. "' don't match the type " .. T)
    end

    struct._val = va[1]
  else
    struct._val = {}

    for i, v in ipairs(va) do
      assert(type(v) == STypes[T], "Key/index '" .. i .. "' don't match the type " .. T)
      table.insert(struct._val, v)
    end
  end

  return struct
end

-- Constructs a table for a "Return" type value
local function Build_Return(T, F, ...)
  assert(type(T) == "string", "Bad argument #1, string expected, got " .. type(T))
  assert(type(F) == "function", "Bad argument #2, function expected, got " .. type(F))

  local ret = { _type = STypes[T], _is = "Return" }
  local Val = { pcall(F, ...) }
  local Ok  = table.remove(Val, 1)

  assert(Ok, "Something's went wrong calling the function!")
  assert(#Val > 0, "Function must return at least 1 value")

  for i, v in ipairs(Val) do
    assert(
      type(v) == STypes[T],
      "One or more returned value(s) don't match type " .. T
    )
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
    if Parse(t) == "Single" and type(va[1]) == STypes[t] then
      temp  = Build_Single(t, va[1])
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

  assert(match, "Typed:new [ERROR] => Value don't match with any of specified types")
  multi._val = temp._val
  temp       = nil
  return multi
end

function Static:new(Dec, Key, ...)
  local va = { ... }

  -- Some type checking
  assert(
    type(Dec) == "string" or type(Dec) == "table",
    "Bad argument #1 for Typed:new, table or string expected, got " .. type(Dec)
  )

  assert(
    #Dec > 0,
    "Argument #1 is given, but length is 0 (in Typed:new)"
  )

  assert(
    type(Key) == "string",
    "Bad argument #2 for Typed:new, string expected, got " .. type(Key)
  )

  assert(not Reg[Key], "Key '" .. Key .. "' already's exists (in Typed:new)")
  -- End type checking

  if Parse(Dec) == "Single" then
    Reg[Key] = Build_Single(Dec, va[1])
  elseif Parse(Dec) == "Struct" then
    Reg[Key] = Build_Struct(Dec, ...)
  elseif Parse(Dec) == "Return" then
    Reg[Key] = Build_Return(Dec, table.remove(va, 1), Unpack(va))
  elseif Parse(Dec) == "Mixed" then
    Reg[Key] = Build_Mixed(Dec, ...)
  else
    return error("Typed:new [ERROR] => Bad type declaration: " .. Dec)
  end
end

function Static:get(Key)
  assert(Reg[Key], "Key '" .. Key .. "' doesn't exists")
  return Reg[Key]._val
end

function Static:set(Key, ...)
  local temp
  local va = { ... }
  assert(Reg[Key], "Key '" .. Key .. "' doesn't exists")

  if Reg[Key]._is == "Single" then
    temp = Build_Single(LTypes[Reg[Key]._type], va[1])
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

Static = SetMT(Static, {
  __call     = Static.new,
  __index    = Static.get,
  __newindex = Static.set
})

return Static