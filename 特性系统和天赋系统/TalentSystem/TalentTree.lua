require "game/CharacterSystems/TalentSystem/TalentNode"

TalentTree = {}

function TalentTree.New(BaGuaId, SlotId_NodeConfigIds)
    local instance = {}

    -- Field: 表示八卦 Id.
    instance.BaGuaId = BaGuaId;
    -- Field: 储存了天赋节点的数据, Dictionary<int,TalentNode> key 是 槽位 Id. 
    instance.SlotId_TalentNode = {};
    for SlotId, NodeConfigIds in pairs(SlotId_NodeConfigIds) do
        instance.SlotId_TalentNode[SlotId] = TalentNode.New(SlotId, NodeConfigIds)
    end
    -- Field: HashSet, 当前已经解锁的节点配置 Ids.
    instance.UnlockedNodeConfigIdSet = {};
    -- Field: 表示当前已经消耗的天赋点数.
    instance.ConsumedTalentPoints = 0;

    return instance
end

function TalentTree.RecordUnlockedNodeId(talentTree, nodeConfigId)
    talentTree.UnlockedNodeConfigIdSet[nodeConfigId] = 1
end

-- bool, 表示 talentNode 升级所需的前置节点是否全部解锁. 
function TalentTree.IsPrecedingNodeUnlocked(talentTree, talentNode)
    local nextLevelConfig = TalentNode.GetNextLevelConfig(talentNode)
    for _, preconditionId in pairs(nextLevelConfig.unlockingConditions) do
        if not talentTree.UnlockedNodeConfigIdSet[preconditionId] then
            return false
        end
    end
    return true
end

