[![License][LicenseBadge]][licenseURL]

# Static

Basic static typing support library for Lua.

## Contents

  - [Features](#features)
  - [Documentation](#documentation)
  - [Specification](#specification)
  	- [Basic](#basic)
  	- [Struct](#struct)
  	- [Return](#return)
  	- [Mixed](#mixed)
  - [Examples](#examples)
  - [Limitations](#limitations)
  - [Thanks](#thanks)

## Features

  - Basic typing
  - Tables with only one type
  - Functions with return type
  - Values that can be one or more types

## Documentation

Static uses metatables and the `type()` function to work, so, this means that can be slow because metatables are an abstraccion layer and `type()` is slow by default. This can be a problem, so, to solve it, Static provides a `setup()` function, that is called when you load Static:

```lua
local Static = require("Static").setup(true)
```

Call this function is mandatory and basically what it does is enable or disable type checking using `true` or `false` respectivelly. This allows you to increase performance when the user runs your app disabling type checking, but in development, you're still using static typing.

Having said that, Static provides a simple and easy to use API, exposing only 3 methods:

  - `new(Dec, Key, Val, ...)`: Creates a new typed value and store it into an internal registry. Arguments:
    - (`string` or `table`) `Dec` The TDM for the given value (see the specification below)
    - (`string`) `Key` An identifier to use for store the given value
    - `Val` The value to store
    - `...` Variadic arguments, used only in functions returns (if needed)

  - `set(Key, Val, ...)`: Set a new value for the given identifier
    - (`string`) `Key` The identifier that you used when created the typed value
    - `Val` The new value to store
    - `...` Variadic arguments, used only in functions returns (if needed)

  - `get(Key)`: Get the value for the given identifier
    - (`string`) `Key` The identifier that you used when created the typed value

As I said before, Static uses metatables, so... You can:

  - Call: `Static(...)`. This is the same has `Static:new(...)`
  - Index: `Static.something`. This is the same has `Static:get("something")`
  - Set: `Static.something = "ª"`. This is the same has `Static:set("something", "ª")`

Learn more about that in the [Examples](#examples) section

### Specification

> This specification tries to give you the knowledge needed to start using Static.

All types in Static starts with a `@` ("at") symbol and is inmediatelly followed by a name in [Capital Case][Capitalization]. This is for try to remarks a bit more the TDM and helps you to think something like *"Oh, this is a Static type, because starts with the `@` symbol, isn't a 'regular' string!"*. The following table has all the supported types:

| Static    | Lua        |
|:----------|:-----------|
| `@Str`    | `string`   |
| `@Num`    | `number`   |
| `@Bool`   | `boolean`  |
| `@User`   | `userdata` |
| `@Func`   | `function` |
| `@Table`  | `table`    |
| `@Thread` | `thread`   |

Note that if you don't use the exact Static type name, then that may result in unexpected behaviors, because Static don't make intese analysis of it.

That's all about types in general, but you may think *"What the heck is 'TDM'?"*... Well, basically means "Type Declaration Mode" and is very important, because is the way in how Static works. Currently, Static supports only 4 TDM's (*Basic*, *Struct*, *Return* and *Mixed*), see them below.

#### Basic

A value that can be only the specified type. This is done with the syntax: `@Type`. Example:

```lua
Static('@Num', "Num", 0)
```

This means that the value (stored as `Num`) can be only a number.

#### Struct

Tables that can have only one value type. This is done with the syntax: `@Type{}`. Example:

```lua
Static('@Bool{}', "Booleans", { true, false })
```

This means that the given table (stored as `Booleans`) can have only boolean values inside.

#### Return

A function that returns an specified value type. This is done with the syntax: `@Type()`. Example:

```lua
Static('@Table()', "NewTable", function ()
  return {}
end)
```

This means that the given function (stored as `NewTable`) can return only tables.

#### Mixed

Values that can be two or more types. This is done with the syntax: `{ ... }`. Example:

```lua
Static({ '@Str', '@Num' }, "Mix", 0)
```

This means that the given value (stored as `Mix`) can be both, an string or a number.

## Examples

See [Examples.lua](Examples.lua)

## Limitations

See [Limitations.md](Limitations.md)

## Thanks

To @darltrash for helping me to implement the `setup()` function and the idea itself.

[LicenseBadge]: https://img.shields.io/badge/License-Zlib-brightgreen?style=for-the-badge
[LicenseURL]: https://opensource.org/licenses/Zlib
[Capitalization]: https://en.wikipedia.org/wiki/Capitalization