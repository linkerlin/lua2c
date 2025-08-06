#!/usr/bin/env lua

-- 转换 lua2c 生成的 C 代码为 Lua 模块（改进版）
-- 用法: lua convert_to_module_improved.lua input.c output.c module_name

local input_file = arg[1]
local output_file = arg[2]
local module_name = arg[3]

if not input_file or not output_file or not module_name then
  print("用法: lua convert_to_module_improved.lua input.c output.c module_name")
  os.exit(1)
end

-- 读取输入文件
local f = assert(io.open(input_file, "r"))
local content = f:read("*a")
f:close()

-- 移除 main 函数及相关代码
-- 使用更精确的方法逐段移除不需要的代码

-- 移除 traceback 函数
content = content:gsub("static int traceback%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 移除 lc_l_message 函数
content = content:gsub("static void lc_l_message%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 移除 lc_report 函数
content = content:gsub("static int lc_report%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 移除 lc_docall 函数
content = content:gsub("static int lc_docall%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 移除 lc_dofile 函数
content = content:gsub("static int lc_dofile%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 移除 lc_dostring 函数
content = content:gsub("static int lc_dostring%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 移除 lc_handle_luainit 函数
content = content:gsub("static int lc_handle_luainit%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 移除 lc_args_t 结构体定义
content = content:gsub("typedef struct {%s*\n%s*int c;%s*\n%s*const char %*%* v;%s*\n%s*} lc_args_t;%s*\n", "", 1)

-- 移除 lc_createarg 函数
content = content:gsub("static void lc_createarg%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 移除 lc_pmain 函数
content = content:gsub("static int lc_pmain%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 移除 main 函数
content = content:gsub("int main%s*%([^)]*%)%s*{.-\n}%s*\n", "", 1)

-- 生成简单的入口函数名称
-- 使用 "luaopen_" + 模块名称的最后一部分
local module_parts = {}
for part in module_name:gmatch("[^%.]+") do
  table.insert(module_parts, part)
end
local simple_module_name = module_parts[#module_parts]
local entry_function_name = "luaopen_" .. simple_module_name

-- 修改 lcf_main 函数名，使其更符合模块的命名规范
content = content:gsub("lcf_main", "lcf_" .. simple_module_name .. "_main")

-- 添加 Lua 模块入口函数
local module_entry = string.format([[
/* Lua module entry point */
int %s(lua_State *L) {
  /* 创建模块表 */
  lua_newtable(L);
  
  /* 将主函数注册为模块表的一个字段 */
  lua_pushcfunction(L, lcf_%s_main);
  lua_setfield(L, -2, "%s");
  
  /* 返回模块表 */
  return 1;
}
]], entry_function_name, simple_module_name, simple_module_name)

-- 将入口函数添加到文件末尾
content = content .. "\n" .. module_entry

-- 写入输出文件
f = assert(io.open(output_file, "w"))
f:write(content)
f:close()

print("已将 " .. input_file .. " 转换为 Lua 模块 " .. output_file)
print("入口函数名称: " .. entry_function_name)