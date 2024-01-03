require("game/CharacterSystems/CharacterTalentEffectSystem/TalentEffectProcessor")
require("game/CharacterSystems/CharacterTraitSystem/Trait")

CharacterTraitCenter = {
    IsLogging = false,
}

function CharacterTraitCenter.Initialize(role)
    -- Debug
    if (role == nil) then
        luaError("角色 roleData 为空.")
        return
    end

    role.data.traits = {}
    role.data.hasDurationTrait = false
end

-- 简单的添加新特性逻辑
function CharacterTraitCenter.AddTraitBase(role, configId)
    local traitInstance = Trait.New(configId)
    role.data.traits[configId] = traitInstance

    -- 如果该特性有持续时间，则设置 hasDurationTrait 为 true
    if traitInstance.remainingTime and traitInstance.remainingTime > 0 then
        role.data.hasDurationTrait = true
    end

    -- 如果存在天赋效果
    if traitInstance.talentEffect then
        if TalentEffectConditionGroup.IsSatisfied(role, traitInstance.talentEffect.conditionGroup) then
            TalentEffectConditionGroup.Activate(traitInstance.talentEffect.conditionGroup)
            TalentEffectProcessor.ApplyTalentEffect(role, t_characteristic.config[traitInstance.configId].talentEffect, nil, traitInstance.talentEffect.conditionGroup)
        end
    end
end

-- 简单的移除特性逻辑
function CharacterTraitCenter.RemoveTraitBase(role, configId)
    local traitInstance = role.data.traits[configId]
    role.data.traits[configId] = nil

    -- 当特性被移除时，遍历所有的特性来检查是否还有持续时间的特性
    local foundDurationTrait = false
    for _, trait in pairs(role.data.traits) do
        if trait.remainingTime and trait.remainingTime > 0 then
            foundDurationTrait = true
            break
        end
    end
    role.data.hasDurationTrait = foundDurationTrait

    if traitInstance and traitInstance.talentEffect and traitInstance.talentEffect.conditionGroup.isActive then
        TalentEffectProcessor.RemoveTalentEffect(role, t_characteristic.config[traitInstance.configId].talentEffect)
    end
end

-- 添加新特性
function CharacterTraitCenter.AddTrait(role, configIdToAdd)
    local configToAdd = t_characteristic.config[configIdToAdd]
    if (CharacterTraitCenter.IsLogging) and (configToAdd == nil) then
        luaError("特性表 t_characteristic 中未找到 该特性: " .. configIdToAdd)
        return
    end

    -- 1. 首先看看, 目前的特性中, 有没有同 Id 的特性. 如果有, 那么就更新持续时间. 
    if role.data.traits[configIdToAdd] ~= nil then
        role.data.traits[configIdToAdd].remainingTime = configToAdd.duration
        role.isDataDirty = true
        if (CharacterTraitCenter.IsLogging) then
            luaLog("重复特性刷新持续时间 " .. configMgr:getLanguage(configToAdd.name))
        end
        return
    end

    -- 2. 再看有没有替换组Id 为 0 的, 表示自己一组. 直接添加.
    if configToAdd.groupIdForReplacement == 0 then
        CharacterTraitCenter.AddTraitBase(role, configIdToAdd)
        role.isDataDirty = true
        if (CharacterTraitCenter.IsLogging) then
            luaLog("添加了特性" .. configMgr:getLanguage(configToAdd.name))
        end
        return
    end

    -- 3. 其次, 再看看目前的特性有, 有没有同 替换组Id 的特性.
    -- 如果有, 并且 数值较低的, 那么就替换成新的. 如果数值较高, 就不获得低级特性. 
    for id, _ in pairs(role.data.traits) do
        local existingConfig = t_characteristic.config[id]
        if existingConfig and existingConfig.groupIdForReplacement == configToAdd.groupIdForReplacement then
            if existingConfig.level < configToAdd.level then
                CharacterTraitCenter.RemoveTraitBase(role, id)
                CharacterTraitCenter.AddTraitBase(role, configIdToAdd)
                role.isDataDirty = true
                if (CharacterTraitCenter.IsLogging) then
                    luaLog("替换特性: " .. configMgr:getLanguage(configToAdd.name) .. " 替换掉 " .. configMgr:getLanguage(existingConfig.name))
                end
                return
            else
                return
            end
        end
    end

    -- 3. 简单的添加新特性
    CharacterTraitCenter.AddTraitBase(role, configIdToAdd)
    role.isDataDirty = true

    if (CharacterTraitCenter.IsLogging) then
        luaLog("添加了特性" .. configMgr:getLanguage(configToAdd.name))
    end
end

-- 减少特性的持续时间, 单位是 时辰. 
function CharacterTraitCenter.DecreaseTraitDuration(role, delta)
    --记录下来添加特性需要的参数
    local toAdd = {}
    --1. 减少持续时间. 如果该特性对应的特性配置是无限时间, 则忽略. 反之, 则减少其持续时间. 
    for configId, trait in pairs(role.data.traits) do
        local config = t_characteristic.config[configId]
        if config.duration ~= 0 then
            trait.remainingTime = trait.remainingTime - delta
        end
    end
    --2. 转变特性. 
    --开始遍历现在的特性, 如果该特性的剩余持续时间 > 0, 不管它, 如果持续时间 <=0, 移除该特性, 并记录要转变的特性. 
    for configId, trait in pairs(role.data.traits) do
        if trait.remainingTime and trait.remainingTime <= 0 then
            CharacterTraitCenter.RemoveTraitBase(role, configId)
            local transformToId = t_characteristic.config[configId].transformToId
            if transformToId and transformToId ~= 0 then
                table.insert(toAdd, transformToId)
            end
        end
    end
    --3. 遍历上面记录的需要添加的新特性的配置, 添加对应特性. 
    for _, configId in pairs(toAdd) do
        CharacterTraitCenter.AddTrait(role, configId)
    end

    role.isDataDirty = true
end

-- 属性系统对于特性系统的更新. 
function CharacterTraitCenter.UpdateTraitCondition(role)
    if (role.data.traits == nil) then
        return
    end

    for _, trait in pairs(role.data.traits) do
        if trait.talentEffect and trait.talentEffect.conditionGroup then
            local conditionGroup = trait.talentEffect.conditionGroup
            -- 检查条件组是否满足
            if TalentEffectConditionGroup.IsSatisfied(role, conditionGroup) then
                if not conditionGroup.isActive then
                    TalentEffectConditionGroup.Activate(conditionGroup)
                    role.isDataDirty = true
                    TalentEffectProcessor.ApplyTalentEffect(role, t_characteristic.config[trait.configId].talentEffect, conditionGroup)
                end
            else
                if conditionGroup.isActive then
                    TalentEffectConditionGroup.Deactivate(conditionGroup)
                    role.isDataDirty = true
                    TalentEffectProcessor.RemoveTalentEffect(role, t_characteristic.config[trait.configId].talentEffect)
                end
            end
        end
    end
end

-- 获得特性剩余时间
function CharacterTraitCenter.GetTraitRemainingTime(role, id)
    if (role.data.traits == nil) then
        return nil
    end

    for cfgId, trait in pairs(role.data.traits) do
        if id == cfgId then
            return trait.remainingTime
        end
    end
    return nil
end