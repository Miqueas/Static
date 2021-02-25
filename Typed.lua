local SetMT  = setmetatable
local GetMT  = getmetatable
local Unpack = table.unpack or unpack

--[[ Spec:

  [DONE]    (Single)   @Type   ==> just @Type
  [WORKING] (Struct)   @Type{} ==> a table of @Type
  [WORKING] (Return)   @Type() ==> a function that returns @Type
  [WORKING] (Multiple) { ... } ==> can be multiple types

]]

--[[ Lua data types

  This table contains the equivalent Typed types of
  supported Lua types by Typed

]]
local _LTypes = {
  ["string"]   = "@Str",
  ["number"]   = "@Num",
  ["boolean"]  = "@Bool",
  ["userdata"] = "@User",
  ["function"] = "@Func",
  ["table"]    = "@Table",
  ["thread"]   = "@Thread"
}

--[[ Typed data types

  Same as the above table, but reversed.

]]
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

--[[ Typed registry

  A registry were Typed store all created values

]]
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

-- Constructs a table for a Single type value
local function Build_Single(T, V)
  local ErrMsg = "Typed:new [ERROR] => Type mismatch, %s (%s) expected, got %s (%s)"
  local VT = type(V)

  assert(
    VT == _TTypes[T],
    ErrMsg:format(T, _TTypes[T], _LTypes[VT], VT)
  )

  return {
    _type = _TTypes[T],
    _val = V,
    _is = "Single"
  }
end

local function Build_Struct(T, ...)
  local va = { ... }
  local struct = {
    _type = _TTypes[T],
    _is = "Struct"
  }

  if #va == 1 then
    for k, v in pairs(va[1]) do
      if type(v) ~= _TTypes[T] then
        return error("Key/index '" .. k .. "' don't match the type " .. T)
      end
    end

    struct._val = va[1]
  elseif #va > 1 then
    struct._val = {}

    for i, v in ipairs(va) do
      if type(v) ~= _TTypes[T] then
        return error("Key/index '" .. i .. "' don't match the type " .. T)
      else
        table.insert(struct._val, v)
      end
    end
  end

  return struct
end

local function Build_Return(T, F, ...)
  local ret = {
    _type = _TTypes[T],
    _is = "Return"
  }

  assert(type(T) == "string", "Bad argument #1, string expected, got " .. type(T))
  assert(type(F) == "function", "Bad argument #2, function expected, got " .. type(F))

  local Ok, Val = pcall(F, ...)

  if not Ok then
    return error("Something's went wrong calling the function!")
  elseif Ok and type(Val) ~= _TTypes[T] then
    return error("Type returned don't match type " .. T)
  elseif Ok and type(Val) == _TTypes[T] then
    ret._val = F
    return ret
  end
end

local function Build_Multiple(Types, ...)
  local obj

  local va    = { ... }
  local match = false
  local mult  = {
    _type = Types,
    _is = "Multiple"
  }

  for _, t in ipairs(Types) do
    if Parse(t) == "Single" and type(va[1]) == _TTypes[t] then
      obj   = Build_Single(t, va[1])
      match = true

    elseif Parse(t) == "Struct" and type(va[1]) == _TTypes[t] then
      obj   = Build_Struct(t, ...)
      match = true

    elseif Parse(t) == "Return" and type(va[1]) == "function" then
      local fn = table.remove(va, 1)
      obj      = Build_Return(t, fn, Unpack(va))
      match    = true

    elseif Parse(t) == "Multiple" and type(va[1]) == _TTypes[t] then
      obj   = Build_Multiple(t, va[1])
      match = true

    end
  end

  if match then
    mult._val = obj._val
    return mult
  else
    return error("Typed:new [ERROR] => Value don't match with any of specified types")
  end
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
  if _TReg[Key] then
    return _TReg[Key]._val
  else
    return error("Key '" .. Key .. "' doesn't exists")
  end
end

function Typed:set(Key, ...)
  local va = { ... }

  if _TReg[Key] then
  else
    return error("Key '" .. Key .. "' doesn't exists")
  end
end

Typed = SetMT(Typed, {
  __call     = Typed.new,
  __index    = Typed.get,
  __newindex = Typed.set
})

-- Some basic tests
Typed('@Str', "test_str", "")
Typed('@Num', "test_num", 0)
Typed('@Bool', "test_bool", true)
Typed('@Func', "test_func", function () end)
Typed('@Table', "test_table", {})
Typed('@Thread', "test_thread", coroutine.create(function () end))

Typed('@Str{}', "test_str_struct", { "" })
Typed('@Num{}', "test_num_struct", { 0 })
Typed('@Bool{}', "test_bool_struct", { true })
Typed('@Func{}', "test_func_struct", { function () end })
Typed('@Table{}', "test_table_struct", { {} })
Typed('@Thread{}', "test_thread_struct", { coroutine.create(function () end) })

Typed('@Str()', "test_str_return", function() return "" end)
Typed('@Num()', "test_num_return", function() return 0 end)
Typed('@Bool()', "test_bool_return", function() return true end)
Typed('@Func()', "test_func_return", function() return function() end end)
Typed('@Table()', "test_table_return", function() return {} end)
Typed('@Thread()', "test_thread_return", function() return coroutine.create(function () end) end)