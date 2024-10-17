-------------------------------- private --------------------------------
local kConfig = require("config")

local kFile

local kLogData

-------------------------------- private --------------------------------

-------------------------------- public --------------------------------
local kLog = {}

-- 初始化
function kLog.init()
    if not kConfig.kAllowLog then
        return
    end

    kFile = io.open("nuclear.log", "w")
    kLogData = {}

    if kFile == nil then
        error("日志初始化失败")
    end
end

-- 结束
function kLog.dispose()
    if not kConfig.kAllowLog then
        return
    end

    for index, value in ipairs(kLogData) do
        kFile:write(value)
    end
    kFile:close()
end

-- 记录一条日志，不在终端输出
function kLog.w(str)
    if not kConfig.kAllowLog then
        return
    end

    while #kLogData > kConfig.kMaxLogLength do
        table.remove(kLogData, 1)
    end

    local currentTime = os.date("%Y-%m-%d %H:%M:%S")
    local log = string.format("[%s %s]\n", currentTime, str)
    table.insert(kLogData, log)
end

-- 记录一条日志，在终端输出
function kLog.p(str)
    print(str)
    if not kConfig.kAllowLog then
        return
    end

    kLog.w(str)
end

-- table转string
function kLog.formatTable(data, i)
    if data == nil then
        return "nil"
    elseif type(data) ~= "table" then
        return tostring(data)
    elseif next(data) == nil then
        return "nil"
    end

    local index
    if i == nil then
        index = 1
    else
        index = i + 1
    end

    local result = "{"
    for k, v in pairs(data) do
        local value = tostring(v)
        if type(v) == "table" then
            value = kLog.formatTable(v, index)
        end
        result = result .. "\n" .. string.rep(" ", index * 4) .. k .. " : " .. value .. ","
    end

    return result .. "\n" .. string.rep(" ", index * 4 - 4) .. "}"
end

return kLog

-------------------------------- public --------------------------------
