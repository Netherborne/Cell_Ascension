local _, Cell = ...
local L = Cell.L
local F = Cell.funcs

-------------------------------------------------
-- click-castings
-------------------------------------------------
local defaultSpells = {
    ["DEATHKNIGHT"] = {
        ["common"] = {
            61999, -- 复活盟友
            49893, -- 凋零缠绕
            "49016T", -- 邪恶狂热
        },
    },

    ["DRUID"] = {
        ["common"] = {
            -- Balance
            29166, -- 激活
            26992, -- 荆棘术
            -- Restoration
            774, -- 回春术
            8936, -- 愈合
            5185, -- 治疗之触
            33763, -- 生命绽放
            50464, -- 滋养
            "18562T", -- 迅捷治愈
            "48438T", -- 野性成长
            -- dispel
            8946, -- 消毒术
            2893, -- 驱毒术
            2782, -- 解除诅咒
            -- resurrect
            20484, -- 复生
            50769, -- 起死回生
            -- buff
            1126, -- 野性印记
            21849, -- 野性赐福
        },
    },

    ["HUNTER"] = {
        ["common"] = {
            34477, -- 误导
            53271, -- 主人的召唤
        },
    },

    ["MAGE"] = {
        ["common"] = {
            -- dispel
            475, -- 解除诅咒
            -- buff
            130, -- 缓落术
            "54646T", -- 专注魔法
            1008, -- 魔法增效
            604, -- 魔法抑制
            1459, -- 奥术智慧
            23028, -- 奥术光辉
        },
    },

    ["PALADIN"] = {
        ["common"] = {
            -- Holy
            635, -- 圣光术
            19750, -- 圣光闪现
            633, -- 圣疗术
            53601, -- 圣洁护盾
            "20473T", -- 神圣震击
            "53563T", -- 圣光道标
            -- Protection
            31789, -- 正义防御
            1044, -- 自由之手
            1038, -- 拯救之手
            6940, -- 牺牲之手
            1022, -- 保护之手
            -- dispel
            4987, -- 清洁术
            1152, -- 纯净术
            -- resurrect
            7328, -- 救赎
            19752, -- 神圣干涉
            -- buff
            20217, -- 王者祝福
            25898, -- 强效王者祝福
            19740, -- 力量祝福
            25782, -- 强效力量祝福
            19742, -- 智慧祝福
            25894, -- 强效智慧祝福
            "20911T", -- 庇护祝福
            "25899T", -- 强效庇护祝福
        },
    },

    ["PRIEST"] = {
        ["common"] = {
            -- Discipline
            17, -- Power Word: Shield Rank 1
            "47540T", -- Penance Rank 1
            -- Holy
            2061, -- Flash Heal Rank 1
            2050, -- Greater Heal Rank 1
            139, -- Renew Rank 1
            33076, -- Prayer of Mending Rank 1
            596, -- Prayer of Healing Rank 1
            "34861T", -- Circle of Healing Rank 1
            "47788T", -- Guardian Spirit 
            -- dispel
            527, -- Dispel Magic Rank 1
            552, -- Abolish Disease 
            528, -- Cure Disease 
            -- resurrect
            2006, -- 复活术
            -- buff
            "10060T", -- Power Infusion 
            "33206T", -- Pain Suppression 
            1706, -- Levitate 
            6346, -- Fear Ward 
            1243, -- Power Word: Fortitude Rank 1
            21562, -- Prayer of Fortitude Rank 1
            14752, -- Divine Spirit Rank 1
            27681, -- Prayer of Spirit Rank 1
            976, -- Shadow Protection Rank 1
            27683, -- Prayer of Shadow Protection Rank 1
            -- other
            2096, -- Mind Vision Rank 1
        },
    },

    ["ROGUE"] = {
        ["common"] = {
            57934, -- 嫁祸诀窍
        },
    },

    ["SHAMAN"] = {
        ["common"] = {
            -- Restoration
            8004, -- 次级治疗波
            331, -- 治疗波
            1064, -- 治疗链
            "974T", -- "大地之盾"
            "61295T", -- 激流
            -- dispel
            "51886T", -- 净化灵魂
            526, -- 驱毒术
            -- resurrect
            2008, -- 先祖之魂
            -- buff
            546, -- 水上行走
            131, -- 水下呼吸
        },
    },

    ["WARLOCK"] = {
        ["common"] = {
            -- buff
            132, -- 侦测隐形
            5697, -- 魔息术
        },
    },

    ["WARRIOR"] = {
        ["common"] = {
            3411, -- 援护
            "50720T", -- 警戒
        },
    },
	["HERO"] = {
        ["common"] = {
         
        },
    },
	["PROPHET"] = {
        ["common"] = {
         
        },
    },
	["FLESHWARDEN"] = {
        ["common"] = {
         
        },
    },
	["RANGER"] = {
        ["common"] = {
         
        },
    },
	["PYROMANCER"] = {
        ["common"] = {
         
        },
    },
	["WITCHHUNTER"] = {
        ["common"] = {
         
        },
    },
	["STARCALLER"] = {
        ["common"] = {
         
        },
    },
	["SPIRITMAGE"] = {
        ["common"] = {
         
        },
    },
	["CULTIST"] = {
        ["common"] = {
         
        },
    },
	["TINKER"] = {
        ["common"] = {
         
        },
    },
	["SUNCLERIC"] = {
        ["common"] = {
         
        },
    },
	["NECROMANCER"] = {
        ["common"] = {
         
        },
    },
	["WILDWALKER"] = {
        ["common"] = {
         
        },
    },
	["CHRONOMANCER"] = {
        ["common"] = {
         
        },
    },
	["STORMBRINGER"] = {
        ["common"] = {
         
        },
    },
	["SONOFARUGAL"] = {
        ["common"] = {
         
        },
    },
	["REAPER"] = {
        ["common"] = {
         
        },
    },
	["GUARDIAN"] = {
        ["common"] = {
         
        },
    },
	["MONK"] = {
        ["common"] = {
         
        },
    },
	["BARBARIAN"] = {
        ["common"] = {
         
        },
    },
	["WITCHDOCTOR"] = {
        ["common"] = {
         806240, -- Hexbreak
         801661, -- Potion Toss
         801696, -- Spirit in a Bottle
         801670, -- Loa's Brew
         804049, -- Allcure Elixir
         707671, -- Power Wuju
         560294, -- Spirit Wuju
        },
    },
	["DEMONHUNTER"] = {
        ["common"] = {
         
        },
    },
}

