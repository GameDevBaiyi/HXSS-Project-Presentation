function PropertyCenter.GetStorageRecoveryProbability(role, skillTypeEnum)
    local value = role.data.PropertyCenter.SkillTypeEnum_StorageRecoveryProbability[skillTypeEnum] or 0;
    return value;
end
function PropertyCenter.AddStorageRecoveryProbability(role, skillTypeEnum, addend)
    --Debug
    if (role == nil) then
        luaError("角色 roleData 为空. ")
        return
    end
    local existingValue = PropertyCenter.GetStorageRecoveryProbability(role, skillTypeEnum)
    local newValue = addend + existingValue
    role.data.PropertyCenter.SkillTypeEnum_StorageRecoveryProbability[skillTypeEnum] = newValue
end
