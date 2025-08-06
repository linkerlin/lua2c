-- 测试修复版模块的脚本

-- 显示当前的 package.path 和 package.cpath
print("package.path:")
print(package.path)
print("\npackage.cpath:")
print(package.cpath)

-- 确保 cpath 包含当前目录的动态库
package.cpath = "./?.dylib;" .. package.cpath
print("\n更新后的 package.cpath:")
print(package.cpath)

-- 测试1: 在 examples-lua 目录下加载模块
print("\n=== 测试1: 在 examples-lua 目录下加载模块 ===")
-- 切换到 examples-lua 目录
local old_pwd = io.popen("pwd"):read("*l")
print("切换前目录:", old_pwd)

-- 更改工作目录到 examples-lua
os.execute("cd examples-lua")

-- 更新 package.cpath 以包含 examples-lua 目录
package.cpath = "./?.dylib;../?.dylib;" .. package.cpath
print("更新后的 package.cpath:")
print(package.cpath)

-- 尝试加载 hello 模块
package.loaded["hello"] = nil  -- 卸载模块（如果已加载）
local ok, result = pcall(require, "hello")
if ok then
  print("成功加载 hello 模块")
  print("返回值:", result)
  
  -- 尝试调用模块函数
  if type(result) == "function" then
    print("调用模块函数:")
    result()
  elseif type(result) == "table" then
    print("模块返回一个表:")
    for k, v in pairs(result) do
      print("  ", k, v)
    end
    
    -- 如果模块表中有 hello 函数，调用它
    if type(result.hello) == "function" then
      print("调用 hello.hello():")
      result.hello()
    end
  else
    print("模块返回:", result)
  end
else
  print("加载 hello 模块失败:", result)
end

-- 测试2: 在项目根目录下加载模块
print("\n=== 测试2: 在项目根目录下加载模块 ===")
-- 更改工作目录到项目根目录
os.execute("cd ..")
local new_pwd = io.popen("pwd"):read("*l")
print("切换后目录:", new_pwd)

-- 更新 package.cpath 以包含 examples-lua 目录
package.cpath = "./examples-lua/?.dylib;./?.dylib;" .. package.cpath
print("更新后的 package.cpath:")
print(package.cpath)

-- 尝试加载 hello 模块
package.loaded["hello"] = nil  -- 卸载模块（如果已加载）
local ok2, result2 = pcall(require, "hello")
if ok2 then
  print("成功加载 hello 模块")
  print("返回值:", result2)
  
  -- 尝试调用模块函数
  if type(result2) == "function" then
    print("调用模块函数:")
    result2()
  elseif type(result2) == "table" then
    print("模块返回一个表:")
    for k, v in pairs(result2) do
      print("  ", k, v)
    end
    
    -- 如果模块表中有 hello 函数，调用它
    if type(result2.hello) == "function" then
      print("调用 hello.hello():")
      result2.hello()
    end
  else
    print("模块返回:", result2)
  end
else
  print("加载 hello 模块失败:", result2)
end

print("\n=== 总结 ===")
print("1. 修复版模块应该能正确加载")
print("2. 模块应该注册一个名为 'hello' 的函数")
print("3. 可以通过 require('hello') 加载模块，然后调用 hello() 函数执行代码")