function F.GetClickCastingSpellList(class)
    local spells = defaultSpells[class]["common"] and F.Copy(defaultSpells[class]["common"]) or {}

    -- fill data
    for i, v in pairs(spells) do
        local spellId, spellType

        if type(v) == "number" then
            spellId = v
        else -- string
            spellId, spellType = strmatch(v, "(%d+)(%a)")
            spellId = tonumber(spellId)
            spellType = L[spellType]
        end

        local name, icon = F.GetSpellInfo(spellId)
        spells[i] = {icon, name, spellType, spellId, F.GetMaxSpellRank(spellId)}
    end

    -- texplore(spells)
    return spells
end

-------------------------------------------------
-- resurrections
-------------------------------------------------
local resurrections_for_dead = {
    -- DEATHKNIGHT
    61999, -- 复活盟友

    -- DRUID
    20484, -- 复生
    50769, -- 起死回生

    -- PALADIN
    7328, -- 救赎

    -- PRIEST
    2006, -- 复活术

    -- SHAMAN
    2008, -- 先祖之魂
}

do
    local temp = {}
    for _, id in pairs(resurrections_for_dead) do
        if F.GetSpellInfo(id) then
            temp[F.GetSpellInfo(id)] = true
        end
    end
    resurrections_for_dead = temp
end

function F.IsSoulstone()
    return false
end

function F.IsResurrectionForDead(spellId)
    return resurrections_for_dead[spellId]
end

local resurrection_click_castings = {
    ["DEATHKNIGHT"] = {
        {"type-altR", "spell", 61999},
    },
    ["DRUID"] = {
        {"type-altR", "spell", 20484},
        {"type-shiftR", "spell", 50769},
    },
    ["PALADIN"] = {
        {"type-shiftR", "spell", 7328},
    },
    ["PRIEST"] = {
        {"type-shiftR", "spell", 2006},
    },
    ["SHAMAN"] = {
        {"type-shiftR", "spell", 2008},
    },
}

function F.GetResurrectionClickCastings(class)
    return resurrection_click_castings[class] or {}
end

-------------------------------------------------
-- smart resurrection
-------------------------------------------------
local normalResurrection = {
    ["DRUID"] = 50769,
    ["PALADIN"] = 7328,
    ["PRIEST"] = 2006,
    ["SHAMAN"] = 2008,
    ["WITCHDOCTOR"] = 801796
}

do
    for class, spell in pairs(normalResurrection) do
        normalResurrection[class] = F.GetSpellInfo(spell)
    end
end

function F.GetNormalResurrection(class)
    return normalResurrection[class]
end

local combatResurrection = {
    ["DEATHKNIGHT"] = 61999,
    ["DRUID"] = 20484,
}

do
    for class, spell in pairs(combatResurrection) do
        combatResurrection[class] = F.GetSpellInfo(spell)
    end
end

function F.GetCombatResurrection(class)
    return combatResurrection[class]
end