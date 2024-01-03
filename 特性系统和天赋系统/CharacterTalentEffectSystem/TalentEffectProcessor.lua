require("game/CharacterSystems/CharacterTalentEffectSystem/TalentEffectResultEnum")

TalentEffectProcessor = {}

function TalentEffectProcessor.ApplyTalentEffect(role, talentResultGroupConfig, conditionGroup)
    for _, talentResultConfig in pairs(talentResultGroupConfig) do
        local talentEffectResultEnum = talentResultConfig[1]

        if talentEffectResultEnum == TalentEffectResultEnum.ModifyCharacterProperty then
            local propertyEnum, effectValue = talentResultConfig[2], talentResultConfig[3]
            PropertyCenter.AddProperty(role, propertyEnum, effectValue)
            --luaLog("天赋效果激活" .. tostring(propertyEnum) .. " +" .. effectValue)
        elseif talentEffectResultEnum == TalentEffectResultEnum.ModifyCharacterStateProperty then
            local stateType, value = talentResultConfig[2], talentResultConfig[3]
            role:roleStateChange(value > 0, stateType, math.abs(value))
            --luaLog("天赋效果激活 - 状态属性 (饱食度等): " .. tostring(stateType) .. " " .. (value > 0 and "+" or "-") .. math.abs(value))
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddBuff then
            local skillBuffCfg = { { talentResultConfig[2], talentResultConfig[3], 1 } }  -- t_skillBuff Id  /   持续时间秒   /   是否释放给自己 
            local target = _BattleTargetEnum.Friendly -- 目标类型
            -- BaiyiTODO这里需要一个方法, 直接通过 role 获取 owner, 用于添加 Buff. 
            local owner = nil;
            if (owner == nil) then
                luaError("需要一个方法, 直接通过 role 获取 owner, 用于添加 Buff. ");
                return ;
            end
            local params = {
                skillId = nil,
                attack = owner,
            }
            owner.buffControl:analysisBuff(skillBuffCfg, target, params)
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddItem then
            local itemId = talentResultConfig[2]
            local itemCount = talentResultConfig[3]
            role:addConsumable(itemId, itemCount)
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddEquipment then
            local equipmentId = talentResultConfig[2]
            role:addBagEquipment(configMgr:getEquipmentById(equipmentId))
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddJiYi then
            local jiYiId = talentResultConfig[2]
            local levelAddend = talentResultConfig[3]
            role:upTechniqueLv(jiYiId, levelAddend)
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddStorageForSkillType then
            local skillTypeEnum, addend = talentResultConfig[2], talentResultConfig[3]
            PropertyCenter.AddStorageForSkillType(role, skillTypeEnum, addend)
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddStorageRecoverPctForSkillType then
            local skillTypeEnum, addend = talentResultConfig[2], talentResultConfig[3]
            PropertyCenter.AddStorageRecoveryProbability(role, skillTypeEnum, addend)
        elseif talentEffectResultEnum == TalentEffectResultEnum.ReplaceSkillId then
            local skillId, replaceSkillId = talentResultConfig[2], talentResultConfig[3]
            PropertyCenter.AddReplaceSkillId(role, skillId, replaceSkillId)
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddProbabilityAndMpRecoverPctForSkillType then
            local skillTypeEnum, probability, mpRecoverPct = talentResultConfig[2], talentResultConfig[3], talentResultConfig[4]
            PropertyCenter.AddProbabilityAndMpRecoveryPct(role, skillTypeEnum, probability, mpRecoverPct)
        end

        -- 如果有其他类型的天赋效果结果，可以在此处进行扩展
    end

    eventMgr:broadcastEvent(_EEventType.TalentEffectOfCounterInvoked, { { conditionGroup = conditionGroup } })
end

function TalentEffectProcessor.RemoveTalentEffect(role, talentEffectGroupConfig)
    for _, talentResultConfig in pairs(talentEffectGroupConfig) do
        local talentEffectResultEnum = talentResultConfig[1]

        if talentEffectResultEnum == TalentEffectResultEnum.ModifyCharacterProperty then
            local propertyEnum, effectValue = talentResultConfig[2], talentResultConfig[3]
            PropertyCenter.AddProperty(role, propertyEnum, -effectValue)
            luaLog("天赋效果失活" .. tostring(propertyEnum) .. " -" .. effectValue)
        elseif talentEffectResultEnum == TalentEffectResultEnum.ModifyCharacterStateProperty then
            local stateType, value = talentResultConfig[2], talentResultConfig[3]
            role:roleStateChange(value < 0, stateType, math.abs(value))
            luaLog("天赋效果失活 - 状态属性 (饱食度等): " .. tostring(stateType) .. " " .. (value < 0 and "+" or "-") .. math.abs(value))
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddStorageForSkillType then
            local skillTypeEnum, addend = talentResultConfig[2], talentResultConfig[3]
            PropertyCenter.AddStorageForSkillType(role, skillTypeEnum, -addend);
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddStorageRecoverPctForSkillType then
            local skillTypeEnum, addend = talentResultConfig[2], talentResultConfig[3]
            PropertyCenter.AddStorageRecoveryProbability(role, skillTypeEnum, -addend)
        elseif talentEffectResultEnum == TalentEffectResultEnum.ReplaceSkillId then
            local skillId, _ = talentResultConfig[2], talentResultConfig[3]
            PropertyCenter.AddReplaceSkillId(role, skillId, nil)
        elseif talentEffectResultEnum == TalentEffectResultEnum.AddProbabilityAndMpRecoverPctForSkillType then
            local skillTypeEnum, probability, mpRecoverPct = talentResultConfig[2], talentResultConfig[3], talentResultConfig[4]
            PropertyCenter.RemoveProbabilityAndMpRecoveryPct(role, skillTypeEnum, probability, mpRecoverPct)
        end

        -- 如果有其他类型的天赋效果结果，可以在此处进行扩展
    end
end
