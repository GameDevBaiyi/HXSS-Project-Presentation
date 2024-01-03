require("game/CharacterSystems/CharacterTalentEffectSystem/TalentEffectConditionGroup")

CharacterTalentEffect = {}

function CharacterTalentEffect.New(conditionGroupConfig)
    local instance = {}
    
    instance.conditionGroup = TalentEffectConditionGroup.New(conditionGroupConfig)

    return instance
end
