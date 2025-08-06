# Lua2C - Lua to C Compiler

## Description

This utility converts a given Lua 5.1 source file into an equivalent C source file written in terms of Lua C API calls. At least, this works for a large subset of the Lua language (see limitations below).

The compiler is written entirely in Lua, and no build/install is needed. This project reuses Metalua's gg/mlp parser to convert Lua source to a Metalua-style AST over which the compiler then operates. lua2c does not require Metalua itself though since gg/mlp is bundled in the distribution and is written in pure Lua.

## Key Features

- Converts Lua 5.1 source code to C code using Lua C API
- Written entirely in Lua with no external dependencies
- Supports closures, upvalues, and most Lua language features
- Generates executable C code that can be compiled with standard C compilers
- Includes tools for converting Lua scripts to dynamic libraries

## Usage

### Basic Usage

Example usage:

```bash
lua lua2c.lua test/bisect.lua
```

which generates a C file to standard output.

You may also use the shell script "clua" to compile Lua->C->machine code and execute all in one step. However, you may need to edit the variables in the file to match your system since this utility invokes the C compiler.

```bash
./clua test/bisect.lua
```

lua2c can even compile itself! (Note: the -c option compiles only without running.)

```bash
./clua -c lua2c.lua               # compile lua2c binary
./lua2c examples-lua/bisect.lua   # test
```

### Automatic C File Generation

The modified lua2c.lua can automatically save the generated C code to a file:

```bash
lua lua2c.lua examples-lua/hello.lua
# This will generate examples-lua/hello.c automatically
```

### Automatic Dynamic Library Compilation

The modified lua2c.lua can also automatically compile the generated C code to a dynamic library:

```bash
lua lua2c.lua examples-lua/hello.lua
# This will generate examples-lua/hello.dylib (or .so/.dll) automatically
```

### One-Step Compilation to Dynamic Library

The project now includes a one-step script to convert Lua files directly to dynamic libraries:

```bash
lua onestep.lua examples-lua/hello.lua
```

This will:
1. Generate C code from the Lua file
2. Convert the C code to an auto-executing Lua module
3. Compile it into a dynamic library

To use the generated module:

```lua
package.cpath = "./?.dylib;" .. package.cpath  -- Adjust for your OS
local module = require("hello")
-- The original Lua script code executes automatically when the module is loaded
-- The module table also contains a 'hello' function that can be called again
```

### Module Behavior

When a Lua script is converted to a dynamic library module:

1. **Automatic Execution**: The original Lua script's global code executes automatically when the module is first loaded
2. **Module Table**: The module returns a table containing a function with the same name as the module
3. **Re-execution**: The function can be called again if needed

Example:
```lua
-- Original Lua script (hello.lua):
print("Hello world, from ", _VERSION, "!")

-- After conversion and loading:
package.cpath = "./?.dylib;" .. package.cpath
local hello = require("hello")  -- Outputs: Hello world, from Lua 5.1!
hello.hello()  -- Outputs: Hello world, from Lua 5.1! (again)
```

### Module Conversion

The project includes several scripts for converting generated C code to proper Lua modules:

- `convert_to_module_simple.lua` - Basic conversion
- `convert_to_module_fixed.lua` - Fixed version
- `convert_to_module_improved.lua` - Improved version
- `convert_to_module_final.lua` - Final version (recommended)

## Related Work

- luac2c - This related effort by Hisham Muhammad converts Lua bytecodes to C source, whereas this project converts Lua source to C source.
- luagen++ uses C++ expression templates to translate Lua-like C++ statements to C API calls.
- Python Pyrex does something similar in Python but has the added goal of lowering the boundary between C and Python code.
- Clue by David Given does the opposite: convert C source to Lua source.
- luac + BinToCee allow compilation of Lua source to bytecodes and/or embedding in a C file.

## Potential Uses

