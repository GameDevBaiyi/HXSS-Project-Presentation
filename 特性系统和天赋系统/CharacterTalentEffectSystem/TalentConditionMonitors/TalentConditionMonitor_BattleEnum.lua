TalentConditionMonitor_BattleEnum = {
    EquipmentCategory = 8000,
    WeaponType = 8001,
    IsCritting = 9000, -- 暴击了, 通过事件 _EEventType.TraitBattleCritPer 来触发并归位. 
    IsBreakingDefense = 9001, -- 破防了, 通过事件 _EEventType.TraitBattleThump 来触发并归位.
    IsParrying = 9002, -- 格挡了, 通过事件 _EEventType.TraitBattleBlockPer 来触发并归位.
    IsDodging = 9003, -- 闪避了, 通过事件 _EEventType.TraitBattleDodge 来触发并归位.
    IsStiffing = 9004, -- 使敌人硬直了, 通过事件 _EEventType.TraitBattleStagger 来触发但自己手动归位.
    IsStiffed = 9005, -- 自己被硬直了, 通过事件 _EEventType.TraitBattleBeStagger 来触发但自己手动归位.
}