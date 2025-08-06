-- echo command line arguments

-- table.getn 已废弃，使用 # 操作符替代，且 Lua 数组索引通常从 1 开始
for i=1,#arg do
 print(i,arg[i])
end
