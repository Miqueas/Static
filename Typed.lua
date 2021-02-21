local Typed = {
  -- Registry
  _Reg = {},
  -- Types
  _Types = {
    ["@Str"]    = "string",
    ["@Num"]    = "number",
    ["@Bool"]   = "boolean",
    ["@User"]   = "userdata",
    ["@Func"]   = "function",
    ["@Table"]  = "table",
    ["@Thread"] = "thread"
  }
}

function Typed:new(TDef, Key, Val)
  -- Some type checking
  assert(
    type(TDef) == "string" or type(TDef) == "table",
    "Bad argument #1 for Typed:new, table or string expected, got " .. type(TDef)
  )

  assert(
    #TDef > 0,
    "Argument #1 is given, but length is 0 (in Typed:new)"
  )

  assert(
    type(Key) == "string",
    "Bad argument #2 for Typed:new, string expected, got " .. type(Key)
  )
  -- End type checking

  if type(TDef) == "string" then
    assert(
      type(Val) == self._Types[TDef],
      "Typed:new [ERROR] => Type mismatch, " .. self._Types[TDef] .. " expected, got " .. type(Val)
    )

    self._Reg[Key] = {
      _type = self._Types[TDef],
      _val = Val
    }

  elseif type(TDef) == "table" then
    local len = #TDef
    local match = 0

    self._Reg[Key] = { _type = TDef }

    for i, v in ipairs(TDef) do
      if type(Val) == self._Types[v] then
        match = match + 1
      end
    end

    if match > 0 then
      self._Reg[Key]._val = Val
    else
      return error("Typed:new [ERROR] => Type mismatch, value don't match with any of specified types")
    end
  end

  return self
end

--[[ Format:

[DONE] @Type ==> just @Type
[DONE] { @Type1, @Type2, ..., @TypeN } ==> can be @Type1 or @Type2 or @TypeN
[TODO] @Type{} ==> a table of @Type

]]

-- Nais bro
Typed:new("@Str", "salutations", "Hello, world!")
-- Error bro
Typed:new({ "@Num", "@Str", "@Bool" }, "test", {})
