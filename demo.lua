#!/usr/bin/env lua

-- Lua2C 功能演示脚本

print("=== Lua2C 功能演示 ===\n")

-- 1. 基本 Lua2C 使用
print("1. 基本 Lua2C 使用:")
print("   lua lua2c.lua examples-lua/hello.lua")
print("   (将生成 C 代码到标准输出)\n")

-- 2. 一键编译为动态库
print("2. 一键编译为动态库:")
print("   lua onestep.lua examples-lua/hello.lua")
print("   (将生成 hello.dylib 动态库)\n")

-- 3. 模块加载和使用
print("3. 模块加载和使用:")
print("   以下是如何加载和使用生成的模块:")

local demo_code = [[
package.cpath = "./?.dylib;" .. package.cpath
local hello = require("hello")
if type(hello) == "table" and type(hello.hello) == "function" then
    hello.hello()  -- 输出: Hello world, from Lua 5.1!
else
    print("模块加载失败或格式不正确")
end
]]

print(demo_code)

-- 4. 创建一个简单的测试脚本
print("4. 创建测试脚本 test_generated_module.lua:")
local test_script_content = [[
-- 测试生成的模块
package.cpath = "./?.dylib;" .. package.cpath

local ok, module = pcall(require, "hello")
if ok then
    print("成功加载 hello 模块")
    if type(module) == "table" then
        print("模块返回一个表:")
        for k, v in pairs(module) do
            print("  ", k, v)
        end
        
        -- 调用模块函数
        if type(module.hello) == "function" then
            print("调用 module.hello():")
            module.hello()
        end
    else
        print("模块返回:", module)
    end
else
    print("加载 hello 模块失败:", module)
end
]]

-- 写入测试脚本文件
local f = io.open("test_generated_module.lua", "w")
if f then
    f:write(test_script_content)
    f:close()
    print("   已创建 test_generated_module.lua")
else
    print("   创建测试脚本文件失败")
end

print("\n5. 运行测试:")
print("   lua test_generated_module.lua")
print("   (将加载并执行生成的模块)\n")

print("=== 演示完成 ===")