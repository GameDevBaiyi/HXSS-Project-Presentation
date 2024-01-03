require("game/CharacterSystems/CharacterTalentEffectSystem/TalentEffectConditionEnum")

TalentEffectCondition = {}

function TalentEffectCondition.New(conditionConfig)
    local instance = {}
    instance.conditionType = conditionConfig[1]
    -- 根据条件类型进行初始化
    if instance.conditionType == TalentEffectConditionEnum.BattleValueJudge then
        instance.characterPropertyEnum = conditionConfig[2]
        instance.symbol = conditionConfig[3]  -- 符号 (1代表 <=, 2代表 =, 3 代表 >=)
        instance.value = conditionConfig[4]  -- 具体数值
    elseif instance.conditionType == TalentEffectConditionEnum.PropertyValueIntervalJudge then
        instance.characterPropertyEnum = conditionConfig[2]
        instance.intervalStart = conditionConfig[3]  -- 区间开始
        instance.intervalEnd = conditionConfig[4]    -- 区间结束
    elseif instance.conditionType == TalentEffectConditionEnum.CounterJudge then
        instance.counterTypeEnum = conditionConfig[2]  -- 计数器类型
        instance.symbol = conditionConfig[3] -- 符号 (1代表 <=, 2代表 =, 3 代表 >=)
        instance.value = conditionConfig[4] -- 具体数值
        instance.currentCount = 0  -- 初始计数
    else
        luaError("无效的条件类型: " .. instance.conditionType)
        return nil
    end

    return instance
end

function TalentEffectCondition.IsSatisfied(role, talentEffectCondition)
    if talentEffectCondition.conditionType == TalentEffectConditionEnum.BattleValueJudge then
        if talentEffectCondition.symbol == 1 then
            return TalentConditionMonitor_Battle.GetValue(role, talentEffectCondition.characterPropertyEnum) <= talentEffectCondition.value
        elseif talentEffectCondition.symbol == 2 then
            return TalentConditionMonitor_Battle.GetValue(role, talentEffectCondition.characterPropertyEnum) == talentEffectCondition.value
        elseif talentEffectCondition.symbol == 3 then
            return TalentConditionMonitor_Battle.GetValue(role, talentEffectCondition.characterPropertyEnum) >= talentEffectCondition.value
        end
    elseif talentEffectCondition.conditionType == TalentEffectConditionEnum.PropertyValueIntervalJudge then
        return PropertyCenter.GetValue(role, talentEffectCondition.characterPropertyEnum) >= talentEffectCondition.intervalStart and PropertyCenter.GetValue(role, self.characterPropertyEnum) <= self.intervalEnd
    elseif talentEffectCondition.conditionType == TalentEffectConditionEnum.CounterJudge then
        if talentEffectCondition.symbol == 1 then
            return talentEffectCondition.currentCount <= talentEffectCondition.value
        elseif talentEffectCondition.symbol == 2 then
            return talentEffectCondition.currentCount == talentEffectCondition.value
        elseif talentEffectCondition.symbol == 3 then
            return talentEffectCondition.currentCount >= talentEffectCondition.value
        end
    end
    return false
end

-- IncrementCounter 方法，检查并增加计数器判断类型条件的 currentCount
function TalentEffectCondition.IncrementCounter(talentEffectCondition)
    -- Debug
    if not talentEffectCondition or talentEffectCondition.conditionType ~= TalentEffectConditionEnum.CounterJudge then
        luaError("IncrementCounter 只能用于计数器判断类型的条件")
        return
    end
    if talentEffectCondition.currentCount == nil then
        luaError("计数器类型的条件缺少 currentCount 参数")
        return
    end

    talentEffectCondition.currentCount = talentEffectCondition.currentCount + 1

    if TalentEffectSystemEventDetector.IsLogging then
        luaLog("计数器类型的条件增加了一次计数, 当前: " .. talentEffectCondition.currentCount)
    end
end

-- ResetCounter 方法，检查并重置计数器判断类型条件的 currentCount
function TalentEffectCondition.ResetCounter(talentEffectCondition)
    -- Debug
    if not talentEffectCondition or talentEffectCondition.conditionType ~= TalentEffectConditionEnum.CounterJudge then
        luaError("ResetCounter 只能用于计数器判断类型的条件")
        return
    end
    if talentEffectCondition.currentCount == nil then
        luaError("计数器类型的条件缺少 currentCount 参数")
        return
    end

    talentEffectCondition.currentCount = 0
    if TalentEffectSystemEventDetector.IsLogging then
        luaLog("计数器类型的条件重置了计数, 当前: " .. talentEffectCondition.currentCount)
    end
end
