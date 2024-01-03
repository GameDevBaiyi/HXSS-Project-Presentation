function PropertyCenter.GetStorageForSkillType(role, skillTypeEnum)
    local value = role.data.PropertyCenter.SkillTypeEnum_Storage[skillTypeEnum] or 0;
    return value;
end
function PropertyCenter.AddStorageForSkillType(role, skillTypeEnum, addend)
    --Debug
    if (role == nil) then
        luaError("角色 roleData 为空. ")
        return
    end
    local existingValue = PropertyCenter.GetStorageForSkillType(role, skillTypeEnum)
    local newValue = addend + existingValue
    role.data.PropertyCenter.SkillTypeEnum_Storage[skillTypeEnum] = newValue
end
