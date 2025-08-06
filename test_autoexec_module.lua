-- 测试自动执行模块

print("=== 测试自动执行模块 ===")

-- 确保 cpath 包含当前目录
package.cpath = "./?.dylib;" .. package.cpath

-- 检查文件是否存在
local function file_exists(filepath)
  local f = io.open(filepath, "r")
  if f then
    f:close()
    return true
  end
  return false
end

print("文件检查:")
print("hello.dylib 存在:", file_exists("hello.dylib"))

-- 重新生成模块以确保使用最新版本
print("\n重新生成模块...")
os.execute("lua onestep.lua examples-lua/hello.lua")

-- 测试模块加载和自动执行
print("\n=== 测试模块加载和自动执行 ===")
package.loaded.hello = nil  -- 卸载可能已加载的模块

print("加载 hello 模块...")
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

print("\n=== 测试完成 ===")