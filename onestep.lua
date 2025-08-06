#!/usr/bin/env lua

-- onestep.lua - 一步到位将 Lua 文件编译为动态库
-- 用法: lua onestep.lua input.lua

local input_file = arg[1]

if not input_file then
  print("用法: lua onestep.lua input.lua")
  os.exit(1)
end

-- 检查输入文件是否存在
local f = io.open(input_file, "r")
if not f then
  print("错误: 文件 " .. input_file .. " 不存在")
  os.exit(1)
end
f:close()

-- 获取文件名和目录
local function get_filename_and_dir(filepath)
  local dir, filename = filepath:match("^(.-)([^\\/]*)$")
  if dir == "" then
    dir = "./"
  elseif not dir:match("/$") then
    dir = dir .. "/"
  end
  return filename, dir
end

local filename, dir = get_filename_and_dir(input_file)

-- 移除.lua扩展名
local module_name = filename:gsub("%.lua$", "")

-- 生成中间文件名
local c_file = dir .. module_name .. ".c"
local module_c_file = dir .. module_name .. "_module.c"
local lib_ext = ".so"  -- 默认为 Linux/Unix 扩展名

-- 检测操作系统类型
local function get_os_name()
  local os_name = os.getenv("OS") or "unknown"
  local uname = io.popen("uname 2>/dev/null", "r")
  if uname then
    local unamedata = uname:read("*a")
    uname:close()
    if unamedata then
      if unamedata:match("Darwin") then
        return "macos"
      elseif unamedata:match("Linux") or unamedata:match("GNU") then
        return "linux"
      end
    end
  end
  
  -- Windows detection
  if os_name:match("Windows") then
    return "windows"
  end
  
  return "unix"
end

local os_name = get_os_name()
if os_name == "macos" then
  lib_ext = ".dylib"
elseif os_name == "windows" then
  lib_ext = ".dll"
end

local dylib_file = dir .. module_name .. lib_ext

print("操作系统: " .. os_name)
print("输入文件: " .. input_file)
print("C 文件: " .. c_file)
print("模块 C 文件: " .. module_c_file)
print("动态库文件: " .. dylib_file)

-- 步骤1: 使用 lua2c.lua 生成 C 代码
print("\n步骤1: 生成 C 代码...")
local cmd1 = string.format('lua lua2c.lua "%s"', input_file)
print("执行命令: " .. cmd1)
local result1 = os.execute(cmd1)
if result1 ~= 0 then
  print("错误: 生成 C 代码失败")
  os.exit(1)
end

-- 步骤2: 使用 convert_to_module_autoexec.lua 转换为模块
print("\n步骤2: 转换为模块...")
local cmd2 = string.format('lua convert_to_module_autoexec.lua "%s" "%s" "%s"', c_file, module_c_file, module_name)
print("执行命令: " .. cmd2)
local result2 = os.execute(cmd2)
if result2 ~= 0 then
  print("错误: 转换为模块失败")
  os.exit(1)
end

-- 步骤3: 编译为动态库
print("\n步骤3: 编译为动态库...")

-- 查找 Lua 头文件和库文件路径
local function find_lua_paths()
  -- 尝试从环境变量获取路径
  local lua_inc = os.getenv("LUA_INC") or os.getenv("LUA_INCLUDE")
  local lua_lib = os.getenv("LUA_LIB")
  
  -- 如果没有找到，尝试常见路径
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
      "/opt/local/lib"  -- MacPorts
    }
    
    for _, path in ipairs(common_lib_paths) do
      -- 检查常见的 Lua 库文件名
      local lib_names = {"liblua5.1", "liblua51", "liblua"}
      for _, lib_name in ipairs(lib_names) do
        local f = io.open(path .. "/" .. lib_name .. ".so", "r")
        if f then
          f:close()
          lua_lib = path
          break
        end
        
        -- 检查 macOS 特定扩展名
        f = io.open(path .. "/" .. lib_name .. ".dylib", "r")
        if f then
          f:close()
          lua_lib = path
          break
        end
      end
      
      if lua_lib then
        break
      end
    end
  end
  
  return lua_inc, lua_lib
end

-- 查找 Lua 路径
local lua_inc, lua_lib = find_lua_paths()

-- 构建编译命令
local compile_cmd = "gcc -shared -fPIC"

-- 添加包含路径
if lua_inc then
  compile_cmd = compile_cmd .. " -I" .. lua_inc
else
  print("警告: 未找到 Lua 头文件路径，编译可能失败")
end

-- 添加库路径
if lua_lib then
  compile_cmd = compile_cmd .. " -L" .. lua_lib
else
  print("警告: 未找到 Lua 库文件路径，编译可能失败")
end

-- 添加 Lua 库链接
compile_cmd = compile_cmd .. " -llua"

-- 添加输入和输出文件
compile_cmd = compile_cmd .. ' "' .. module_c_file .. '" -o "' .. dylib_file .. '"'

print("执行命令: " .. compile_cmd)
local result3 = os.execute(compile_cmd)
if result3 ~= 0 then
  print("错误: 编译动态库失败")
  os.exit(1)
end

print("\n成功: 已生成动态库 " .. dylib_file)
print("\n使用方法:")
print('  package.cpath = "./?.dylib;" .. package.cpath  -- 根据需要调整路径')
print('  local module = require("' .. module_name .. '")')