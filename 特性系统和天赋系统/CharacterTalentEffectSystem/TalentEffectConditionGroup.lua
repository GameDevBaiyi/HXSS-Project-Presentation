require("game/CharacterSystems/CharacterTalentEffectSystem/TalentEffectCondition")

TalentEffectConditionGroup = {}

function TalentEffectConditionGroup.New(conditionsConfig)
    local instance = {}
    -- field: isActive
    instance.isActive = false -- 初始为未激活状态
    -- field: conditions
    instance.conditions = {}
    for _, conditionConfig in pairs(conditionsConfig) do
        table.insert(instance.conditions, TalentEffectCondition.New(conditionConfig))
    end

    return instance
end

function TalentEffectConditionGroup.IsSatisfied(role, talentEffectConditionGroup)
    -- 如果一个条件也没有，返回true
    if #talentEffectConditionGroup.conditions == 0 then
        return true
    end

    for _, condition in pairs(talentEffectConditionGroup.conditions) do
        if not TalentEffectCondition.IsSatisfied(role,condition) then
            return false
        end
    end
    return true
end

function TalentEffectConditionGroup.Activate(talentEffectConditionGroup)
    talentEffectConditionGroup.isActive = true
end

function TalentEffectConditionGroup.Deactivate(talentEffectConditionGroup)
    talentEffectConditionGroup.isActive = false
end
