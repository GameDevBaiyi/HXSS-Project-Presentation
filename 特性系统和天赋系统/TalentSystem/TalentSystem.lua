require "game/CharacterSystems/TalentSystem/TalentTree"
require "game/CharacterSystems/TalentSystem/TalentSystemEffectProcessor"

TalentSystem = {
    -- Static Field: 其中 NodeConfigIds 按 等级排序. 
    BaGuaId_SlotId_NodeConfigIds = {},
    -- Static Field: 以 前置节点 Id 检索可能解锁的槽位 Ids.
    BaGuaId_PrecedingSlotId_MaybeUnlockedSlotIds = {},
    -- Static Field: 表示对应的 Tree 总共需要的天赋点. 
    BaGuaId_TotalTalentPoints = {},
}

function TalentSystem.GetNodeConfigById(nodeConfigId)
    if (nodeConfigId == nil) then
        luaError("nodeConfigId 为空.")
        return
    end
    local nodeConfig = t_talent.config[nodeConfigId]
    if nodeConfig == nil then
        luaError("未找到该天赋节点配置: " .. nodeConfigId)
    end
    return nodeConfig
end

function TalentSystem.InitializeTalentConfig()
    TalentSystem.InitializeBaGuaId_SlotId_NodeConfigIds();
    TalentSystem.InitializeBaGuaId_PrecedingSlotId_MaybeUnlockedSlotIdsTalentSlot();
    TalentSystem.InitializeBaGuaId_TotalTalentPoints()
end

function TalentSystem.InitializeBaGuaId_SlotId_NodeConfigIds()
    for _, config in pairs(t_talent.config) do
        local diagrams = config.diagrams
        local slotId = config.slotId
        -- 确保对应的八卦ID和槽位ID的表项存在
        if not TalentSystem.BaGuaId_SlotId_NodeConfigIds[diagrams] then
            TalentSystem.BaGuaId_SlotId_NodeConfigIds[diagrams] = {}
        end
        if not TalentSystem.BaGuaId_SlotId_NodeConfigIds[diagrams][slotId] then
            TalentSystem.BaGuaId_SlotId_NodeConfigIds[diagrams][slotId] = {}
        end

        -- 将配置项的ID加入到列表中
        table.insert(TalentSystem.BaGuaId_SlotId_NodeConfigIds[diagrams][slotId], config.id)
    end

    -- 将 NodeConfigIds 按 等级排序.
    for _, slotConfigs in pairs(TalentSystem.BaGuaId_SlotId_NodeConfigIds) do
        for _, nodeConfigIds in pairs(slotConfigs) do
            table.sort(nodeConfigIds, function(a, b)
                local aNodeConfig = TalentSystem.GetNodeConfigById(a)
                local bNodeConfig = TalentSystem.GetNodeConfigById(b)
                return aNodeConfig.grade < bNodeConfig.grade
            end)
        end
    end
end
function TalentSystem.InitializeBaGuaId_PrecedingSlotId_MaybeUnlockedSlotIdsTalentSlot()
    for _, config in pairs(t_talent.config) do
        local diagrams = config.diagrams
        local slotId = config.slotId

        local unlockingConditions = config.unlockingConditions
        if not TalentSystem.BaGuaId_PrecedingSlotId_MaybeUnlockedSlotIds[diagrams] then
            TalentSystem.BaGuaId_PrecedingSlotId_MaybeUnlockedSlotIds[diagrams] = {}
        end
        for i = 1, #unlockingConditions do
            local _slot = configMgr:getTalentByID(unlockingConditions[i]).slotId
            if not TalentSystem.BaGuaId_PrecedingSlotId_MaybeUnlockedSlotIds[diagrams][_slot] then
                TalentSystem.BaGuaId_PrecedingSlotId_MaybeUnlockedSlotIds[diagrams][_slot] = {}
            end
            table.insert(TalentSystem.BaGuaId_PrecedingSlotId_MaybeUnlockedSlotIds[diagrams][_slot], slotId)
        end
    end
end
function TalentSystem.InitializeBaGuaId_TotalTalentPoints()
    for _, config in pairs(t_talent.config) do
        local diagrams = config.diagrams
        local upgradeConsumption = config.upgradeConsumption
        if not TalentSystem.BaGuaId_TotalTalentPoints[diagrams] then
            TalentSystem.BaGuaId_TotalTalentPoints[diagrams] = 0
        end
        TalentSystem.BaGuaId_TotalTalentPoints[diagrams] = TalentSystem.BaGuaId_TotalTalentPoints[diagrams] +
                upgradeConsumption
    end
end

function TalentSystem.New()
    local instance = {}

    -- Field: 当前天赋点数.
    instance.TalentPoints = 0;
    -- Field: 储存了天赋树的数据, Dictionary<int,TalentTree> key 是 八卦 Id.
    instance.BaGuaId_TalentTree = {};
    for BaGuaId, SlotId_TalentConfigIds in pairs(TalentSystem.BaGuaId_SlotId_NodeConfigIds) do
        instance.BaGuaId_TalentTree[BaGuaId] = TalentTree.New(BaGuaId, SlotId_TalentConfigIds)
    end

    return instance
end

