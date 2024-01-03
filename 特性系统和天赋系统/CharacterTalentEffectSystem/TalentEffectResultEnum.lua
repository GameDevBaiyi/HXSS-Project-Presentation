TalentEffectResultEnum = {
    None = 0,
    ModifyCharacterProperty = 11001,
    ModifyCharacterStateProperty = 11002, --减少 角色的饱食度等状态属性. 
    AddBuff = 11003,
    AddItem = 11004, -- 添加道具.
    AddEquipment = 11005, -- 添加装备.
    AddJiYi = 11006, -- 添加技艺. 
    AddStorageForSkillType = 11008, -- 添加指定技能类型的 储能上限.
    AddStorageRecoverPctForSkillType = 11009, -- 添加指定技能类型的 储能回复率.
    ReplaceSkillId = 11010, -- 替换 身上的技能 为 其他技能. 
    AddProbabilityAndMpRecoverPctForSkillType = 11011, -- 使用某类型的技能时, 有概率恢复灵力.
}