local Static = require("Static")
local Unp    = table.unpack or unpack

-- Creates some values
-- This can be only an string
Static('@Str', "name", "Juan 😎")
-- This can be only a number
Static('@Num', "age", 325)

print(Static.name .. " is " .. Static.age .. "yo")

-- Lets look Structs (tables)
function Fib(n)
  if n == 0 or n == 1 then
    return n
  else
    return Fib(n - 1) + Fib(n - 2)
  end
end

Static('@Num{}', "Fib_Numbers", { [0] = 0 })

for i = 1, 10 do
  Static.Fib_Numbers[i] = Fib(i)
end

print(#Static.Fib_Numbers)
print(Unp(Static.Fib_Numbers))

-- What about functions?
Static('@Str()', "Greet", function (Name)
  return "Hello " .. (Name or "guest") .. "!"
end)

print(Static.Greet(Static.name))

-- If you're ok with more than one type, then try
-- a Mixed value!
Static({ '@Num', '@Bool' }, "idk", true)
print(Static.idk)
Static.idk = 3.14159
print(Static.idk)

-- @Thread is for coroutines
Static('@Thread', "co", coroutine.create(
    function ()
      print("This")
      coroutine.yield()
      print("is")
      coroutine.yield()
      print("a")
      coroutine.yield()
      print("thread")
      coroutine.yield()
    end
  )
)

print(coroutine.resume(Static.co))
print(coroutine.resume(Static.co))
print(coroutine.resume(Static.co))
print(coroutine.resume(Static.co))
print(coroutine.resume(Static.co))

-- @User is for userdata
Static('@User', "In", io.stdin)
Static('@User', "Out", io.stdout)
Static.Out:write("Enter something: ")
Static('@Str', "input", Static.In:read())
Static.Out:write("You entered: '" .. Static.input .. "'\n")

-- Check out the Test.lua file for more examples of usage