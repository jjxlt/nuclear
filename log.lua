-------------------------------- private --------------------------------
local kConfig = require("config")

local kLogData

local kLastTimestamp

local kFilePath = "debug_log"

-- 文件名种子，保证生成的文件名不会重复
local kFileNameSeed

local kLog = {}

-- 是否是生产环境(openOS)
local function isPro()
    local handle = io.popen("uname")
    local result = handle:read("*l")
    handle:close()
    -- 这里判断的是macOS
    return result ~= "Darwin"
end

local function fileNamesInDirOpenOS(directory)
    error("未实现 \"fileNamesInDirOpenOS方法\" ")
end

local function fileNamesInDirMacOS(directory)
    local handle = io.popen('ls -1 "'..directory..'" 2>/dev/null')
    local files = {}
    if handle then
        for line in handle:lines() do
            table.insert(files, line)
        end
        handle:close()
    end
    return files
end

-- 获取目录中所有文件夹名字
local function fileNamesInDir(directory)
    if isPro() then
        return fileNamesInDirOpenOS(directory)
    else
        return fileNamesInDirMacOS(directory)
    end
end

-- 删除最早的日志文件
local function deleteOldestFile()
    local fileNames = fileNamesInDir(kFilePath)
    local needDeleteCount = #fileNames - kConfig.kMaxLogFileCount
    local needDeleteFiles = {}
    -- 找到需要删除的日志文件
    for i = 1, #fileNames do
        local time, seed = fileNames[i]:match("_(%d+)_([%d]+)%.log")
        local item = {
            time = tonumber(time),
            seed = tonumber(seed),
            fileName = fileNames[i]
        }
        if #needDeleteFiles < needDeleteCount then
            table.insert(needDeleteFiles, item)
        else
            local tItem = item
            for j = 1, #needDeleteFiles do
                if tItem.time < needDeleteFiles[j].time then
                    local pItem = tItem
                    tItem = needDeleteFiles[j]
                    needDeleteFiles[j] = pItem
                elseif tItem.time == needDeleteFiles[j].time and tItem.seed < needDeleteFiles[j].seed then
                    local pItem = tItem
                    tItem = needDeleteFiles[j]
                    needDeleteFiles[j] = pItem
                end
            end
        end
    end

    -- 删除之
    for i = 1, #needDeleteFiles do
        local ok = os.remove(string.format("%s/%s", kFilePath, needDeleteFiles[i].fileName))
        if not ok then
            error("删除文件出错")
        end
    end
end
-------------------------------- private --------------------------------

-------------------------------- public --------------------------------
-- 初始化
function kLog.init()
    if not kConfig.kAllowLog then
        return
    end

    kLogData = {}
    kFileNameSeed = 0
end

-- 结束
function kLog.dispose()
    if not kConfig.kAllowLog then
        return
    end
    kLog.writeToFile()
end

-- 记录一条日志，不在终端输出
function kLog.w(str)
    if not kConfig.kAllowLog then
        return
    end

    local currentTime = os.date("%Y-%m-%d %H:%M:%S")
    local log = string.format("[%s %s]\n", currentTime, str)
    table.insert(kLogData, log)
    kLog.writeToFile()
end

-- 记录一条日志，在终端输出
function kLog.p(str)
    print(str)
    kLog.w(str)
end

function kLog.writeToFile()
    if #kLogData < kConfig.kMaxLogLength then
        return
    end

    if not kLog.isDirectoryExists(kFilePath) then
        kLog.createDirectory(kFilePath)
    end

    local fileName = kLog.logFileName()
    local file = io.open(string.format("%s/%s", kFilePath, fileName), "w")
    if file == nil then
        error("日志文件初始化失败")
    end

    -- 将内存中的日志写入文件
    for index, value in ipairs(kLogData) do
        file:write(value)
    end
    file:close()
    kLogData = {}

    deleteOldestFile()
end

-- OpenComputer中的openOS文件系统API与通用的windows或unix不大相同，具体API见：
-- https://ocdoc.cil.li/api:filesystem:zh
function kLog.createDirectory(path)
    local ok
    if isPro() then
        ok = filesystem.makeDirectory(path)
    else
        ok = os.execute(string.format("mkdir -p %s", path))
    end

    if not ok then
        error("新建目录失败")
    end
end

function kLog.isDirectoryExists(path)
    if isPro() then
        return filesystem.exists(path)
    else
        local ok, err, code = os.rename(path, path)
        return ok or code ~= 2
    end
end

-- 生成日志文件名
function kLog.logFileName()
    local timestamp = tostring(os.time())
    kFileNameSeed = kFileNameSeed + 1
    return string.format("debug_%s_%d.log", timestamp, kFileNameSeed)
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

-------------------------------- public --------------------------------

return kLog