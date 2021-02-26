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

## Features

  - Basic typing
  - Tables with only one type
  - Functions with return type
  - Values that can be one or more types

## Documentation

Static provides a simple and easy to use API, exposing only 3 methods:

  - `new(Dec, Key, ...)`: Creates a new typed value and store it into an internal registry. Arguments:
    - (`string` or `table`) `Dec` The TDM for the given value (see the specification below)
    - (`string`) `Key` An identifier to use for store the given value
    - `...` Variadic arguments, this is explained in the examples

  - `set(Key, ...)`: Set a new value for the given identifier
    - (`string`) `Key` The identifier that you used when created the typed value
    - `...` Variadic arguments, this is explained in the examples

  - `get(Key)`: Get the value for the given identifier
    - (`string`) `Key` The identifier that you used when created the typed value

## Specification

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

__TODO__

## Limitations

__TODO__

[LicenseBadge]: https://img.shields.io/badge/License-Zlib-brightgreen?style=for-the-badge
[LicenseURL]: https://opensource.org/licenses/Zlib
[Capitalization]: https://en.wikipedia.org/wiki/Capitalization