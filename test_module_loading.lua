-- 测试脚本，用于验证 Lua 模块加载机制

-- 显示当前的 package.path 和 package.cpath
print("package.path:")
print(package.path)
print("\npackage.cpath:")
print(package.cpath)

-- 测试1: 在 examples-lua 目录下加载 "hello"
print("\n=== 测试1: 在 examples-lua 目录下加载 'hello' ===")
local old_path = package.path
local old_cpath = package.cpath

-- 保存当前目录
local current_dir = io.popen("pwd"):read("*l")
print("当前目录: " .. current_dir)

-- 切换到 examples-lua 目录
os.execute("cd examples-lua")

-- 尝试加载 hello 模块
local ok, result = pcall(require, "hello")
if ok then
  print("成功加载 hello 模块")
  print("返回值:", result)
else
  print("加载 hello 模块失败:", result)
end

-- 恢复路径
package.path = old_path
package.cpath = old_cpath

-- 测试2: 在项目根目录下加载 "hello"
print("\n=== 测试2: 在项目根目录下加载 'hello' ===")
-- 确保在项目根目录
os.execute("cd ..")

-- 添加当前目录到 cpath
package.cpath = "./?.dylib;" .. package.cpath

-- 尝试加载 hello 模块
local ok2, result2 = pcall(require, "hello")
if ok2 then
  print("成功加载 hello 模块")
  print("返回值:", result2)
else
  print("加载 hello 模块失败:", result2)
end

-- 测试3: 明确指定路径加载动态库
print("\n=== 测试3: 明确指定路径加载动态库 ===")
-- 添加 examples-lua 目录到 cpath
package.cpath = "./examples-lua/?.dylib;" .. package.cpath

-- 尝试加载 examples-lua.hello 模块
local ok3, result3 = pcall(require, "examples-lua.hello")
if ok3 then
  print("成功加载 examples-lua.hello 模块")
  print("返回值:", result3)
else
  print("加载 examples-lua.hello 模块失败:", result3)
end