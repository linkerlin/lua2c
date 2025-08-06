-- lua2c.lua - Driver for lua2c - converts Lua 5.1 source to C code.
--
-- STATUS:
--   WARNING: This code passes much of the Lua 5.1 test suite,
--   but there could still be errors.  In particular, a few
--   language features (e.g. coroutines) are not implemented.
--
--   Unimplemented Lua language features:
--    - deprecated old style vararg (arg) table inside vararg functions
--      (LUA_COMPAT_VARARG)
--    - debug.getinfo(f, 'n').name for C-based functions
--    - setfenv does not permit C-based functions
--    - how well do tail call optimizations work?
--    - how to handle coroutines? (see README)
--    Note: A few things (coroutines) might remain
--      unimplemented--see README file file for details.
--
--   Possible improvements:
--    - Fix: large numerical literals can give gcc warnings such as
--      'warning: integer constant is too large for "long" type').
--      Literal numbers are rendered as C integers literals (e.g. 123)
--      rather than C double literals (eg. 123.0).  
--    - improved debug tracebacks on exceptions
--    - See items marked FIX in below code.
--
-- SOURCE:
--
--   http://lua-users.org/wiki/LuaToCee
--
--   (c) 2008 David Manura.  Licensed in the same terms as Lua (MIT license).
--   See included LICENSE file for full licensing details.
--   Please post any patches/improvements.
--

local _G           = _G
local assert       = _G.assert
local error        = _G.error
local io           = _G.io
local ipairs       = _G.ipairs
local os           = _G.os
local package      = _G.package
local require      = _G.require
local string       = _G.string
local table        = _G.table

package.path = './lib/?.lua;' .. package.path

-- note: includes gg/mlp Lua parsing Libraries taken from Metalua.
require "lexer"
require "gg"
require "mlp_lexer"
require "mlp_misc"
require "mlp_table"
require "mlp_meta"
require "mlp_expr"
require "mlp_stat"
require "mlp_ext"
_G.mlc = {} -- make gg happy
local mlp = assert(_G.mlp)
local A2C = require "lua2c.ast2cast"
local C2S = require "lua2c.cast2string"

local function NOTIMPL(s)
  error('FIX - NOT IMPLEMENTED: ' .. s, 2)
end

local function DEBUG(...)
  local ts = {...}
  for i,v in ipairs(ts) do
    ts[i] = table.tostring(v,'nohash',60)
  end
  io.stderr:write(table.concat(ts, ' ') .. '\n')
end

-- Converts Lua source string to Lua AST (via mlp/gg)
local function string_to_ast(src)
  local  lx  = mlp.lexer:newstream (src)
  local  ast = mlp.chunk (lx)
  return ast
end
-- Command line argument parsing
local src_filename = nil
local compile = false

-- Check if we have at least one argument
if not arg or not arg[1] then
  io.stderr:write("usage: lua2c [--compile] filename.lua\n")
  os.exit(1)
end

-- Parse arguments
for i = 1, #arg do
  if arg[i] == "--compile" then
    compile = true
  else
    src_filename = arg[i]
  end
end

if not src_filename then
  io.stderr:write("usage: lua2c [--compile] filename.lua\n")
  os.exit(1)
end

-- Generate output filename by replacing .lua extension with .c
local output_filename = src_filename:gsub("%.lua$", "") .. ".c"

local src_file = assert(io.open (src_filename, 'r'))
local src = src_file:read '*a'; src_file:close()
src = src:gsub('^#[^\r\n]*', '') -- remove any shebang

local ast = string_to_ast(src)

local cast = A2C.ast_to_cast(src, ast)
-- DEBUG(cast)

-- Write output to file instead of stdout
local output_file = assert(io.open(output_filename, 'w'))
output_file:write(C2S.cast_to_string(cast))
output_file:close()

-- Print a message to stdout to indicate success
io.stdout:write("Generated " .. output_filename .. "\n")

-- Function to detect OS and return appropriate library extension
local function get_lib_extension()
  local osname = os.getenv("OS") or "unknown"
  local uname = io.popen("uname 2>/dev/null", "r")
  if uname then
    local unamedata = uname:read("*a")
    uname:close()
    if unamedata then
      if unamedata:match("Darwin") then
        return ".dylib"  -- macOS
      elseif unamedata:match("Linux") or unamedata:match("GNU") then
        return ".so"     -- Linux and other Unix-like systems
      end
    end
  end
  
  -- Windows detection
  if osname:match("Windows") then
    return ".dll"
  end
  
  -- Default to .so for Unix-like systems
  return ".so"
end

-- Function to find Lua paths
local function find_lua_paths()
  -- Try to find Lua paths from environment variables
  local lua_inc = os.getenv("LUA_INC") or os.getenv("LUA_INCLUDE")
  local lua_lib = os.getenv("LUA_LIB")
  
  -- If not found in environment, try common paths
  if not lua_inc then
    local common_inc_paths = {
      "/usr/include/lua5.1",
      "/usr/include/lua51",
      "/usr/include/lua",
      "/usr/local/include/lua5.1",
      "/usr/local/include/lua51",
      "/usr/local/include/lua",
      "/opt/local/include/lua5.1",  -- MacPorts
      "/opt/local/include/lua51",
      "/opt/local/include/lua"
    }
    
    for _, path in ipairs(common_inc_paths) do
      local f = io.open(path .. "/lua.h", "r")
      if f then
        f:close()
        lua_inc = path
        break
      end
    end
  end
  
  if not lua_lib then
    local common_lib_paths = {
      "/usr/lib",
      "/usr/local/lib",
      "/opt/local/lib",  -- MacPorts
      ".",               -- Current directory
      "../lua/lib"       -- Relative path as mentioned by user
    }
    
    for _, path in ipairs(common_lib_paths) do
      -- Check for liblua.a specifically as mentioned by user
      local f = io.open(path .. "/liblua.a", "r")
      if f then
        f:close()
        lua_lib = path
        break
      end
    end
  end
  
  return lua_inc, lua_lib
end

-- Auto-compile to dynamic library if requested
if compile then
  -- Determine library extension based on OS
  local lib_ext = get_lib_extension()
  local lib_filename = src_filename:gsub("%.lua$", "") .. lib_ext
  
  -- Find Lua paths
  local lua_inc, lua_lib = find_lua_paths()
  
  -- Build gcc command
  local cmd = "gcc -shared -fPIC"
  
  -- Add include path if found
  if lua_inc then
    cmd = cmd .. " -I" .. lua_inc
  end
  
  -- Add library path and link liblua.a if found
  if lua_lib then
    cmd = cmd .. " -L" .. lua_lib .. " " .. lua_lib .. "/liblua.a"
  else
    -- If not found, try to link with common library names
    cmd = cmd .. " -llua5.1 -llua51 -llua"  -- Try common library names
  end
  
  -- Add output file and input file
  cmd = cmd .. " -o " .. lib_filename .. " " .. output_filename
  
  -- Print the command for debugging
  io.stdout:write("Compiling with: " .. cmd .. "\n")
  
  -- Execute the command
  local result = os.execute(cmd)
  
  if result == 0 then
    io.stdout:write("Generated " .. lib_filename .. "\n")
  else
    io.stderr:write("Compilation failed\n")
    os.exit(1)
  end
end


