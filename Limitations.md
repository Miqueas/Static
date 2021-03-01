## Limitations

Currently, Static has some limations (may have more, but I only know these) and here I try to explain you that limitations. Also, if I can, I'll solve this problems in the future.

#### Confused behavior in Mixed values

Take a look of this code:

```lua
local Static = require("Static")
Static({ '@Str{}', '@Num{}' }, "m", { 2, 4, 6, 8 })
```

That can be interpreted as `m` is a table that can contains both types, strings __AND__ numbers. But that's wrong, if you try to mix types in the table, Static will throw an error. This is because of how Static works: when you want to create a mixed value, Static iterates through all types declared, and then stops when the first match between type and value is found, if value don't fit with any type declared, then Static throw an error. So... In this case, the table `m` can have both: strings __OR__ numbers (__only one of these at time__).

#### *"I want to add one"*

If you found a limitation (an unexpected problem/behavior or something like the mentioned limitations here), you can open an issue to discuss it and make a pull request to add them here. Also, if you'll do it, then:

  - Add an example
  - Explain it
  - Suggest a solution (if have one or a little idea of one)