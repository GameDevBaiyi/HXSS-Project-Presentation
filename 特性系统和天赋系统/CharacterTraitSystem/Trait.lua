require("game/CharacterSystems/CharacterTalentEffectSystem/CharacterTalentEffect")

Trait = {}

function Trait.New(configId, remainingTime)
    local instance = {}
    -- 1. field: configId
    instance.configId = configId

    -- 2. field: remainingTime
    -- 如果传入了 remainingTime, 直接使用传入的
    if remainingTime then
        instance.remainingTime = remainingTime
    elseif t_characteristic.config[configId].duration == 0 then
        -- 设计上: 如果该特性对应的特性配置是无限时间(duration==0), 则 remainingTime 为 nil. 反之, 则 remainingTime 为剩余时间.
        instance.remainingTime = nil
    else
        instance.remainingTime = t_characteristic.config[configId].duration
    end

    -- 3. field: talentEffect
    local conditionGroupConfig = t_characteristic.config[configId].effective
    if conditionGroupConfig then
        instance.talentEffect = CharacterTalentEffect.New(conditionGroupConfig)
    end
    return instance
end
