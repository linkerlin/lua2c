-- 测试生成的模块
package.cpath = "./examples-lua/?.dylib;" .. package.cpath

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
