-- 通过getAllStacks一次性获取所有反应堆数据
-- 检测是否存在枯竭的燃料棒或无效的冷却单元
-- 如果存在，关闭所有核反应堆，并在延时1秒后开始替换操作
-- 通过getAllStacks获取缓存容器中所有数据
-- 找到有效的燃料棒和冷却单元位置，以及空槽位
-- 根据已有数据开始替换操作
-- 除去替换操作比较耗时，整个程序耗时操作就只有两次getAllStacks
-------------------------------- private --------------------------------
local kConfig = require("config")

local kAddFuel = require("add_fuel")

local kLog = require("log")

local kComponent = require("component")

local kSide = require("sides")

local kFront = kSide.front
local kBack = kSide.back
local kLeft = kSide.left
local kRight = kSide.right
local kUp = kSide.up
local kDown = kSide.down

-- 4联核反应堆容器
local kNuclearContainers = {kFront, kLeft, kBack, kRight}

-- 核反应堆物品信息
local kNuclearDatas

-- 缓存容器
local kCacheContainer = kDown

-- 缓存容器物品信息
local kCacheData

-- 转运器
local kTransposerId
local kTransposer

-- 红石io端口
local kRedstoneIOId
local kRedstoneIO

-- 全局反应堆停止函数
local kGlobalStopFunc

-- 是否为物品
local function validItem(item)
    return item and item["name"] ~= nil
end

-- 物品是否为有效冷却单元
local function validCoolantcell(item)
    return item and item["name"] == kConfig.kCoolantcellName and item["damage"] <= kConfig.kValidCoolantcellMaxDamage
end

-- 物品是否为有效燃料棒
local function validFuel(item)
    return item and item["name"] == kConfig.kFuelName
end

-- 刷新存储容器的数据 耗时操作
local function refreshCacheData()
    kCacheData = kTransposer.getAllStacks(kCacheContainer)
end

-- 刷新核反应堆的数据 耗时操作
local function refreshNuclearDatas()
    kNuclearDatas = {}
    for index, value in ipairs(kNuclearContainers) do
        local stacks = kTransposer.getAllStacks(value)
        table.insert(kNuclearDatas, {
            nuclear = value,
            stacks = stacks
        })
    end
end

-------------------------------- private --------------------------------

-------------------------------- 红石控制 --------------------------------

local function closeAllNuclear()
    kLog.w(string.format("关闭所有反应堆 ID = %s", kRedstoneIOId))
    kRedstoneIO.setOutput({
        [kLeft] = 0,
        [kRight] = 0,
        [kFront] = 0,
        [kBack] = 0,
        [kUp] = 0,
        [kDown] = 0
    })
end

local function openAllNuclear()
    kLog.w(string.format("开启所有反应堆 ID = %s", kRedstoneIOId))
    kRedstoneIO.setOutput({
        [kLeft] = 1,
        [kRight] = 1,
        [kFront] = 1,
        [kBack] = 1,
        [kUp] = 0,
        [kDown] = 0
    })
end

-------------------------------- 红石控制 --------------------------------

-------------------------------- 物品逻辑 --------------------------------

local function findEmptySlotDatas()
    kLog.w("找到缓存容器中的空槽位")
    local emptySlotDatas = {}
    for slot = 1, kCacheData.count() do
        if not validItem(kCacheData[slot]) then
            table.insert(emptySlotDatas, slot)
        end
    end
    kLog.w(string.format("emptySlotDatas = %s", kLog.formatTable(emptySlotDatas)))
    kLog.w("----------------------------------------------------------------")
    return emptySlotDatas
end

local function findInvalidItemDatas(validItemFunc, findSlots, type)
    kLog.w("找到反应堆中无效" .. type .. "位置")
    local invalidItemDatas = {}
    for stacksIndex, datas in ipairs(kNuclearDatas) do
        for slotIndex, slot in ipairs(findSlots) do
            if not validItemFunc(datas["stacks"][slot]) then
                local invalidItem = {
                    nuclear = datas["nuclear"],
                    slot = slot,
                    isEmpty = not validItem(datas["stacks"][slot])
                }
                table.insert(invalidItemDatas, invalidItem)
            end
        end
    end
    kLog.w(string.format("invalidItemDatas = %s", kLog.formatTable(invalidItemDatas)))
    kLog.w("----------------------------------------------------------------")
    return invalidItemDatas
end

local function findValidItemDatas(validItemFunc, type)
    kLog.w("找到缓存容器中有效的" .. type .. "位置")
    local validItemDatas = {}
    local totalSize = 0
    for slot = 1, kCacheData.count() do
        if validItemFunc(kCacheData[slot]) then
            table.insert(validItemDatas, {
                slot = slot,
                size = kCacheData[slot]["size"],
                name = kCacheData[slot]["name"]
            })
            totalSize = totalSize + kCacheData[slot]["size"]
        end
    end
    kLog.w(string.format("validItemDatas = %s", kLog.formatTable(validItemDatas)))
    kLog.w("----------------------------------------------------------------")
    return validItemDatas, totalSize
end

