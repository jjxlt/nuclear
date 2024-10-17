local kLog = require("log")

local data = {
    id = 0,
    name = "Field Gong",
    info = {
        age = 26,
        height = 172,
        avatar = "www.baidu.com"
    }
}

print(kLog.formatTable(data))
