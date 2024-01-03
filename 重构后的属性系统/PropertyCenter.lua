PropertyCenter = {}

require("game/CharacterSystems/PropertySystem/PropertyEnum")
require("game/CharacterSystems/PropertySystem/PropertyCenterExpandable")
require("game/CharacterSystems/PropertySystem/PropertyCenter_MpRecoveryWhenSkillReleased")
require("game/CharacterSystems/PropertySystem/PropertyCenter_SkillReplacement")
require("game/CharacterSystems/PropertySystem/PropertyCenter_SkillStorage")
require("game/CharacterSystems/PropertySystem/PropertyCenter_SkillStorageRecoveryProbability")
require("game/CharacterSystems/PropertySystem/Formulas_Battle")
require("game/CharacterSystems/PropertySystem/Formulas_BattleWrapper")
require("game/CharacterSystems/PropertySystem/Formulas_Living")
require("game/CharacterSystems/RoleConfigExtensions")

function PropertyCenter.New()
    local propertyCenter = {};

    propertyCenter.Enum_Value = {}; -- 角色属性.
    propertyCenter.SkillTypeEnum_Storage = {} -- 指定技能类型对应的 储能上限. 
    propertyCenter.SkillTypeEnum_StorageRecoveryProbability = {} -- 指定技能类型对应的 储能回复概率.
    propertyCenter.SkillId_ReplaceSkillId = {} -- 指定技能Id 对应的 替换技能Id.
    propertyCenter.SkillTypeEnum_ProbabilityAndMpRecoveryPctList = {} -- 某类型的技能 对应的 概率 和 灵力回复百分比.

    return propertyCenter;
end

function PropertyCenter.AddProperty(role, propertyEnum, addend)
    -- Debug.
    if (role == nil) then
        luaError("角色 roleData 为空. ")
        return
    end
    if PropertyCenter.IsFinalProperty(propertyEnum) then
        luaError("不应该直接修改最终值: " .. tostring(propertyEnum))
        return
    end

    -- 更新子属性.
    local existingValue = PropertyCenter.GetValue(role, propertyEnum)
    local newValue = existingValue + addend
    local propertyCenter = role.data.PropertyCenter;
    propertyCenter.Enum_Value[propertyEnum] = newValue

    -- 更新主属性.
    local mainProperty = PropertyCenter.GetMainPropertyFromSub(propertyEnum)
    PropertyCenter.UpdateMainProperty(role, mainProperty)

    -- 更新依赖属性.
    PropertyCenter.UpdateAffectedProperties(role, mainProperty)

    -- 其他事件, 比如 特性更新之类的.
    PropertyCenter.OnAddProperty(role, propertyEnum, addend)
end

function PropertyCenter.IsFinalProperty(propertyEnum)
    return propertyEnum < 10000
end
function PropertyCenter.GetMainPropertyFromSub(propertyEnum)
    if PropertyCenter.IsFinalProperty(propertyEnum) then
        return propertyEnum
    end
    return math.floor(propertyEnum / 10)
end

function PropertyCenter.UpdateMainProperty(role, mainProperty)
    -- 如果是 一级属性, 那么使用通用的公式 : mainValue = (baseValue + addValue) * (1 + pctValue)
    if mainProperty < 2000 then
        local baseValue = PropertyCenter.GetValue(role, mainProperty * 10 + 1)
        local addValue = PropertyCenter.GetValue(role, mainProperty * 10 + 2)
        local pctValue = PropertyCenter.GetValue(role, mainProperty * 10 + 3)
        local mainValue = (baseValue + addValue) * (1 + pctValue)
        role.data.PropertyCenter.Enum_Value[mainProperty] = mainValue
        return
    end

    -- 如果是 二级属性, 各有各的公式.
    PropertyCenter.UpdateLv2MainProperty(role, mainProperty)
end

function PropertyCenter.UpdateAffectedProperties(role, mainProperty)
    local affectedProperties = PropertyCenter.MainProperty_AffectedProperties[mainProperty]
    if affectedProperties == nil then
        return
    end
    for _, affectedProperty in pairs(affectedProperties) do
        PropertyCenter.UpdateMainProperty(role, affectedProperty)
    end
end
