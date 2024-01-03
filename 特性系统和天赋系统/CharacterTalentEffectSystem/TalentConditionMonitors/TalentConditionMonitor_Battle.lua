require("game/CharacterSystems/CharacterTalentEffectSystem/TalentConditionMonitors/TalentConditionMonitor_BattleEnum")

TalentConditionMonitor_Battle = {}

function TalentConditionMonitor_Battle.New()
    local talentConditionMonitor_battle = {}

    -- 数据结构是一个 Dictionary<TalentConditionMonitor_BattleEnum,int>.
    talentConditionMonitor_battle.Enum_Value = {};

    return talentConditionMonitor_battle;
end

function TalentConditionMonitor_Battle.SetValue(role, talentConditionMonitor_battleEnum, value)
    local talentConditionMonitor_battle = role.data.TalentConditionMonitor_Battle;
    talentConditionMonitor_battle.Enum_Value[talentConditionMonitor_battleEnum] = value;
    -- 当数值发生改变时, 需要更新特性的触发条件, 比如暴击时, 有某个特性可能会生效. 
    CharacterTraitCenter.UpdateTraitCondition(role);
end

function TalentConditionMonitor_Battle.GetValue(role, talentConditionMonitor_battleEnum)
    local talentConditionMonitor_battle = role.data.TalentConditionMonitor_Battle;
    return talentConditionMonitor_battle.Enum_Value[talentConditionMonitor_battleEnum] or 0;
end

