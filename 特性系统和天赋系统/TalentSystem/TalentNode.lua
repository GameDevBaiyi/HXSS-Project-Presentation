TalentNode = {}

function TalentNode.New(SlotId, NodeConfigIdsToCopy)
    local instance = {}

    -- Field: 槽位 Id.
    instance.SlotId = SlotId;
    -- Field: 该槽位的按等级排序的 天赋节点配置 Id.
    instance.TalentConfigIds = arrayDeepClone(NodeConfigIdsToCopy);
    -- Field: 该槽位当前的等级. 
    instance.Level = 0;

    return instance;
end

-- 获得该节点下一个等级(有最高等级限制)的配置
function TalentNode.GetNextLevelConfig(talentNode)
    local currentLevel = talentNode.Level
    local maxLevel = #talentNode.TalentConfigIds
    local nextLevel = currentLevel < maxLevel and currentLevel + 1 or currentLevel
    return TalentSystem.GetNodeConfigById(talentNode.TalentConfigIds[nextLevel])
end

-- bool, 表示该节点是否是 0 级. 
function TalentNode.IsLevelZero(talentNode)
    return talentNode.Level == 0
end

-- bool, 表示该节点是否已经是最高等级. 
function TalentNode.IsMaxLevel(talentNode)
    return talentNode.Level == #talentNode.TalentConfigIds
end



