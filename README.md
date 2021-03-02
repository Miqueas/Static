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

Static uses metatables and the `type()` function to work, this can cause overhead because metatables and `type()` are slow by default so to solve it, Static provides a `setup()` function that is called when you load Static:

```lua
local Static = require("Static").setup(true)
```

Calling this function is mandatory and it enables or disables type checking using `true` or `false` respectivelly. This allows you to increase performance when shipping your app since you can deactivate the library as a whole, but still being able to typecheck on your side

That said, Static provides a simple and easy to use API, exposing only 3 methods:

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

As I said before, Static uses metatables, so you can:

  - Call: `Static(...)`. This is the same as `Static:new(...)`
  - Index: `Static.something`. This is the same as `Static:get("something")`
  - Set: `Static.something = "ª"`. This is the same as `Static:set("something", "ª")`

Learn more in the [Examples](#examples) section

### Specification

> This specification tries to give you the knowledge needed to start using Static.

All types in Static start with a `@` symbol and it's inmediatelly followed by a name in [Capital Case][Capitalization]. This is to attempt highlighting the TDM and helps you not confuse things up, like *"Oh, this is a Static type, because starts with the `@` symbol unlike a 'regular' type!"*. The following table contains all the supported types:

| Static    | Lua        |
|:----------|:-----------|
| `@Str`    | `string`   |
| `@Num`    | `number`   |
| `@Bool`   | `boolean`  |
| `@User`   | `userdata` |
| `@Func`   | `function` |
| `@Table`  | `table`    |
| `@Thread` | `thread`   |

Note that if you don't use the exact Static type name, it may result in unexpected behaviours because Static don't make an intense analysis of it.

That's all about types in general, but you may think *"What the heck is a 'TDM'?"*... Well, basically means "Type Declaration Mode" and it is very important, because it's the way of how Static works. Currently, Static supports only 4 TDMs (*Basic*, *Struct*, *Return* and *Mixed*), see them below.

#### Basic

A value that can be only of the specified type. This is done with the syntax: `@Type`. Example:

```lua
Static('@Num', "Num", 0)
```

This means that the value (stored as `Num`) can be only a number.

#### Struct

Tables that can have only one value type. This is done with the syntax: `@Type{}`. Example:

```lua
Static('@Bool{}', "Booleans", { true, false })
```

This means that the given table (stored as `Booleans`) can only contain boolean values.

#### Return

A function that returns a value of a specific type. This is done with the syntax: `@Type()`. Example:

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

To @darltrash for helping me to implement the `setup()` function, polishing the readme and the idea itself.

[LicenseBadge]: https://img.shields.io/badge/License-Zlib-brightgreen?style=for-the-badge
[LicenseURL]: https://opensource.org/licenses/Zlib
[Capitalization]: https://en.wikipedia.org/wiki/Capitalization
