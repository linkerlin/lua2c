-- 简单测试自动执行

print("开始测试...")

-- 确保 cpath 包含当前目录
package.cpath = "./?.dylib;" .. package.cpath

-- 卸载模块
package.loaded.hello = nil

-- 加载模块 - 应该自动执行
print("加载模块...")
local module = require("hello")

print("模块加载完成")
print("模块类型:", type(module))

if type(module) == "table" then
  print("模块内容:")
  for k, v in pairs(module) do
    print("  ", k, "=", type(v))
  end
end