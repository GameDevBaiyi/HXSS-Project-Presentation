function PropertyCenter.GetProbabilityAndMpRecoveryPctList(role, skillTypeEnum)
    local probabilityAndMpRecoveryPctList = role.data.PropertyCenter.SkillTypeEnum_ProbabilityAndMpRecoveryPctList[skillTypeEnum] or { };
    return probabilityAndMpRecoveryPctList;
end
function PropertyCenter.AddProbabilityAndMpRecoveryPct(role, skillTypeEnum, probability, mpRecoverPct)
    --Debug
    if (role == nil) then
        luaError("角色 roleData 为空. ")
        return
    end
    if role.data.PropertyCenter.SkillTypeEnum_ProbabilityAndMpRecoveryPctList[skillTypeEnum] == nil then
        role.data.PropertyCenter.SkillTypeEnum_ProbabilityAndMpRecoveryPctList[skillTypeEnum] = { }
    end
    local probabilityAndMpRecoverPctList = role.data.PropertyCenter.SkillTypeEnum_ProbabilityAndMpRecoveryPctList[skillTypeEnum];
    local probabilityAndMpRecoveryPct = { Probability = probability, MpRecoverPct = mpRecoverPct }
    table.insert(probabilityAndMpRecoverPctList, probabilityAndMpRecoveryPct)
end
function PropertyCenter.RemoveProbabilityAndMpRecoveryPct(role, skillTypeEnum, probability, mpRecoverPct)
    --Debug
    if (role == nil) then
        luaError("角色 roleData 为空. ")
        return
    end
    if role.data.PropertyCenter.SkillTypeEnum_ProbabilityAndMpRecoveryPctList[skillTypeEnum] == nil then
        role.data.PropertyCenter.SkillTypeEnum_ProbabilityAndMpRecoveryPctList[skillTypeEnum] = { }
    end
    local probabilityAndMpRecoveryPctList = role.data.PropertyCenter.SkillTypeEnum_ProbabilityAndMpRecoveryPctList[skillTypeEnum];
    local probabilityAndMpRecoveryPct = { Probability = probability, MpRecoverPct = mpRecoverPct }
    for i = 1, #probabilityAndMpRecoveryPctList do
        if probabilityAndMpRecoveryPctList[i].Probability == probabilityAndMpRecoveryPct.Probability and probabilityAndMpRecoveryPctList[i].MpRecoverPct == probabilityAndMpRecoveryPct.MpRecoverPct then
            table.remove(probabilityAndMpRecoveryPctList, i)
            break
        end
    end
end
