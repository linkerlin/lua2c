-- trace assigments to global variables

do
 -- a tostring that quotes strings. note the use of the original tostring.
 local _tostring=tostring
 local tostring=function(a)
  if type(a)=="string" then
   return string.format("%q",a)
  else
   return _tostring(a)
  end
 end

 local log=function (name,old,new)
  local t=debug.getinfo(3,"Sl")
  local line=t.currentline
  io.write(t.short_src)
  if line>=0 then io.write(":",line) end
  io.write(": ",name," is now ",tostring(new)," (was ",tostring(old),")","\n")
 end

 local g={}
 local set=function (t,name,value)
  log(name,g[name],value)
  g[name]=value
 end
 setmetatable(getfenv(),{__index=g,__newindex=set})
end

-- an example

-- 示例：演示全局变量跟踪功能
-- 这些赋值操作将被上面定义的元表机制捕获并记录

-- 数字类型赋值
counter = 1
temperature = 2

-- 字符串类型赋值
name = "Lua"

-- 表类型赋值
config = { debug = true, version = "1.0" }

-- 布尔类型赋值
isEnabled = true

-- 重新赋值不同类型的值给同一个变量
counter = 10
counter = "ten"  -- 从数字改为字符串

-- 将变量设置为nil（删除变量）
temperature = nil

-- 再次赋值
temperature = 25.5

-- 打印一些变量的值以验证跟踪效果
print("counter:", counter)
print("temperature:", temperature)
print("name:", name)
print("config:", config)
print("isEnabled:", isEnabled)
