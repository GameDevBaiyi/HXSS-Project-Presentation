function PropertyCenter.GetReplaceSkillId(role, skillId)
    return role.data.PropertyCenter.SkillId_ReplaceSkillId[skillId]
end
function PropertyCenter.AddReplaceSkillId(role, skillId, replaceSkillId)
    --Debug
    if (role == nil) then
        luaError("角色 roleData 为空. ")
        return
    end
    --Debug
    if (replaceSkillId ~= nil and PropertyCenter.GetReplaceSkillId(role, skillId) ~= nil) then
        luaError("某角色的该技能已经被替换" .. tostring(skillId) .. ", 不应尝试重复替换.")
        return
    end
    role.data.PropertyCenter.SkillId_ReplaceSkillId[skillId] = replaceSkillId
end
