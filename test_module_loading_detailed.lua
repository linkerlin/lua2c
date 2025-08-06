-- 详细的测试脚本，用于验证 Lua 模块加载机制

-- 显示当前的 package.path 和 package.cpath
print("package.path:")
print(package.path)
print("\npackage.cpath:")
print(package.cpath)

-- 测试1: 检查文件是否存在
print("\n=== 检查文件是否存在 ===")
local function file_exists(filepath)
  local f = io.open(filepath, "r")
  if f then
    f:close()
    return true
  end
  return false
end

print("examples-lua/hello.lua 存在:", file_exists("examples-lua/hello.lua"))
print("examples-lua/hello.dylib 存在:", file_exists("examples-lua/hello.dylib"))
print("hello.dylib 存在:", file_exists("hello.dylib"))

-- 测试2: 在项目根目录下加载 "hello"，明确设置 cpath
print("\n=== 测试2: 在项目根目录下加载 'hello'，明确设置 cpath ===")
-- 保存原始路径
local original_cpath = package.cpath

-- 添加当前目录到 cpath
package.cpath = "./?.dylib;" .. original_cpath
print("新的 package.cpath:")
print(package.cpath)

-- 尝试加载 hello 模块
local ok, result = pcall(require, "hello")
if ok then
  print("成功加载 hello 模块")
  print("返回值:", result)
else
  print("加载 hello 模块失败:", result)
end

-- 测试3: 移动 hello.dylib 到项目根目录后加载
print("\n=== 测试3: 移动 hello.dylib 到项目根目录后加载 ===")
-- 首先检查文件是否存在
if file_exists("examples-lua/hello.dylib") then
  -- 移动文件
  os.execute("cp examples-lua/hello.dylib hello.dylib")
  print("已将 examples-lua/hello.dylib 复制到项目根目录")
  
  -- 再次尝试加载 hello 模块
  package.loaded["hello"] = nil  -- 卸载模块（如果已加载）
  local ok2, result2 = pcall(require, "hello")
  if ok2 then
    print("成功加载 hello 模块")
    print("返回值:", result2)
  else
    print("加载 hello 模块失败:", result2)
  end
else
  print("examples-lua/hello.dylib 不存在，跳过测试")
end

-- 测试4: 检查为什么在 examples-lua 目录下会加载 hello.lua 而不是 hello.dylib
print("\n=== 测试4: 检查为什么在 examples-lua 目录下会加载 hello.lua 而不是 hello.dylib ===")
-- 切换到 examples-lua 目录
local old_pwd = io.popen("pwd"):read("*l")
print("切换前目录:", old_pwd)

-- 保存原始路径
local original_path = package.path
local original_cpath = package.cpath

-- 切换目录并设置路径
os.execute("cd examples-lua")
-- 注意：在 Lua 脚本中切换目录不会影响当前 Lua 进程的工作目录
-- 我们需要使用不同的方法来模拟在 examples-lua 目录下的情况

-- 模拟在 examples-lua 目录下的情况
package.path = "./?.lua;" .. original_path
package.cpath = "./?.dylib;" .. original_cpath

print("模拟 examples-lua 目录下的 package.path:")
print(package.path)
print("模拟 examples-lua 目录下的 package.cpath:")
print(package.cpath)

-- 尝试加载 hello 模块
package.loaded["hello"] = nil  -- 卸载模块（如果已加载）
local ok3, result3 = pcall(require, "hello")
if ok3 then
  print("成功加载 hello 模块")
  print("返回值:", result3)
else
  print("加载 hello 模块失败:", result3)
end

-- 恢复原始路径
package.path = original_path
package.cpath = original_cpath

-- 测试5: 重命名 hello.lua 后的行为
print("\n=== 测试5: 重命名 hello.lua 后的行为 ===")
-- 重命名 hello.lua
if file_exists("examples-lua/hello.lua") then
  os.execute("mv examples-lua/hello.lua examples-lua/hello.lua.bak")
  print("已将 examples-lua/hello.lua 重命名为 examples-lua/hello.lua.bak")
  
  -- 再次尝试加载 hello 模块
  package.loaded["hello"] = nil  -- 卸载模块（如果已加载）
  local ok4, result4 = pcall(require, "hello")
  if ok4 then
    print("成功加载 hello 模块")
    print("返回值:", result4)
  else
    print("加载 hello 模块失败:", result4)
  end
  
  -- 恢复文件名
  os.execute("mv examples-lua/hello.lua.bak examples-lua/hello.lua")
  print("已恢复 examples-lua/hello.lua")
else
  print("examples-lua/hello.lua 不存在，跳过测试")
end

print("\n=== 总结 ===")
print("1. Lua 按照 package.path 和 package.cpath 的顺序搜索模块")
print("2. 默认情况下，package.path 包含 './?.lua'，所以 .lua 文件优先于动态库")
print("3. 要加载动态库，需要确保 package.cpath 包含动态库所在的目录")
print("4. 动态库文件名必须与模块名匹配（例如，require('hello') 需要 hello.dylib）")
print("5. 如果同时存在 hello.lua 和 hello.dylib，Lua 会优先加载 hello.lua")