function TalentSystem.AddInitialTalentPoints(role, initialNodeConfigIds)
    -- 初始化角色最开始拥有的天赋.
    if (initialNodeConfigIds == nil) then
        initialNodeConfigIds = {}
    else
        for _, nodeConfigId in pairs(initialNodeConfigIds) do
            local nodeConfig = TalentSystem.GetNodeConfigById(nodeConfigId)
            local baGuaId = nodeConfig.diagrams;
            local slotId = nodeConfig.slotId;
            TalentSystem.UpgradeNodeLevel(role, baGuaId, slotId, nil, false, false);
        end
    end
end

-- 升级天赋点必须调用此方法.
function TalentSystem.RecordConsumeTalentPoints(talentSystem, upgradeCost, baGuaId)
    talentSystem.BaGuaId_TalentTree[baGuaId].ConsumedTalentPoints = talentSystem.BaGuaId_TalentTree[baGuaId].ConsumedTalentPoints + upgradeCost
end

-- 升级天赋节点. 默认只需要传入前三个参数, 后面的参数是 Gm 命令用的.
function TalentSystem.UpgradeNodeLevel(role, baGuaId, slotId, targetLevel, shouldCheckPrecedingNodes,
                                       shouldConsumePoints)
    local talentSystem = role.data.TalentSystem;
    local talentTree = talentSystem.BaGuaId_TalentTree[baGuaId];
    local node = talentTree.SlotId_TalentNode[slotId];

    if TalentNode.IsMaxLevel(node) then
        -- BaiyiTODO. 由于没有唯一 Id, 做一个检测保证程序能运行. 
        -- luaError("对 八卦: " .. baGuaId .. " 的该槽位: " .. slotId .. " 升级时, 当前等级是最大等级了: ")
        return
    end
    -- 默认升级到下一等级
    if targetLevel == nil then
        targetLevel = node.Level + 1
    end
    -- 如果当前等级已经大于指定等级了, 报错. 
    if (targetLevel ~= nil and node.Level >= targetLevel) then
        luaError("对 八卦: " .. baGuaId .. " 的该槽位: " .. slotId .. " 升级到: " .. targetLevel ..
                "时, 当前等级已经大于等于指定等级了: " .. targetLevel)
        return
    end

    -- 默认会检测前置节点. 
    shouldCheckPrecedingNodes = shouldCheckPrecedingNodes == nil and true or shouldConsumePoints
    if shouldCheckPrecedingNodes and not TalentTree.IsPrecedingNodeUnlocked(talentTree, node) then
        luaError("对 八卦: " .. baGuaId .. " 的该槽位: " .. slotId .. " 升级到: " .. targetLevel ..
                "时, 有前置节点没解锁. ")
        return
    end

    local targetConfig = TalentSystem.GetNodeConfigById(node.TalentConfigIds[targetLevel]);
    if targetConfig == nil then
        luaError("对 八卦: " .. baGuaId .. " 的该槽位: " .. slotId .. " 升级时, 未找到该等级: " ..
                targetLevel)
        return ;
    end

    -- 默认会消耗天赋点. 
    shouldConsumePoints = shouldConsumePoints == nil and true or shouldConsumePoints
    local upgradeCost = targetConfig.upgradeConsumption
    if shouldConsumePoints and talentSystem.TalentPoints < upgradeCost then
        luaError("对 八卦: " .. baGuaId .. " 的该槽位: " .. slotId .. " 升级到: " .. targetLevel ..
                "时, 天赋点不足. 需要点数: " .. upgradeCost)
        return ;
    end

    -- 升级处理
    node.Level = targetLevel
    TalentTree.RecordUnlockedNodeId(talentTree, targetConfig.id);
    if shouldConsumePoints then
        talentSystem.TalentPoints = talentSystem.TalentPoints - upgradeCost
    end
    TalentSystem.RecordConsumeTalentPoints(talentSystem, upgradeCost, baGuaId)
    -- 激活天赋效果. (天赋系统的效果只考虑添加, 不考虑移除. )
    TalentSystemEffectProcessor.ApplyEffects(targetConfig.talentType, role)
    role.isDataDirty = true
end

-- bool, 表示其升级所需的天赋点是否足够. 
function TalentSystem.HasEnoughPoints(talentSystem, talentNode)
    local nextLevelConfig = TalentNode.GetNextLevelConfig(talentNode);
    local hasEnoughPoints = talentSystem.TalentPoints >= nextLevelConfig.upgradeConsumption;
    return hasEnoughPoints;
end

-- bool, 表示该节点是否可以升级 (前置解锁了 并且 天赋点足够).
function TalentSystem.CanUpgradeNode(talentSystem, talentNode)
    local nextLevelConfig = TalentNode.GetNextLevelConfig(talentNode)
    local talentTree = talentSystem.BaGuaId_TalentTree[nextLevelConfig.diagrams]
    local hasPrecedingNodesUnlocked = TalentTree.IsPrecedingNodeUnlocked(talentTree, talentNode)
    local hasEnoughPoints = TalentSystem.HasEnoughPoints(talentSystem, talentNode)

    return hasPrecedingNodesUnlocked and hasEnoughPoints
end

-- 添加天赋点.
function TalentSystem.AddTalentPoints(talentSystem, points)
    talentSystem.TalentPoints = talentSystem.TalentPoints + points
end
