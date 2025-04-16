local kLog = require("log")

local function main()
    print("程序开始")
    kLog.init()
    for i = 1, 2000000 do
        kLog.p("日志 " .. i .. " 打印")
    end
    kLog.dispose()
end

local status, err = pcall(main, nil)
if not status then
    local errDomain
    if type(err) == "table" then
        errDomain = kLog.formatTable(err)
    else
        errDomain = err
    end
    print(string.format("errDomain %s", errDomain))
end
print("程序结束")
os.exit()