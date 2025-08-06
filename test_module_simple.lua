-- 简单的测试脚本

-- 确保 cpath 包含动态库
package.cpath = "./?.dylib;" .. package.cpath

-- 尝试加载 hello 模块
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
  elseif result == "hello" then
    print("模块正确返回 'hello' 字符串")
  else
    print("模块返回:", result)
  end
else
  print("加载 hello 模块失败:", result)
end