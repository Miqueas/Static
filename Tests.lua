local Static = require("Static")
local Unp    = table.unpack or unpack

function Fn() end

-- Tests for "Basic"
Static('@Str', "test_str", "ª")
print(Static.test_str)

Static('@Num', "test_num", 0)
print(Static.test_num)

Static('@Bool', "test_bool", true)
print(Static.test_bool)

Static('@User', "test_user", io.stdout)
print(Static.test_user)
Static.test_user:write("Yeah, bOi\n")

Static('@Func', "test_func", Fn)
print(Static.test_func)
Static.test_func()

Static('@Table', "test_table", {})
print(Static.test_table)
Static.test_table[1] = "yEs"

Static('@Thread', "test_thread", coroutine.create(Fn))
print(Static.test_thread)

-- Tests for "Struct"
Static('@Str{}', "test_str_struct", { str = "String Struct" })
print(Static.test_str_struct.str)
Static.test_str_struct.key = "value"
print(Static.test_str_struct.key)
-- Not allowed:
-- Static.test_str_struct.no = 0

Static('@Num{}', "test_num_struct", { num = 0 })
Static('@Bool{}', "test_bool_struct", { bool = true })
Static('@User{}', "test_user_struct", { user = io.stdout })
Static('@Func{}', "test_func_struct", { func = Fn })
Static('@Table{}', "test_table_struct", { table = {} })
Static('@Thread{}', "test_thread_struct", { thread = coroutine.create(Fn) })

-- Tests for "Return"
Static('@Str()', "test_str_return", function() return "" end)
Static('@Num()', "test_num_return", function() return 0 end)
Static('@Bool()', "test_bool_return", function() return true end)
Static('@User()', "test_user_return", function() return io.stdout end)
Static('@Func()', "test_func_return", function() return Fn end)
Static('@Table()', "test_table_return", function() return {} end)
Static('@Thread()', "test_thread_return", function() return coroutine.create(Fn) end)

-- Tests for "Mixed"
Static({ '@Str', '@Str{}', '@Str()' }, "test_str_mixed", "Yes")
print(Static.test_str_mixed)
Static.test_str_mixed = { "Allowed :)" }
print(Static.test_str_mixed[1])
Static.test_str_mixed = function() return "Functions", "returns", "!" end
print(Static.test_str_mixed())

Static({ '@Num', '@Num{}', '@Num()' }, "test_num_mixed_basic", 0)
Static({ '@Num', '@Num{}', '@Num()' }, "test_num_mixed_struct", { 0 })
Static({ '@Num', '@Num{}', '@Num()' }, "test_num_mixed_return", function() return 0 end)
Static({ { '@Num', '@Num{}', '@Num()' } }, "test_num_mixed_mixed", function() return 0 end)

Static({ '@Bool', '@Bool{}', '@Bool()' }, "test_bool_mixed_basic", true)
Static({ '@Bool', '@Bool{}', '@Bool()' }, "test_bool_mixed_struct", { true })
Static({ '@Bool', '@Bool{}', '@Bool()' }, "test_bool_mixed_return", function() return true end)
Static({ { '@Bool', '@Bool{}', '@Bool()' } }, "test_bool_mixed_mixed", function() return true end)

Static({ '@User', '@User{}', '@User()' }, "test_user_mixed_basic", io.stdout)
Static({ '@User', '@User{}', '@User()' }, "test_user_mixed_struct", { io.stdout })
Static({ '@User', '@User{}', '@User()' }, "test_user_mixed_return", function() return io.stdout end)
Static({ { '@User', '@User{}', '@User()' } }, "test_user_mixed_mixed", function() return io.stdout end)

Static({ '@Func', '@Func{}', '@Func()' }, "test_func_mixed_basic", Fn)
Static({ '@Func', '@Func{}', '@Func()' }, "test_func_mixed_struct", { Fn })
Static({ '@Func', '@Func{}', '@Func()' }, "test_func_mixed_return", function() return Fn end)
Static({ { '@Func', '@Func{}', '@Func()' } }, "test_func_mixed_mixed", function() return Fn end)

Static({ '@Table', '@Table{}', '@Table()' }, "test_table_mixed_basic", {})
Static({ '@Table', '@Table{}', '@Table()' }, "test_table_mixed_struct", { {} })
Static({ '@Table', '@Table{}', '@Table()' }, "test_table_mixed_return", function() return {} end)
Static({ '@Table', '@Table{}', '@Table()' }, "test_table_mixed_mixed", function() return {} end)

Static({ '@Thread', '@Thread{}', '@Thread()' }, "test_thread_mixed_basic", coroutine.create(Fn))
Static({ '@Thread', '@Thread{}', '@Thread()' }, "test_thread_mixed_struct", { coroutine.create(Fn) })
Static({ '@Thread', '@Thread{}', '@Thread()' }, "test_thread_mixed_return", function() return coroutine.create(Fn) end)
Static({ { '@Thread', '@Thread{}', '@Thread()' } }, "test_thread_mixed_mixed", function() return coroutine.create(Fn) end)

-- A more complex tests
Static({ '@Str', '@Num', '@Bool', '@User', '@Func', '@Table', '@Thread' }, "test_complex", {})
print(Static.test_complex)
Static.test_complex = "Works!"
print(Static.test_complex)
Static.test_complex = 3.14159
print(Static.test_complex)
Static.test_complex = true
print(Static.test_complex)
Static.test_complex = function (a, b) return (a or 0) + (b or 0) end
print(Static.test_complex)
print(Static.test_complex(8734, 23049))
Static.test_complex = io.stdout
Static.test_complex:write("HMMmMmMmmMmmMmMmMm... YeSSsSss\n")