function TalentEffectSystemEventDetector:InitializeForCounter()
    -- 释放不同技能计数, 通过事件 _EEventType.TraitBattleDiffSkill 来计数
    eventMgr:registerEvent(_EEventType.TraitBattleDiffSkill, handler(self.onTraitBattleDiffSkill, self))
    -- 受到伤害计数, 通过事件 _EEventType.TraitBattleBeHurt 来计数
    eventMgr:registerEvent(_EEventType.TraitBattleBeHurt, handler(self.onTraitBattleBeHurt, self))
    -- 造成伤害计数, 通过事件 _EEventType.TraitBattleHurt 来计数
    eventMgr:registerEvent(_EEventType.TraitBattleHurt, handler(self.onTraitBattleHurt, self))
    -- 不受伤害的秒数, 通过事件 _EEventType.TraitBattleNoHurt 来计数
    eventMgr:registerEvent(_EEventType.TraitBattleNoHurt, handler(self.onTraitBattleNoHurt, self))

    -- 释放不同技能计数, 通过 进出战斗 来归位
    -- 受到伤害计数, 通过 进出战斗 来归位
    -- 造成伤害计数, 通过 进出战斗 来归位
    -- 不受伤害的秒数, 通过 进出战斗 来归位
    eventMgr:registerEvent(_EEventType.TraitBattleEnter, handler(self.onTraitBattleEnter, self))
    eventMgr:registerEvent(_EEventType.TraitBattleEnd, handler(self.onTraitBattleEnd, self))

    -- 释放不同技能计数, 通过 激活效果 来归位
    -- 受到伤害计数, 通过 激活效果 来归位
    -- 造成伤害计数, 通过 激活效果 来归位
    -- 不受伤害的秒数, 通过 激活效果 来归位
    eventMgr:registerEvent(_EEventType.TalentEffectOfCounterInvoked, handler(self.onTalentEffectOfCounterInvoked, self))
end

function TalentEffectSystemEventDetector:onTraitBattleDiffSkill(params)
    local role = params[1].role;
    if role == nil then
        luaError("释放不同技能计数 的事件 的参数 role 为空")
        return
    end

    for _, trait in pairs(role.data.traits) do
        local conditions = trait.talentEffect.conditionGroup.conditions
        for _, condition in pairs(conditions) do
            if condition.counterTypeEnum == CounterTypeEnum.DifferentSkillCastCount then
                TalentEffectCondition.IncrementCounter(condition)
            end
        end
    end

    CharacterTraitCenter.UpdateTraitCondition(role)
end

function TalentEffectSystemEventDetector:onTraitBattleBeHurt(params)
    local role = params[1].role;
    if role == nil then
        luaError("受到伤害计数 的事件 的参数 role 为空")
        return
    end

    for _, trait in pairs(role.data.traits) do
        local conditions = trait.talentEffect.conditionGroup.conditions
        for _, condition in pairs(conditions) do
            if condition.counterTypeEnum == CounterTypeEnum.DamageReceivedCount then
                TalentEffectCondition.IncrementCounter(condition)
            end
        end
    end

    CharacterTraitCenter.UpdateTraitCondition(role)
end

function TalentEffectSystemEventDetector:onTraitBattleHurt(params)
    local role = params[1].role;
    if role == nil then
        luaError("造成伤害计数 的事件 的参数 role 为空")
        return
    end

    for _, trait in pairs(role.data.traits) do
        local conditions = trait.talentEffect.conditionGroup.conditions
        for _, condition in pairs(conditions) do
            if condition.counterTypeEnum == CounterTypeEnum.DamageDealtCount then
                TalentEffectCondition.IncrementCounter(condition)
            end
        end
    end

    CharacterTraitCenter.UpdateTraitCondition(role)
end

function TalentEffectSystemEventDetector:onTraitBattleNoHurt(params)
    local role = params[1].role;
    if role == nil then
        luaError("不受伤害的秒数 的事件 的参数 role 为空")
        return
    end

    for _, trait in pairs(role.data.traits) do
        local conditions = trait.talentEffect.conditionGroup.conditions
        for _, condition in pairs(conditions) do
            if condition.counterTypeEnum == CounterTypeEnum.SecondsWithoutDamage then
                TalentEffectCondition.IncrementCounter(condition)
            end
        end
    end

    CharacterTraitCenter.UpdateTraitCondition(role)
end

function TalentEffectSystemEventDetector:onTraitBattleEnter(params)
    local role = params[1].role;
    if role == nil then
        luaError("进入战斗的 的事件 的参数 role 为空")
        return
    end

    for _, trait in pairs(role.data.traits) do
        local conditions = trait.talentEffect.conditionGroup.conditions
        for _, condition in pairs(conditions) do
            TalentEffectCondition.ResetCounter(condition)
        end
    end

    CharacterTraitCenter.UpdateTraitCondition(role)
end

function TalentEffectSystemEventDetector:onTraitBattleEnd(params)
    local role = params[1].role;
    if role == nil then
        luaError("离开战斗 的事件 的参数 role 为空")
        return
    end

    for _, trait in pairs(role.data.traits) do
        local conditions = trait.talentEffect.conditionGroup.conditions
        for _, condition in pairs(conditions) do
            TalentEffectCondition.ResetCounter(condition)
        end
    end

    CharacterTraitCenter.UpdateTraitCondition(role)
end

function TalentEffectSystemEventDetector:onTalentEffectOfCounterInvoked(params)
    if params[1].conditionGroup == nil then
        luaError("计数器类型的天赋条件对应的效果激活 的事件 的参数 conditionGroup 为空")
        return
    end

    local conditions = params[1].conditionGroup.conditions
    if conditions == nil then
        return
    end
    for _, condition in pairs(conditions) do
        TalentEffectCondition.ResetCounter(condition)
    end
end