- Provide another approach of compiling Lua to machine code (rather than luac + bin2c).
- Streamline the interface between C and Lua code and allow efficient access to C datatypes from Lua.
- Compile Lua to optimized C. For example, by statically determining that certain variables are used in a restricted way, certain code constructs might be simplified to use plain C rather that the Lua C API.
- This could allow certain Lua code written with sufficient care to run at native speeds. Since it compiles to C, it will even work on CPUs where LuaJIT is not available.

## Limitations / Status

WARNING: This code passes much of the Lua 5.1 test suite and can compile itself, but the code is new and there can still be errors. In particular, a few language features (e.g. coroutines) are not implemented. See comments in lua2c.lua for details. Please report bugs/patches on the wiki.

lua2c does not currently support coroutines, functions that normally reject C functions (e.g. setfenv), and possibly tail call optimizations. Not all of these have the exact analogue in C. Coroutines might not ever be supported. However, some solutions might be explored, including possibly generating code that maintains the coroutine context in Lua tables.

Closures and upvalues are implemented, but creating and accessing upvalues is somewhat slow due to the implementation and hopefully can be improved.

Once the code is more complete/robust, more attention can be given to optimizing the code generation. Performance was 25%-75% of regular Lua when running a few tests, but hopefully future optimizations will improve that.

## Lua 5.2 Notes

Note: LuaFiveTwo (as of 5.2.0-work4) deprecates getfenv and setfenv, which eliminates one of the limitations above. LuaFiveTwo has new lua_arith and lua_compare C API function, which eliminate the need for lua2c to reimplement these functions. LuaFiveTwo also has new lua_yieldk, lua_callk, and lua_pcallk functions for coroutines and might help to implement coroutines in lua2c.

## Module Loading

When converting Lua files to dynamic libraries, there are some important considerations:

1. **File Naming**: The dynamic library file must match the module name. For example, `require("hello")` looks for `hello.so` (Linux), `hello.dylib` (macOS), or `hello.dll` (Windows).

2. **Package Path**: Ensure `package.cpath` includes the directory where your dynamic library is located:
   ```lua
   package.cpath = "./?.dylib;" .. package.cpath  -- For macOS
   ```

3. **Module Function Registration**: The converted modules register a table with a function that matches the module name. For example, `require("hello")` returns a table with a `hello` function that can be called.

4. **Lua vs C Module Precedence**: Lua's `package.path` takes precedence over `package.cpath`. If both `hello.lua` and `hello.dylib` exist in the same directory, `require("hello")` will load the Lua file. To force loading the dynamic library, you may need to rename or remove the Lua file.

## Project Page

The project page is currently http://lua-users.org/wiki/LuaToCee .

## Download

- Latest development source (recommended): http://github.com/davidm/lua2c/ .
  From here you can browse the source, download a tar/zip snapshot, or checkout with git by running `git clone git://github.com/davidm/lua2c.git`.
- Last release distribution: (see Project Page above)

## Licensing

(c) 2008 David Manura. Licensed under the same terms as Lua (MIT license). See included LICENSE file for full licensing details. Please post any patches/improvements.

## References

- Metalua AST - http://metalua.luaforge.net/manual006.html#toc17
- luac2c (previously named luatoc) - LuaList:2006-07/msg00144.html
- LHF's lua2c for Lua 4.0 - LuaList:2002-01/msg00296.html
- luagen++ - LuaGenPlusPlus
- Pyrex - http://www.cosc.canterbury.ac.nz/greg.ewing/python/Pyrex/
- Clue - http://cluecc.sourceforge.net/
- Lua 5.1 test suite - http://www.inf.puc-rio.br/~roberto/lua/lua5.1-tests.tar.gz
- Wikipedia:Coroutine - Implementations for C http://en.wikipedia.org/wiki/Coroutine#Implementations_for_C
- Coco - http://luajit.org/coco.html Coco - True C coroutine semantics (used in LuaJIT)
- BinToCee - http://lua-users.org/wiki/BinToCee
- The Computer Language Benchmarks Game http://shootout.alioth.debian.org/gp4/lua.php
- http://lua-users.org/wiki/LuaImplementations - other source translators and Lua reimplementations