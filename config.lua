local kConfig = {
    -- 是否开启日志
    -- 关闭日志，仅仅是日志不保存到文件，但仍然在终端输出
    kAllowLog = true,

    -- 日志文件数量
    kMaxLogFileCount = 20,

    -- 每个日志文件的日志数量
    kMaxLogLength = 1000,

    -- 外部电池容量充满时，待机时长（秒）
    kWaitTime = 1800,

    -- 冷却单元
    kCoolantcellName = "gregtech:gt.1080k_Space_Coolantcell",

    -- 燃料棒
    kFuelName = "gregtech:gt.reactorMOXQuad",

    -- 枯竭燃料棒
    kDepletedFuelName = "IC2:reactorMOXQuaddepleted",

    -- 有效冷却单元的最大耐久
    kValidCoolantcellMaxDamage = 90,

    -- 冷却单元摆法
    kCoolantcellSlots = {1, 5, 8, 12, 17, 19, 24, 31, 36, 38, 43, 47, 50, 54},

    -- 燃料棒摆法
    kFuelSlots = {2, 3, 4, 6, 7, 9, 10, 11, 13, 14, 15, 16, 18, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 32, 33, 34, 35,
                  37, 39, 40, 41, 42, 44, 45, 46, 48, 49, 51, 52, 53},

    -- 核反应堆配置
    kNuclear = {{
        kTransposerId = "d1fc867e-a0aa-4cc4-85b7-5f45b7550ee5",
        kRedstoneIOId = "e866d88b-0d98-45f9-b230-48311f3936f6"
    }, {
        kTransposerId = "e122555b-5f7f-4635-8eee-39b7f47f0f80",
        kRedstoneIOId = "9925ffea-e822-4f31-ba65-d910a34e52d0"
    }, {
        kTransposerId = "6bae2755-21d0-4d31-9cfc-71e4b981ee0d",
        kRedstoneIOId = "2b177460-98c3-449a-8924-244a95f78d2f"
    }, {
        kTransposerId = "6d98ee75-c61b-4fa5-89ee-e6a799c30ee3",
        kRedstoneIOId = "6958a166-a24c-4767-b361-2ff0ed461e7e"
    }},

    -- 主控制程序红石io端口uuid
    kControlRedstoneIOId = "958389e5-6b65-4c17-8374-fe42ca6c0df5",

    -- 补充燃料棒转运器uuid
    kAddFuelTransposerId = "3c0c8aaf-5f98-47b3-856c-c9b1a7bfecd3"
}

return kConfig
