TalentSystemEffectEnum = {
    -- 1. 增加相性.
    AddXiangXing = 1,
    -- 2. 添加特性.
    AddTrait = 2,
    -- 3. 添加技能.
    AddSkill = 3,
}

TalentSystemEffectProcessor = {}

function TalentSystemEffectProcessor.ApplyEffects(effectConfigs, role)
    for _, effectConfig in pairs(effectConfigs) do
        local effectEnum = effectConfig[1];
        if effectEnum == TalentSystemEffectEnum.AddXiangXing then
            local propertyEnum = effectConfig[2];
            local addend = effectConfig[3];
            PropertyCenter.AddProperty(role, propertyEnum, addend)
        elseif effectEnum == TalentSystemEffectEnum.AddTrait then
            local traitId = effectConfig[2];
            CharacterTraitCenter.AddTrait(role, traitId)
        elseif effectEnum == TalentSystemEffectEnum.AddSkill then
            local skillId = effectConfig[2];
            role:addSkill(skillId);
        end
    end
end