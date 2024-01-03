TalentEffectConditionEnum = {
    None = 0,
    BattleValueJudge = 11001,
    PropertyValueIntervalJudge = 11002,
    CounterJudge = 11003, -- 添加新类型：计数器判断
}

CounterTypeEnum = {
    None = 0,
    DifferentSkillCastCount = 1, -- 释放不同技能计数, 通过事件 _EEventType.TraitBattleDiffSkill 来计数, 通过 进出战斗, 激活效果 来归位.
    DamageReceivedCount = 2, -- 受到伤害计数, 通过事件 _EEventType.TraitBattleBeHurt 来计数, 通过 进出战斗, 激活效果 来归位.
    DamageDealtCount = 3, -- 造成伤害计数, 通过事件 _EEventType.TraitBattleHurt 来计数, 通过 进出战斗, 激活效果 来归位.
    SecondsWithoutDamage = 4, -- 不受伤害的秒数计数, 通过事件 _EEventType.TraitBattleNoHurt 来计数, 通过 进出战斗, 激活效果, 受到伤害 来归位.
}