-------------------------------- private --------------------------------
local kConfig = require("config")

local kLog = require("log")

local kComponent = require("component")

local kSide = require("sides")

-- 缓存容器最多存放多少燃料棒
local kCacheContainerFuelMaxCount = 128

-- 转运器
local kTransposer = kComponent.proxy(kConfig.kAddFuelTransposerId)

-- 缓存容器（与反应堆交互）
local kCacheContainer = kSide.front

-- 存储容器（存储大量燃料棒）
local kStorageContainer = kSide.up

-- 是否为物品
local function validItem(item)
    return item and item["name"] ~= nil
end

-- 物品是否为有效燃料棒
local function validFuel(item)
    return item and item["name"] == kConfig.kFuelName
end

local function min(array)
    local min_val = array[1]
    for i = 2, #array do
        if array[i] < min_val then
            min_val = array[i]
        end
    end
    return min_val
end

local function max(a, b)
    return (a > b) and a or b
end

-------------------------------- private --------------------------------

-------------------------------- public --------------------------------

local kAddFuel = {}

function kAddFuel.addFuel()
    kLog.p("补充燃料棒")
    -- 找到缓存箱子中可补充燃料棒的槽位
    local cacheDatas = kTransposer.getAllStacks(kCacheContainer)
    local totalSize_cache = 0
    local validFuelDatas_cache = {}
    for slot = 1, cacheDatas.count() do
        -- 找到已有燃料棒的槽位
        if validFuel(cacheDatas[slot]) then
            if cacheDatas[slot]["size"] < 64 then
                table.insert(validFuelDatas_cache, {
                    slot = slot,
                    size = cacheDatas[slot]["size"]
                })
            end
            totalSize_cache = totalSize_cache + cacheDatas[slot]["size"]
        end
    end
    for slot = 1, cacheDatas.count() do
        -- 找到空槽位
        if not validItem(cacheDatas[slot]) then
            table.insert(validFuelDatas_cache, {
                slot = slot,
                size = 0
            })
        end
    end
    kLog.w(string.format("totalSize_cache = %s", tostring(totalSize_cache)))
    kLog.w(string.format("validFuelDatas_cache = %s", kLog.formatTable(validFuelDatas_cache)))

    -- 找到存储箱子中有效燃料棒
    local storageDatas = kTransposer.getAllStacks(kStorageContainer)
    local totalSize_storage = 0
    local validFuelDatas_storage = {}
    for slot = 1, storageDatas.count() do
        if validFuel(storageDatas[slot]) then
            table.insert(validFuelDatas_storage, {
                slot = slot,
                size = storageDatas[slot]["size"]
            })
            totalSize_storage = totalSize_storage + storageDatas[slot]["size"]
        end
    end
    kLog.w(string.format("totalSize_storage = %s", tostring(totalSize_storage)))
    kLog.w(string.format("validFuelDatas_storage = %s", kLog.formatTable(validFuelDatas_storage)))

    if totalSize_storage == 0 then
        error("燃料棒已用完！！！")
    end

    -- 向已存在燃料棒的槽位补充燃料棒
    for cIndex, cValue in ipairs(validFuelDatas_cache) do
        if totalSize_cache == kCacheContainerFuelMaxCount then
            break
        end

        for sIndex, sValue in ipairs(validFuelDatas_storage) do
            if totalSize_cache == kCacheContainerFuelMaxCount or cValue["size"] == 64 then
                break
            end

            if sValue["size"] == 0 then
                goto continue
            end

            local addCount = min({kCacheContainerFuelMaxCount - totalSize_cache, sValue["size"], 64 - cValue["size"]})
            if kTransposer.transferItem(kStorageContainer, kCacheContainer, addCount, sValue["slot"], cValue["slot"]) ~=
                0 then
                sValue["size"] = sValue["size"] - addCount
                cValue["size"] = cValue["size"] + addCount
                totalSize_cache = totalSize_cache + addCount
            else
                kLog.w("补充燃料棒失败")
                kLog.w(string.format("validFuelDatas_cache = %s\nvalidFuelDatas_storage = %s",
                    kLog.formatTable(validFuelDatas_cache), kLog.formatTable(validFuelDatas_storage)))
                kLog.w(string.format("cValue = %s\nsValue = %s", kLog.formatTable(cValue), kLog.formatTable(sValue)))
                break
            end

            ::continue::
        end
    end
end

return kAddFuel

-------------------------------- public --------------------------------
