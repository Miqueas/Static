local SetMT  = setmetatable
local GetMT  = getmetatable
local Unpack = table.unpack or unpack

local ErrMsg = {}

--[[ Spec:

  [DONE]    (Single)   @Type   ==> just @Type
  [WORKING] (Struct)   @Type{} ==> a table of @Type
  [WORKING] (Return)   @Type() ==> a function that returns @Type
  [WORKING] (Multiple) { ... } ==> can be multiple types

]]

-- This table contains the equivalent Typed types of
-- supported Lua types by Typed
local _LTypes = {
  ["string"]   = "@Str",
  ["number"]   = "@Num",
  ["boolean"]  = "@Bool",
  ["userdata"] = "@User",
  ["function"] = "@Func",
  ["table"]    = "@Table",
  ["thread"]   = "@Thread"
}

-- Same as the above table, but the inverse
local _TTypes = {
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
local _TReg = {}

-- The Typed class
local Typed = {}

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
    return "Multiple"
  else
    return nil
  end
end

-- Constructs a table for a "Single" type value
local function Build_Single(T, V)
  local ErrMsg = "Typed:new [ERROR] => Type mismatch, %s (%s) expected, got %s (%s)"

  assert(type(T) == "string", "Bad argument #1, string expected, got " .. type(T))

  assert(
    type(V) == _TTypes[T],
    ErrMsg:format(T, _TTypes[T], _LTypes[type(V)], type(V))
  )

  return { _type = _TTypes[T], _val = V, _is = "Single" }
end

-- Constructs a table for a "Struct" type value
local function Build_Struct(T, ...)
  assert(type(T) == "string", "Bad argument #1, string expected, got " .. type(T))

  local va = { ... }
  local struct = { _type = _TTypes[T], _is = "Struct" }

  if #va == 1 then
    assert(type(va[1]) == "table")

    for k, v in pairs(va[1]) do
      assert(type(v) == _TTypes[T], "Key/index '" .. k .. "' don't match the type " .. T)
    end

    struct._val = va[1]
  else
    struct._val = {}

    for i, v in ipairs(va) do
      assert(type(v) == _TTypes[T], "Key/index '" .. i .. "' don't match the type " .. T)
      table.insert(struct._val, v)
    end
  end

  return struct
end

-- Constructs a table for a "Return" type value
local function Build_Return(T, F, ...)
  assert(type(T) == "string", "Bad argument #1, string expected, got " .. type(T))
  assert(type(F) == "function", "Bad argument #2, function expected, got " .. type(F))

  local ret = { _type = _TTypes[T], _is = "Return" }
  local Ok, Val = pcall(F, ...)

  assert(Ok, "Something's went wrong calling the function!")
  assert(
    Ok and type(Val) == _TTypes[T],
    "Type returned don't match type " .. T
  )

  ret._val = F
  return ret
end

-- Constructs a table for a "Multiple" type value
local function Build_Multiple(Types, ...)
  local temp
  local va    = { ... }
  local match = false
  local multi = { _type = Types, _is = "Multiple" }

  for _, t in ipairs(Types) do
    if Parse(t) == "Single" and type(va[1]) == _TTypes[t] then
      temp  = Build_Single(t, va[1])
      match = true
      break
    elseif Parse(t) == "Struct" then
      temp  = Build_Struct(t, va[1])
      match = true
      break
    elseif Parse(t) == "Return" then
      temp  = Build_Return(t, table.remove(va, 1), Unpack(va))
      match = true
      break
    elseif Parse(t) == "Multiple" and type(va[1]) == _TTypes[t] then
      temp  = Build_Multiple(t, va[1])
      match = true
      break
    end
  end

  assert(match, "Typed:new [ERROR] => Value don't match with any of specified types")
  multi._val = temp._val
  return multi
end

function Typed:new(Dec, Key, ...)
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

  assert(not _TReg[Key], "Key '" .. Key .. "' already's exists (in Typed:new)")
  -- End type checking

  if Parse(Dec) == "Single" then
    _TReg[Key] = Build_Single(Dec, va[1])
  elseif Parse(Dec) == "Struct" then
    _TReg[Key] = Build_Struct(Dec, ...)
  elseif Parse(Dec) == "Return" then
    local fn   = table.remove(va, 1)
    _TReg[Key] = Build_Return(Dec, fn, Unpack(va))
  elseif Parse(Dec) == "Multiple" then
    _TReg[Key] = Build_Multiple(Dec, va[1])
  else
    return error("Typed:new [ERROR] => Bad type declaration: " .. Dec)
  end
end

function Typed:get(Key)
  assert(_TReg[Key], "Key '" .. Key .. "' doesn't exists")
  return _TReg[Key]._val
end

function Typed:set(Key, ...)
  local va = { ... }
  assert(_TReg[Key], "Key '" .. Key .. "' doesn't exists")

  if _TReg[Key]._is == "Single" then
    assert(type(va[1]) == _TReg[Key]._type, "ª")
    _TReg[Key]._val = va[1]

  elseif _TReg[Key]._is == "Struct" then
    if #va == 1 then
      assert(type(va[1]) == "table")

      for k, v in pairs(va[1]) do
        assert(
          type(v) == _TReg[Key]._type,
          "Key/index '" .. k .. "' don't match the type " .. _LTypes[_TReg[Key]._type]
        )
      end

      _TReg[Key]._val = va[1]
    else
      _TReg[Key]._val = {}

      for i, v in ipairs(va) do
        assert(
          type(v) == _TReg[Key]._type,
          "Key/index '" .. i .. "' don't match the type " .. _LTypes[_TReg[Key]._type]
        )

        table.insert(_TReg[Key]._val, v)
      end
    end

  elseif _TReg[Key]._is == "Return" then
    assert(type(va[1]) == "function", "Bad argument #2, function expected, got " .. _LTypes[type(va[1])])

    local fn      = table.remove(va, 1)
    local ok, ret = pcall(fn, Unpack(va))

    assert(ok, "Something's went wrong calling the function!")
    assert(
      ok and type(ret) == _TReg[Key]._type,
      "Type returned don't match type " .. _LTypes[_TReg[Key]._type]
    )

    _TReg[Key]._val = fn

  elseif _TReg[Key]._is == "Multiple" then
    local match = false
    local temp

    for _, t in ipairs(_TReg[Key]._type) do
      if Parse(t) == "Single" then
        temp  = Build_Single(t, va[1])
        match = true
        break
      elseif Parse(t) == "Struct" then
        temp  = Build_Struct(t, ...)
        match = true
        break
      elseif Parse(t) == "Return" then
        temp  = Build_Return(t, table.remove(va, 1), Unpack(va))
        match = true
        break
      elseif Parse(t) == "Multiple"then
        temp  = Build_Multiple(t, ...)
        match = true
        break
      end
    end

    assert(match, "Typed:new [ERROR] => Value don't match with any of specified types")
    _TReg[Key]._val = temp._val
  end
end

Typed = SetMT(Typed, {
  __call     = Typed.new,
  __index    = Typed.get,
  __newindex = Typed.set
})

return Typed