local function replaceInvalidItem(invalidItemDatas, validItemDatas, emptySlotDatas, type)
    kLog.w("替换无效" .. type)

    for i = #invalidItemDatas, 1, -1 do
        local invalidItemData = invalidItemDatas[i]
        if not invalidItemData["isEmpty"] then
            if #emptySlotDatas == 0 then
                break
            end

            -- 将核反应堆中的无效物品转移到缓存容器中
            if kTransposer.transferItem(invalidItemData["nuclear"], kCacheContainer, 1, invalidItemData["slot"],
                emptySlotDatas[#emptySlotDatas]) ~= 0 then
                table.remove(emptySlotDatas, #emptySlotDatas)
                invalidItemData["isEmpty"] = true
                kLog.p("卸载无效" .. type .. "成功")
            else
                kLog.p("卸载无效" .. type .. "失败")
                kLog.w(string.format("invalidItemData = %s", kLog.formatTable(invalidItemData)))
                kLog.w(string.format("emptySlotDatas = %s", kLog.formatTable(emptySlotDatas)))
                break
            end
        end

        if #validItemDatas == 0 then
            break
        end

        -- 将缓存容器中的物品转移到核反应堆中
        local validItemData = validItemDatas[#validItemDatas]
        if kTransposer.transferItem(kCacheContainer, invalidItemData["nuclear"], 1, validItemData["slot"],
            invalidItemData["slot"]) ~= 0 then
            validItemData["size"] = validItemData["size"] - 1
            if validItemData["size"] <= 0 then
                table.remove(validItemDatas, #validItemDatas)
            end
            table.remove(invalidItemDatas, #invalidItemDatas)
            kLog.p("转移" .. type .. "成功")
        else
            kLog.p("转移" .. type .. "失败")
            kLog.w(string.format("invalidItemData = %s", kLog.formatTable(invalidItemData)))
            kLog.w(string.format("validItemData = %s", kLog.formatTable(validItemData)))
            break
        end
    end
end

-------------------------------- 物品逻辑 --------------------------------

-------------------------------- 燃料棒逻辑 --------------------------------

local function installFuel()
    kLog.w("安装燃料棒")
    local invalidFuelDatas = findInvalidItemDatas(validFuel, kConfig.kFuelSlots, "燃料棒")
    if #invalidFuelDatas ~= 0 then
        kGlobalStopFunc()
        os.sleep(1)
    end

    -- 替换过程中，可能会出现缓存容器已满的情况，延时5秒，等待外部更新缓存容器，然后再继续替换程序
    while (1) do
        if #invalidFuelDatas == 0 then
            break
        end

        refreshCacheData()
        local validFuelDatas, validFuelSize = findValidItemDatas(validFuel, "燃料棒")
        local emptySlotDatas = findEmptySlotDatas()

        -- 缓存容器中燃料棒数目不足时，补充缓存容器中的燃料棒
        if validFuelSize <= 0 then
            kAddFuel.addFuel()
            goto continue
        end

        if #emptySlotDatas == 0 then
            kLog.p("缓存容器已满，请及时清理！！！")
            os.sleep(5)
        else
            replaceInvalidItem(invalidFuelDatas, validFuelDatas, emptySlotDatas, "燃料棒")
        end

        ::continue::
    end
end

-------------------------------- 燃料棒逻辑 --------------------------------

-------------------------------- 冷却单元逻辑 --------------------------------

local function installCoolantcell()
    kLog.w("安装冷却单元")
    local invalidCoolantcellDatas = findInvalidItemDatas(validCoolantcell, kConfig.kCoolantcellSlots, "冷却单元")
    if #invalidCoolantcellDatas ~= 0 then
        kGlobalStopFunc()
        os.sleep(1)
    end

    -- 替换过程中，可能会出现冷却单元不足或缓存容器已满的情况，延时5秒，等待外部更新缓存容器，然后再继续替换程序
    while (1) do
        if #invalidCoolantcellDatas == 0 then
            break
        end

        refreshCacheData()
        local validCoolantcellDatas = findValidItemDatas(validCoolantcell, "冷却单元")
        local emptySlotDatas = findEmptySlotDatas()

        if #validCoolantcellDatas == 0 then
            kLog.p("无可用冷却单元，请及时补充！！！")
            os.sleep(5)
        elseif #emptySlotDatas == 0 then
            kLog.p("缓存容器已满，请及时清理！！！")
            os.sleep(5)
        else
            replaceInvalidItem(invalidCoolantcellDatas, validCoolantcellDatas, emptySlotDatas, "冷却单元")
        end
    end
end

-------------------------------- 冷却单元逻辑 --------------------------------

-------------------------------- public --------------------------------

local kNuclear = {}

-- 初始化程序
function kNuclear.init(config, globalStopFunc)
    kTransposerId = config.kTransposerId
    kTransposer = kComponent.proxy(kTransposerId)

    kRedstoneIOId = config.kRedstoneIOId
    kRedstoneIO = kComponent.proxy(kRedstoneIOId)

    kGlobalStopFunc = globalStopFunc

    kNuclear.closeAllNuclear()
end

-- 执行程序
function kNuclear.run()
    kLog.w("\n\n\n\n")
    kLog.w("================================================================")
    kLog.w(string.format("核反应堆执行程序开始 ID = %s", kTransposerId))

    refreshNuclearDatas()
    installCoolantcell()
    installFuel()

    kLog.w(string.format("核反应堆执行程序结束 ID = %s", kTransposerId))
    kLog.w("================================================================")
    kLog.w("\n\n\n\n")
end

-- 关闭所有反应堆
function kNuclear.closeAllNuclear()
    closeAllNuclear()
end

-- 开启所有反应堆
function kNuclear.openAllNuclear()
    openAllNuclear()
end

return kNuclear

-------------------------------- public --------------------------------
