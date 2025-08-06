-- 测试 dylib 模块加载问题

print("=== 测试 dylib 模块加载 ===")

-- 显示当前路径设置
print("package.path:")
print(package.path)
print("\npackage.cpath:")
print(package.cpath)

-- 确保 cpath 包含当前目录
package.cpath = "./?.dylib;" .. package.cpath
print("\n更新后的 package.cpath:")
print(package.cpath)

-- 检查文件是否存在
local function file_exists(filepath)
  local f = io.open(filepath, "r")
  if f then
    f:close()
    return true
  end
  return false
end

print("\n文件检查:")
print("hello.dylib 存在:", file_exists("hello.dylib"))
print("examples-lua/hello.dylib 存在:", file_exists("examples-lua/hello.dylib"))
print("examples-lua/hello.lua 存在:", file_exists("examples-lua/hello.lua"))

-- 测试1: 在项目根目录加载 hello 模块
print("\n=== 测试1: 在项目根目录加载 hello 模块 ===")
package.loaded.hello = nil  -- 卸载可能已加载的模块

local ok, result = pcall(require, "hello")
if ok then
  print("成功加载 hello 模块")
  print("返回值类型:", type(result))
  print("返回值:", result)
  
  if type(result) == "table" then
    print("模块表内容:")
    for k, v in pairs(result) do
      print("  ", k, type(v))
    end
    
    -- 尝试调用模块函数
    if type(result.hello) == "function" then
      print("调用 result.hello():")
      result.hello()
    end
  elseif type(result) == "function" then
    print("调用模块函数:")
    result()
  end
else
  print("加载 hello 模块失败:", result)
end

-- 测试2: 明确指定路径加载
print("\n=== 测试2: 明确指定路径加载 ===")
package.loaded.hello = nil  -- 卸载可能已加载的模块

-- 复制 dylib 到项目根目录（如果不存在）
if file_exists("examples-lua/hello.dylib") and not file_exists("hello.dylib") then
  os.execute("cp examples-lua/hello.dylib hello.dylib")
  print("已复制 examples-lua/hello.dylib 到项目根目录")
end

-- 重新尝试加载
local ok2, result2 = pcall(require, "hello")
if ok2 then
  print("成功加载 hello 模块")
  print("返回值类型:", type(result2))
  print("返回值:", result2)
  
  if type(result2) == "table" then
    print("模块表内容:")
    for k, v in pairs(result2) do
      print("  ", k, type(v))
    end
    
    -- 尝试调用模块函数
    if type(result2.hello) == "function" then
      print("调用 result2.hello():")
      result2.hello()
    end
  elseif type(result2) == "function" then
    print("调用模块函数:")
    result2()
  end
else
  print("加载 hello 模块失败:", result2)
end

print("\n=== 测试完成 ===")