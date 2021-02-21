local SetMT = setmetatable
local GetMT = getmetatable

--[[ Spec:

[DONE] (type)     @Type   ==> just @Type
[IN PROCCESS] (struct)    @Type{} ==> a table of @Type
[TODO] (return)   @Type() ==> a function that returns @Type
[DONE] (multiple) { ... } ==> can be multiple types

]]

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

function Typed:new(TDecl, Key, ...)
  local va = { ... }

  -- Some type checking
  assert(
    type(TDecl) == "string" or type(TDecl) == "table",
    "Bad argument #1 for Typed:new, table or string expected, got " .. type(TDecl)
  )

  assert(
    #TDecl > 0,
    "Argument #1 is given, but length is 0 (in Typed:new)"
  )

  assert(
    type(Key) == "string",
    "Bad argument #2 for Typed:new, string expected, got " .. type(Key)
  )

  assert(not self._Reg[Key], "Key '" .. Key .. "' already's exists (in Typed:new)")
  -- End type checking

  if type(TDecl) == "string" then
    if not self:parse(TDecl) then
      return error("Typed:new [ERROR] => Bad type declaration: " .. TDecl)

    elseif self:parse(TDecl) == "type" then
      local ErrMsg = "Typed:new [ERROR] => Type mismatch, %s expected, got %s"

      assert(
        type(va[1]) == self._Types[TDecl],
        ErrMsg:format(self._Types[TDecl], type(va[1]))
      )

      self._Reg[Key] = {
        _type = self._Types[TDecl],
        _val = va[1],
        _is = "type"
      }

    elseif self:parse(TDecl) == "struct" then
      local tstr = TDecl:gsub("[%{%}]", "")

      self._Reg[Key] = {
        _type = self._Types[tstr],
        _is = "table"
      }

      if #va == 1 and type(va[1]) == "table" then
        for k, v in pairs(va[1]) do
          if type(v) ~= self._Types[tstr] then
            error("Key/index '" .. k .. "' don't match the type " .. tstr)
          end
        end

        self._Reg[Key]._val = va[1]
      else
      end

    elseif self:parse(TDecl) == "return" then
    end

  elseif type(TDecl) == "table" then
    local match = false

    self._Reg[Key] = {
      _type = TDecl,
      _is = "multiple"
    }

    for i, v in ipairs(TDecl) do
      if type(va[1]) == self._Types[v] then
        match = true
      end
    end

    if match then
      self._Reg[Key]._val = va[1]
    else
      return error("Typed:new [ERROR] => Value don't match with any of specified types")
    end
  end
end

function Typed:get(Key)
  if self._Reg[Key] then
    return self._Reg[Key]._val
  else
    return error("Key '" .. Key .. "' doesn't exists")
  end
end

function Typed:set(Key, ...)
  local va = { ... }

  if self._Reg[Key] then
  else
    return error("Key '" .. Key .. "' doesn't exists")
  end
end

function Typed:parse(TDecl)
  local TName   = "^ *@%a+ *$"
  local TTable  = "^ *@%a+ *%{ *%} *$"
  local TReturn = "^ *@%a+ *%( *%) *$"

  if TDecl:match(TName) then
    return "type"
  elseif TDecl:match(TTable) then
    return "struct"
  elseif TDecl:match(TReturn) then
    return "return"
  else
    return nil
  end
end

Typed = SetMT(Typed, {
  __call = Typed.new,
  __index = Typed.get,
  __newindex = Typed.set
})

-- Nice
Typed("@Num{}", "nums", { 1, 2, 3, 4 })
print(Typed.nums)

-- Error
Typed("@Str{}", "strings", { 'a', 'b', 'c', 4 })
