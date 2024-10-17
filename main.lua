local kTerm = require("term")

local kSide = require("sides")

local kLog = require("log")

local kConfig = require("config")

local kComponent = require("component")

local kNuclearStartTime

local kNuclearEndTime

local kIsClose = false

local kLastCloseTime

local kTotalCloseTime = 0

-- 核电反应控制程序
local kNuclears

-- 主控制程序红石io端口
local kControlRedstoneIO = kComponent.proxy(kConfig.kControlRedstoneIOId)

-- 自动红石控制信号（可用于对兰波顿电池监控）
local kAutoControl = kSide.left

-- 手动红石控制信号（手动结束程序）
local kManualControl = kSide.right

local function closeAllNuclear()
    if not kIsClose then
        kLastCloseTime = os.time()
        kIsClose = true
    end

    for index, value in ipairs(kNuclears) do
        value.closeAllNuclear()
    end
end

local function openAllNuclear()
    for index, value in ipairs(kNuclears) do
        value.openAllNuclear()
    end

    if kIsClose then
        kTotalCloseTime = kTotalCloseTime + os.time() - kLastCloseTime
        kIsClose = false
    end
end

local function dispose()
    closeAllNuclear()

    kNuclearEndTime = os.time()

    kLog.w(string.format("程序开始时间: %s 程序结束时间: %s", tostring(kNuclearStartTime),
        tostring(kNuclearEndTime)))
    kLog.p(string.format("程序运行时长: %s秒", tostring((kNuclearEndTime - kNuclearStartTime) / 60)))
    kLog.p(string.format("核电关闭时长: %s", tostring(kTotalCloseTime / 60)))

    -- 关闭日志系统
    kLog.dispose()
end

local function init()
    -- 清空显示器
    kTerm.clear()

    -- 初始化日志系统
    kLog.init()

    -- 初始化核电控制程序
    kNuclears = {}
    for index, value in ipairs(kConfig.kNuclear) do
        local nuclear = dofile("nuclear.lua")
        nuclear.init(value, closeAllNuclear)
        table.insert(kNuclears, nuclear)
    end
    closeAllNuclear()

    kNuclearStartTime = os.time()
end

local function main()
    init()
    while (1) do
        if kControlRedstoneIO.getInput(kManualControl) == 0 then
            break
        end

        if kControlRedstoneIO.getInput(kAutoControl) >= 10 then
            closeAllNuclear()
            kLog.p(string.format("电池电量库存已满，进入待机，待机时长%s秒", tostring(kConfig.kWaitTime)))
            os.sleep(kConfig.kWaitTime)
            kLog.p("待机结束，开启核反应堆！！！")
        end

        -- 核电检查程序启动
        for index, value in ipairs(kNuclears) do
            value.run()
        end

        openAllNuclear()
    end
    dispose()
end

local status, err = pcall(main, nil)
if not status then
    local errDomain
    if type(err) == "table" then
        errDomain = kLog.formatTable(err)
    else
        errDomain = err
    end
    kLog.p(string.format("程序异常：%s", errDomain))
    dispose()
end
os.exit()
