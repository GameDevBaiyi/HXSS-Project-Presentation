require "game/gameData/attributeDataBase"
require "game/bagSystem/equipmentData"
require "game/CharacterSystems/CharacterPropertySystem/CharacterPropertyCenter"
require "game/CharacterSystems/CharacterTraitSystem/CharacterTraitCenter"
require "game/CharacterSystems/TalentSystem/TalentSystem"

---@class RoleData:AttributeDataBase
RoleData = Class(AttributeDataBase)
function RoleData:ctor()
end
function RoleData:init(arg)

    self.roleId = arg.roleId
    if arg.smallId == nil then
        self.id = self.roleId
    else
        self.id = self.roleId .. "_" .. arg.smallId
    end
    self.fileName = "roleData_" .. self.id
    self.data = self:readData()
    if self.data == nil then
        self:defaultData()
        self:saveData()
    end

    self:registerEvent(_EEventType.Month, self.onMonthEvent, self)
    self:registerEvent(_EEventType.TimeJump, self.timeSkip, self)
    self:registerEvent(_EEventType.PassedHour, self.PassedHour, self)
end

function RoleData:PassedHour()
    if self.data.hasDurationTrait then
        CharacterTraitCenter.DecreaseTraitDuration(self, 1)
    end
end

-- 每月事件处理
function RoleData:onMonthEvent()
    -- 差事
    if self.data.assignment.id ~= 0 then
        local _info = {}
        _info.type = _EBehaviorLogType.Assignment
        _info.id = self.data.assignment.id
        self:addBehaviorLog(_info)
        -- self:inventoryChangeNum()
    end

    if self.data.type == _RoleType.Hero then
        self:roleGrow(1)
    end

    -- 月例交互事件
    self.data.mouthInterEvents = {}
end

-- 得到临时特性
function RoleData:getTemporaryFeature()
    return arrayDeepClone(self.data.perrsonality.temporaryFeatures)
end

function RoleData:roleTemporaryFeatureReduce(value)
    local needCullFeatures = {}
    for i = 1, #self.data.perrsonality.temporaryFeatures do
        self.data.perrsonality.temporaryFeatures[i].days = self.data.perrsonality.temporaryFeatures[i].days - value
        if self.data.perrsonality.temporaryFeatures[i].days <= 0 then
            table.insert(needCullFeatures, self.data.perrsonality.temporaryFeatures[i].id)
        end
    end
    self.isDataDirty = true
end

-- 跳转时间
function RoleData:timeSkip(parmas)
    local isInTheQueque = false
    local roleInList = dataMgr.playerData:getRolesInRank()
    for i = 1, #roleInList do
        if roleInList[i] == self.data.id then
            isInTheQueque = true
        end
    end
end

function RoleData:defaultData()
    local _cfg = configMgr:getRoleCfg(self.id)
    local _default = self:base_defaultData(_cfg)

    _default.id = _cfg.id -- 非唯一id，为角色id
    _default.modelName = _cfg.model -- 模型ID
    _default.oldModelName = _cfg.model -- 方便后面换装调用初始模型
    _default.faceData = self:reloadingRoleInfo(_cfg) ---初始面部数据
    _default.surname = _cfg.surname -- 姓
    _default.familyName = _cfg.familyName -- 氏族
    _default.appellation = _cfg.name -- 名
    _default.identity = _cfg.identity -- 身份
    _default.salary = 0 -- 工资
    _default.country = _cfg.country -- 国家ID
    _default.category = _cfg.category -- 种族
    _default.organizationId = 0 -- 势力ID    TODO:势力生成的时候赋予该属性
    _default.factionReputation = {} -- 当前角色对于其他势力的部分数据
    _default.officialPosition = 0 -- 官职     文职和武职公用
    _default.officialSatisfaction = 100 -- 文职官员满意度（人事列表）初始满意度还没有配表
    _default.roleSatisfaction = self:initSatisfaction(_default, _cfg) -- 角色好感度

    _default.officialState = _OfficialState.Standby -- 文职官员状态（人事列表）
    _default.positionId = _cfg.city -- 角色初始所属城市
    _default.charm = 0 -- 魅力
    _default.gender = _cfg.gender -- 性别
    _default.age = _cfg.age -- 年龄
    _default.ageBracket = "" -- 年纪
    _default.countyId = 0 -- 当前官员在具体城市或者县城入职情况
    _default.stateType = 0 -- 当前角色状态 0：空闲； 1_建筑id：在某个建筑当官员；2_运输队id:在某个运输队充当负责人；3_运输队id:某个运输队的护送队充当护送官员；（运输）
    -- #region 技艺
    _default.LifeSkills = {}
    -- #endregion
    -- #region 觉醒
    _default.awakening = {}
    _default.awakening.table = {}
    _default.awakening.level = 0
    _default.awakening.totemId = 0 -- 图腾组ID
    -- #endregion

    -- #endregions
    -- #region 人格
    _default.perrsonality = {}
    _default.perrsonality.idea = self:initIdea() -- 角色装备了的理念
    _default.perrsonality.experence = {}
    _default.perrsonality.yinValue = 0 -- 阴阳值
    _default.perrsonality.yangValue = 0
    _default.perrsonality.permanentFeatures = {} -- 永久特性 目前获得方式：经历获得和天赋学习
    _default.perrsonality.temporaryFeatures = {} -- 临时特性
    _default.perrsonality.ideaList = {}
    _default.perrsonality.type = _HumanPersonality.Balance -- 阴阳偏向
    _default.perrsonality.opinionType = _HumanOpinion.ZhongYong -- 主张
    _default.perrsonality.opinionValue = {0, 0, 0, 0, 0} -- 王 霸 侠 我 主张四值
    _default.perrsonality.guaxiangopinionValue = {0, 0, 0, 0, 0, 0, 0, 0} -- 卦象对应主张分数
    _default.perrsonality.ideaType = _ESchool.RuJia
    _default.perrsonality.ideaValue = {0, 0, 0, 0, 0, 0, 0, 0, 0} -- 人格中理念偏向值
    -- #endregion
    -- #region 学派
    _default.schoolOfThought = {}
    _default.schoolOfThought.shcookNum = 0
    _default.schoolOfThought.idList = {} -- 学派解锁id（包括技能、理念）
    _default.schoolOfThought.lockedList = self:initSchoolOfThought()
    _default.schoolOfThought.lockedLv = self:schoolLockedLV() -- 解锁层级
    _default.schoolOfThought.knowledgeList = self:schoolLockedKnowledge()
    -- #endregion
    -- region 背包
    _default.bagContent = {}
    _default.bagContent[_BagContent.Equipment] = {}
    _default.equipmentInstanceId = 0
    _default.bagContent[_BagContent.Consumable] = {}

    _default.teamBagContent = {} -- 小队背包整合(玩家+英雄)
    _default.teamBagContent[_BagContent.Equipment] = {}
    _default.teamBagContent[_BagContent.Consumable] = {}

    -- 锻造图谱：已解锁图谱列表
    _default.unlockForgeFormula = {}
    _default.unlockCookFormula = {}
    _default.unlockMedicalFormula = {}

    -- #endregion
    -- 人事
    _default.assignment = {}
    _default.assignment.id = 0

    -- 行为日志
    _default.behaviorLog = {}

    _default.noRunning = true -- 是否可以移动

    -- 是否与玩家交互过:没见过面
    _default.firstMeet = false

    -- 月例交互事件(每月1号刷新)
    _default.mouthInterEvents = {}

    -- 角色住所数据
    _default.homeData = self:defaultDmicileData(_cfg)

    -- 临时住所
    _default.tempTavern = {}

    self.data = _default
    self:defaultRoleData(_cfg)
end

function RoleData:getRoleModelId(cfg)
    if cfg.category == 11 and cfg.gender ~= 0 then
        return dataMgr.roleDataMgr.roleModelIdList[cfg.gender]
    else
        return cfg.model
    end
end

-- 设置当前角色的模型id
function RoleData:changeModelName(isInit)

    local _modelId = 0
    local _modelName = ""
    local _equip = self.data.equipmentList
    local _str = "human_" .. (self.data.gender == 1 and "male_" or "female_") -- 模型前缀
    local _stryiwu = string.split(configMgr:getModelById(self.data.oldModelName).resourceName, "_")[3]
    if _stryiwu == nil then
        return
    end
    -- luaError("_stryiwu=======" .. _stryiwu)
    -- luaError("_equip[4].id=====" .. tostring(_equip[4].id))
    if _equip[4].equipmentCategory == _EEquipmentCategory.Cloth then
        _stryiwu = "21000"
    elseif _equip[4].equipmentCategory == _EEquipmentCategory.Silk then
        _stryiwu = "21216"
    elseif _equip[4].equipmentCategory == _EEquipmentCategory.Brocade then
        _stryiwu = "21315"
    end

    _modelName = _str .. _stryiwu -- 模型完整名称
    _modelId = configMgr.modelName[_modelName]

    if _modelId ~= nil and _modelId ~= 0 then
        local _modelName = configMgr:getModelById(_modelId).resourceName
        self.data.modelName = _modelId
        if not isInit then
            eventMgr:broadcastEvent(_EEventType.RoleChangeWeapon, {{
                id = self.data.id
            }})
            if sceneMgr.curScene ~= nil and self.data.id == dataMgr.roleDataMgr.playerId then
                sceneMgr.curScene:reSpawnPlayer(_modelName)
            end
        end
    end
end

-- 获得名望值
function RoleData:getRenownValue()
    local _allRole = configMgr:getAllRole()
    local allFaction = configMgr:getAllFaction()
    local hgPart = 0
    for k, v in pairs(_allRole) do
        local _role = dataMgr.roleDataMgr:getRoleData(v.id)
        if _role:getFirstMeet() then
            hgPart = hgPart + self:getFavorabilityToOthers(v.id)
        end
    end

    local shiLiPart = 0
    for k, v in pairs(allFaction) do
        shiLiPart = shiLiPart + self:getFactionPopularityByid(v.id)
    end
    return shiLiPart * 10 + hgPart * 2
end

-- 获得名望值总值
function RoleData:getRenownValueMax()
    local _allRole = configMgr:getAllRole()
    local allFaction = configMgr:getAllFaction()
    -- local hgPart = 0

    -- for k, v in pairs(_allRole) do
    --         hgPart = hgPart + self:getFavorabilityToOthers(v.id)
    -- end

    -- local shiLiPart = 0
    -- for k, v in pairs(allFaction) do
    --     shiLiPart = shiLiPart + self:getFactionPopularityByid(v.id)
    -- end
    return #allFaction * 10 * 250 + #_allRole * 2 * 250
end

-- 获取当前角色的完整名称
function RoleData:getRoleName()
    local _nameStr = ""
    if self.data.identity == _EIdentity.Wang then
        if self.data.id == dataMgr.roleDataMgr.playerId then
            _nameStr = self.data.surname .. self.data.appellation
        else
            if self.data.surname ~= 0 then
                _nameStr = configMgr:getLanguage(self.data.surname) .. configMgr:getLanguage(self.data.appellation)
            else
                _nameStr = configMgr:getLanguage(self.data.appellation)
            end
        end
    else
        if self.data.familyName ~= 0 then
            if self.data.id == dataMgr.roleDataMgr.playerId then
                _nameStr = _nameStr .. self.data.familyName .. self.data.appellation
            else
                _nameStr = _nameStr .. configMgr:getLanguage(self.data.familyName) ..
                               configMgr:getLanguage(self.data.appellation)
            end
        else
            if self.data.id == dataMgr.roleDataMgr.playerId then
                _nameStr = _nameStr .. self.data.surname .. self.data.appellation
            else
                if self.data.surname ~= 0 then
                    _nameStr = _nameStr .. configMgr:getLanguage(self.data.surname) ..
                                   configMgr:getLanguage(self.data.appellation)
                else
                    _nameStr = _nameStr .. configMgr:getLanguage(self.data.appellation)
                end
            end
        end
    end
    return _nameStr

end

function RoleData:defaultExperienceData(cfgData)
    if cfgData.experienceID == nil then
        cfgData.experienceID = {}
    end
    if #cfgData.experienceID ~= 0 then
        for i = 1, #cfgData.experienceID[1] do
            self:addRoleExperience(cfgData.experienceID[1][i], true)
        end
    end
end

-- 角色状态初始化及修改方法
function RoleData:initAndChangeRoleOfficalState(stateType)
    self.data.officialState = stateType
    self.isDataDirty = true
end

-- 角色官职初始化和改变
function RoleData:initAndChangeRoleOfficalId(id)
    self.data.officialPosition = id
    self.isDataDirty = true
end

-- 当前角色在什么地方当官
function RoleData:initAndChangeRoleCounyId(id)
    self.data.countyId = id
    self.isDataDirty = true
end

-- 角色势力初始化和改变
function RoleData:initAndChangeRoleOrganizationId(id)
    local factionCfg = configMgr:getFactionById(id)
    self.data.organizationId = id
    self.data.factionReputation[id] = factionCfg.Initialreputation
    self.isDataDirty = true
end

-- 角色添加经历  (isInitial:是否是初始选择的经历)
function RoleData:addExperience(experienceId, isInitial)
    local curExperienceCfg = configMgr:getExperienceById(experienceId)
    -- 经历获得特性
    if #curExperienceCfg.characteristicID > 0 then
        for i = 1, #curExperienceCfg.characteristicID[1] do
            self:changePermanentFeatures(curExperienceCfg.characteristicID[1][i])
        end
    end
    -- 获得装备 若是初始经历 装备需要上到装备栏上面
    if #curExperienceCfg.equipmentID ~= 0 then
        for j = 1, #curExperienceCfg.equipmentID[1] do
            local equipmentData = configMgr:getEquipmentById(curExperienceCfg.equipmentID[1][j])
            if isInitial == true then
                if equipmentData.equipmentType == 1 then
                    if isKarateEquipment(self.data.equipmentList[1]) then
                        self.data.equipmentList[1] = equipmentData
                    elseif isKarateEquipment(self.data.equipmentList[2]) then
                        self.data.equipmentList[2] = equipmentData
                    else
                        self:addBagEquipment(equipmentData, true)
                    end
                else
                    if self.data.equipmentList[equipmentData.equipmentType + 1].id ~= nil then
                        self:addBagEquipment(equipmentData, true)
                    else
                        self.data.equipmentList[equipmentData.equipmentType + 1] = equipmentData
                        self:clothCharm(equipmentData.equipmentType + 1, false)
                    end
                    self:changeModelName(true)
                end
            else
                self:addBagEquipment(equipmentData, true)
            end
        end
    end

    -- 经历获得初始天赋
    if #curExperienceCfg.talentID ~= 0 then
        local _slotId = 1
        for j = 1, #curExperienceCfg.talentID[1] do
            -- self:addTalentData(curExperienceCfg.talentID[1][j], 1, isInitial)
            local _talentData = configMgr:getTalentByID(curExperienceCfg.talentID[1][j])
            TalentSystem.UpgradeNodeLevel(self, _talentData.diagrams, _talentData.slotId, nil, nil, false)
        end
    end
    -- 引导使用后续删除
    if isInitial == true then
        local _publicData = configMgr:getPublicData(186).value
        local index = 1
        for i = 1, #_publicData, 2 do
            for h = 1, 2 do
                local _talentCfg = configMgr:getTalentByID(_publicData[i])
                i = i + 1
                self:setRoleUseSkill(h, _talentCfg.talentType[1][2], index)
            end
            index = index + 1
        end
    end

    -- 经历获得技艺经验 (没有技艺升级表) 技艺升级TODO
    if #curExperienceCfg.skillexperience ~= 0 then
        local skillExperience = configMgr:getPublicData(9).value
        for j = 1, #curExperienceCfg.skillexperience do
            self:addTechniqueExp(curExperienceCfg.skillexperience[j][1], curExperienceCfg.skillexperience[j][2], true)
        end
    end
    -- 国家
    if curExperienceCfg.country ~= 0 then
        self.data.country = curExperienceCfg.country
    end
    -- 姓
    if curExperienceCfg.surname ~= 0 then
        self.data.surname = curExperienceCfg.surname
    end
    -- 氏
    if curExperienceCfg.familyName ~= 0 then
        self.data.familyName = curExperienceCfg.familyName
    end
    -- 身份
    if curExperienceCfg.identity ~= 0 then
        self:setIdentity(curExperienceCfg.identity, true)
    end
    -- 获得道具和钱币
    if #curExperienceCfg.propId ~= 0 then
        for j = 1, #curExperienceCfg.propId do
            self:addConsumable(curExperienceCfg.propId[j][1], curExperienceCfg.propId[j][2], true)
        end
    end
    if #curExperienceCfg.awaken ~= 0 and isInitial == true then
        -- 初始获得觉醒图腾、觉醒阶段
        self.data.awakening.totemId = configMgr:getAwaken(curExperienceCfg.awaken[1][1]).groupId
        self.data.awakening.level = 0
    end
    -- 学派技能(理念和技能)
    if #curExperienceCfg.schoolID ~= 0 then
        for j = 1, #curExperienceCfg.schoolID[1] do
            self:addSchoolData(curExperienceCfg.schoolID[1][j], false)
            local data = curExperienceCfg.schoolID[1][j]
            local _data = configMgr:getSchoolSkill(data)
            local equippedSkillNum = self:getUseSkill()
            if _data.talentType[1][1] == 2 and isInitial == true and #equippedSkillNum < 2 then
                self:setRoleUseSkill(#equippedSkillNum + 1, _data.talentType[1][2], _EEquipmentSlot.MainWeapon)
            end
        end

    end
    -- 添加经历
    self:addRoleExperience(experienceId, isInitial)
    if isInitial ~= true then
        self.isDataDirty = true
    end
end

-- 技艺升级
function RoleData:upTechniqueLv(type, addLv)
    if addLv == nil then
        addLv = 1
    end
    self.data.levelInfo[_EMainAttributesType.Technique][type].lv =
        self.data.levelInfo[_EMainAttributesType.Technique][type].lv + addLv
    if self.data.levelInfo[_EMainAttributesType.Technique][type].lv < 0 then
        self.data.levelInfo[_EMainAttributesType.Technique][type].lv = 0
    elseif self.data.levelInfo[_EMainAttributesType.Technique][type].lv > 5 then
        self.data.levelInfo[_EMainAttributesType.Technique][type].lv = 5
    end

    if type == _ETechniqueType.Forge then
        self:refreshForgeFormula()
    end
    if type == _ETechniqueType.Cook then
        self:refreshCookFormula()
    end

    eventMgr:broadcastEvent(_EEventType.TechniqueUpLv, {{
        techniqueType = type,
        curLv = self.data.levelInfo[_EMainAttributesType.Technique][type].lv
    }})
end

-- 创建角色初始根据等级计算当前加点数据
function RoleData:addExperienceValue(data)
    -- 精
    local curStrengthLv = arrayDeepClone(self.data.levelInfo[_EMainAttributesType.Strength])

    local _talent1 = 0
    -- local _assignCredits1 = 0
    for i = 1, curStrengthLv.lv do
        local curLvCfgData = configMgr:getRoleLevel(1000 + i)

        _talent1 = _talent1 + curLvCfgData.talent
    end
    self:changeAttributePointWrapper(1, data.bloodEssence)
    self:changeAttributePointWrapper(3, data.agility)
    self:changeAttributePointWrapper(2, data.power)
    -- 升级增加天赋点
    self:addTalentPoint(_talent1, true)

    -- 神
    local wisdom = arrayDeepClone(self.data.levelInfo[_EMainAttributesType.Wisdom])

    local _talent2 = 0
    -- local _assignCredits2 = 0

    for i = 1, wisdom.lv do
        local curLvCfgData = configMgr:getRoleLevel(2000 + i)
        _talent2 = _talent2 + curLvCfgData.talent

    end
    self:changeAttributePointWrapper(5, data.politicalStrategy)
    self:changeAttributePointWrapper(6, data.militaryStrategy)
    self:changeAttributePointWrapper(4, data.ability)
    -- 升级增加天赋点
    self:addTalentPoint(_talent2, true)

    -- 气
    local wakan = arrayDeepClone(self.data.levelInfo[_EMainAttributesType.Wakan])
    local _talent3 = 0

    for i = 1, wakan.lv do
        local curLvCfgData = configMgr:getRoleLevel(3000 + i)
        _talent3 = _talent3 + curLvCfgData.talent
    end
    self:changeAttributePointWrapper(7, data.airSea)
    self:changeAttributePointWrapper(9, data.perception)
    self:changeAttributePointWrapper(8, data.spellDamage)
    -- 升级增加天赋点
    self:addTalentPoint(_talent2, true)
    self:defaultRoleAgeBracketName(self.data)

end
-- 初始角色数据
function RoleData:defaultRoleData(cfg)
    self:defaultSchoolData(cfg)
    self:defaultTaData(cfg)
    self:defaultExperienceData(cfg)
    self:defaultAwakenAndSkillData(cfg)
    self:defaultBagContent(cfg)
    self:defaultWuxing(cfg)
    self:defaultRoleAgeBracketName(cfg)
    if self.data.id == dataMgr.roleDataMgr.playerId then
        self:defaultTechniqueData()
    end
    if #cfg.force > 0 and cfg.force[1] == _RoleFoceType.CountryFaction then -- 国家势力
        local _factionId = cfg.force[2]
        self:initAndChangeRoleOrganizationId(_factionId)
        dataMgr.factionDataMgr:getFaction(_factionId):addRole(self.data.id)
    end
    self:changeModelName(true)

    -- 角色系统
    -- 角色属性系统.
    CharacterPropertyCenter.Initialize(self, cfg)
    -- 角色特性系统. 
    CharacterTraitCenter.Initialize(self)
    -- 角色天赋系统.
    self.data.TalentSystem = TalentSystem.New();
    TalentSystem.AddInitialTalentPoints(self, configMgr:getRoleCfg(self.id).talentId[1])
    self:defaultIdeaData(cfg)
    self.isDataDirty = true
end

-- 年纪名字
function RoleData:defaultRoleAgeBracketName(cfg)
    local _arg = {}
    _arg.gender = cfg.gender
    _arg.age = cfg.age
    _arg.category = cfg.category
    local _cfg = configMgr:getAgeBracket(_arg)
    if _cfg ~= nil then
        cfg.ageBracket = configMgr:getLanguage(_cfg.age)
    end
end

-- todo初始化住所数据
function RoleData:defaultDmicileData(cfg)
    local _data = {}
    table.insert(_data, self:getHomeZoneByIdentity(cfg))
    return _data
end

-- 初始化技艺
function RoleData:defaultTechniqueData()
    self:refreshForgeFormula()
    self:refreshCookFormula()
    self:refreshMedicalFormula()
end

-- 角色刚接到任务时计算任务进度
function RoleData:calculateTheProgressOfTask(taskId)
    local curTaskCfg = questMgr:getQuest(taskId)
    local taskTarget = curTaskCfg.objectives
    for i = 1, #taskTarget do
        if taskTarget[i].type == _EQuestObjectiveType.CollectObjective then
            for j = 1, #self.data.bagContent[_BagContent.Consumable] do
                if self.data.bagContent[_BagContent.Consumable][j].modelId == taskTarget[i].itemID then
                    eventMgr:broadcastEvent(_EEventType.GetItem, {{
                        itemID = taskTarget[i][3],
                        amount = self.data.bagContent[_BagContent.Consumable][j].num
                    }})
                end
            end
        end
    end
end

-- 得到该角色背包中该ID道具的数量
function RoleData:getItemNumberById(itemId)
    local number = 0
    for i = 1, #self.data.bagContent[_BagContent.Consumable] do
        if itemId == self.data.bagContent[_BagContent.Consumable][i].modelId then
            number = number + self.data.bagContent[_BagContent.Consumable][i].num
        end
    end
    return number
end

-- 得到该角色背包中所有该类别道具的排序id  
function RoleData:getItemSort(sortType, sortValue, rangeType)
    local _list = {}
    local _count = 0 -- 此类的所有物品数量
    for i = 1, #self.data.bagContent[_BagContent.Consumable] do
        local _id = self.data.bagContent[_BagContent.Consumable][i].modelId
        local _propCfg = configMgr:getPropById(_id)

        if sortType == _EItemSortType.Subclass then
            if sortValue == _propCfg.subclass then
                table.insert(_list, _id)
                _count = _count + self.data.bagContent[_BagContent.Consumable][i].num
            end
        end
    end

    if rangeType == _EItemRangeType.Quality then
        table.sort(_list, self.compareQuality)
    end

    local _arg = {
        idList = _list,
        num = _count
    }
    return _arg
end

function RoleData:compareQuality(a, b)
    local _apropCfg = configMgr:getPropById(a)
    local _bpropCfg = configMgr:getPropById(b)
    return _apropCfg < _bpropCfg
end

function RoleData:getRandomItem()
    local _indexType = math.random(1, 2)
    local _itemList = self.data.bagContent[_indexType]
    if _itemList == nil or #_itemList == 0 then
        return nil
    end
    local _itemIndex = math.random(1, #_itemList)

    local _params = {}
    local _item = _itemList[_itemIndex]
    _params.type = _indexType
    _params.id = _item.modelId
    _params.num = _item.num

    table.remove(_itemList, _itemIndex)
    return _params
end

-- 初始角色背包内容
function RoleData:defaultBagContent(cfg)
    -- 该角色初始的装备
    for i = 1, #cfg.equipmentId do
        -- TODO
        for j = 1, cfg.equipmentId[i][2], 1 do
            local equipment = {}
            local equipmentCfgData = configMgr:getEquipmentById(cfg.equipmentId[i][1])
            equipment.data = arrayDeepClone(equipmentCfgData)
            self.data.equipmentInstanceId = self.data.equipmentInstanceId + 1
            equipment.instanceId = self.data.equipmentInstanceId
            equipment.type = _BagContent.Equipment
            table.insert(self.data.bagContent[_BagContent.Equipment], equipment)
        end
    end
    -- 该角色初始的道具
    for i = 1, #cfg.propId do
        local isExistence = false
        for j = 1, #self.data.bagContent[_BagContent.Consumable] do
            if self.data.bagContent[_BagContent.Consumable][j].modelId == cfg.propId[i][1] then
                isExistence = true
                self.data.bagContent[_BagContent.Consumable][j].num =
                    self.data.bagContent[_BagContent.Consumable][j].num + cfg.propId[i][2]
                break
            end
        end
        if isExistence == false then
            table.insert(self.data.bagContent[_BagContent.Consumable], {
                modelId = cfg.propId[i][1],
                num = cfg.propId[i][2],
                type = _BagContent.Consumable
            })
        end
    end
end
-- 刷新获得队伍的整合背包
function RoleData:getMixTeamBag()
    local _teamList = self:getteamRecruitmentById()
    table.insert(_teamList, dataMgr.roleDataMgr.playerId)
    self.data.teamBagContent[_BagContent.Consumable] = {}
    -- 该角色队伍初始的道具

    for i = 1, #_teamList do
        local _thisRole = dataMgr.roleDataMgr:getRoleData(_teamList[i])
        local _roleBagConsume = _thisRole.data.bagContent[_BagContent.Consumable]
        for j = 1, #_roleBagConsume do
            local _itemId = _roleBagConsume[j].modelId
            local _itemNum = _roleBagConsume[j].num
            if self.data.teamBagContent[_BagContent.Consumable][_itemId] == nil then
                self.data.teamBagContent[_BagContent.Consumable][_itemId] = _itemNum
            else
                self.data.teamBagContent[_BagContent.Consumable][_itemId] =
                    self.data.teamBagContent[_BagContent.Consumable][_itemId] + _itemNum
            end
        end
    end
    luaTable(self.data.teamBagContent)
    return self.data.teamBagContent
end

-- 从队伍背包里检测某物数量
function RoleData:getMixBagItemNumberById(itemId)
    self:getMixTeamBag()

    local number = 0
    for i = 1, #self.data.teamBagContent[_BagContent.Consumable] do
        if itemId == self.data.teamBagContent[_BagContent.Consumable][i].modelId then
            number = number + self.data.teamBagContent[_BagContent.Consumable][i].num
        end
    end
    return number
end

-- 排序背包数据
function RoleData:sortBagData(index, equipData, consumeData)
    local showBagData = {}
    local _consume = {}
    local _equipData = {}
    if index == 1 then
        -- 全部
        _equipData = self:openEquipmentSort(equipData) -- 装备

        for i = 1, #consumeData do
            self:consumeStacking(_consume, consumeData[i])
        end
        _consume = self:consumeSort(_consume)
    else -- 经过筛选后的
        if index == 7 then
            -- 展示道具
            for i = 1, #consumeData do
                self:consumeStacking(_consume, consumeData[i])
            end
            _consume = self:consumeSort(_consume)
        else
            -- 展示装备
            local _equipment = self:switchIndexToBagType(index, equipData)
            _equipData = self:openEquipmentSort(_equipment)
        end
    end
    if _consume == nil then
        _consume = {}
    end
    if _equipData == nil then
        _equipData = {}
    end
    for i = 1, #_equipData do -- 装备
        table.insert(showBagData, _equipData[i])
    end
    for i = 1, #_consume do -- 消耗品(道具)
        -- 道具堆叠
        local data = dataMgr.propDataMgr:getPropData(_consume[i].modelId).data
        if data.largeCategory == 1 then
            table.insert(showBagData, i, _consume[i])
        else
            table.insert(showBagData, _consume[i])
        end

    end
    return showBagData
end

-- 道具排序
function RoleData:consumeSort(data)
    local _consume = arrayDeepClone(data)
    table.sort(_consume, function(a, b)
        local _aE = dataMgr.propDataMgr:getPropData(a.modelId).data
        local _bE = dataMgr.propDataMgr:getPropData(b.modelId).data
        if _aE.largeCategory ~= 1 and _bE.largeCategory == 1 then
            return false
        elseif _aE.quality ~= _bE.quality then
            return _aE.quality > _bE.quality
        elseif _aE.id ~= _bE.id then
            return _aE.id < _bE.id
        end
    end)
    return _consume
end

-- 装备排序
function RoleData:openEquipmentSort(data)
    local _equipData = arrayDeepClone(data)
    table.sort(_equipData, function(a, b)
        local _a = a.data
        local _b = b.data
        if _a.equipmentType ~= _b.equipmentType then
            return _a.equipmentType < _b.equipmentType
        elseif _a.quality ~= _b.quality then
            return _a.quality > _b.quality
        elseif _a.id ~= _b.id then
            return _a.id < _b.id
        end
    end)
    return _equipData
end

-- 道具堆叠
function RoleData:consumeStacking(tab, data)
    -- 道具堆叠
    local _consume = arrayDeepClone(data)
    local _consumeData = dataMgr.propDataMgr:getPropData(_consume.modelId).data
    local _stack = _consumeData.stacking -- 当前道具可堆叠数量
    if _stack >= tonumber(_consume.num) then
        table.insert(tab, data)
        return
    end
    local _num1 = math.floor(tonumber(_consume.num) / _stack) -- 当前可堆叠次数
    local _num2 = _consume.num % _stack

    if _num1 + 1 == 1 then
    else
        for i = 1, _num1 do
            _consume.num = _stack
            table.insert(tab, _consume)
        end
    end
    if _num2 > 0 then
        local _data = arrayDeepClone(_consume)
        _data.num = _num2
        table.insert(tab, _data)
    end
end

function RoleData:switchIndexToBagType(index, data)
    if index == 7 then
        -- 展示道具
    else
        -- 展示装备
        local equipment = {}
        for i = 1, #data do
            if data[i].data.equipmentType == index - 1 then
                table.insert(equipment, data[i])
            end
        end
        return equipment
    end
end

-- 初始角色学派学习
function RoleData:defaultSchoolData(cfg)
    if cfg.schoolID == nil then
        cfg.schoolID = {}
    end
    if #cfg.schoolID ~= 0 then
        for i = 1, #cfg.schoolID[1] do
            self:addSchoolData(cfg.schoolID[1][i], true)
        end
    end
end

-- 初始角色天赋数据
function RoleData:defaultTaData(cfg)
    if cfg.talentId == nil then
        cfg.talentId = {}
    end
    if #cfg.talentId ~= 0 then
        for i = 1, #cfg.talentId[1] do
            -- self:addTalentData(cfg.talentId[1][i], 1, true)
        end
    end
end

-- 初始五行数据
function RoleData:defaultWuxing(_cfg)
    local wuxing = {}
    table.insert(wuxing, _cfg.goldCompatibility) -- 金相性
    table.insert(wuxing, _cfg.woodCompatibility) -- 木相性
    table.insert(wuxing, _cfg.soilCompatibility) -- 土相性
    table.insert(wuxing, _cfg.waterCompatibility) -- 水相性
    table.insert(wuxing, _cfg.fireCompatibility) -- 火相性
    self.data.wuxing = wuxing
end

function RoleData:initRolePerrsona()
    -- 计算人格是阳还是阴TODO
    return "阳"
end
-- 装备附加五行值
function RoleData:equipmentWuxingAddition(baseValue, wuxingType)
    for i = 1, #self.data.equipmentList do
        if self.data.equipmentList[i].id ~= nil then
            if wuxingType == 1 then
                baseValue = baseValue + self.data.equipmentList[i].goldCompatibility
            elseif wuxingType == 2 then
                baseValue = baseValue + self.data.equipmentList[i].woodCompatibility
            elseif wuxingType == 3 then
                baseValue = baseValue + self.data.equipmentList[i].soilCompatibility
            elseif wuxingType == 4 then
                baseValue = baseValue + self.data.equipmentList[i].waterCompatibility
            else
                baseValue = baseValue + self.data.equipmentList[i].fireCompatibility
            end
        end
    end
    return baseValue
end
-- 装备附加战斗属性
function RoleData:equipmentAddition(baseValue, battleAttributeType) -- 装备现在只做了影响武器伤害 法器伤害 物理抗性 法术抗性 护甲 打击系数
    if battleAttributeType == _RoleBattleAttribute.weaponAtk then
        if self.data.equipmentList[1].id ~= nil then
            return baseValue + self.data.equipmentList[1].weaponatk
        else
            return baseValue
        end
    elseif battleAttributeType == _RoleBattleAttribute.magicInstrumentAtk then
        if self.data.equipmentList[5].id ~= nil then
            return baseValue + self.data.equipmentList[5].magicInstrumentAtk
        else
            return baseValue
        end
    elseif battleAttributeType == _RoleBattleAttribute.physicalResistance then
        if self.data.equipmentList[3].id ~= nil then
            baseValue = baseValue + self.data.equipmentList[3].physicalResistance
        end
        if self.data.equipmentList[4].id ~= nil then
            baseValue = baseValue + self.data.equipmentList[4].physicalResistance
        end
        return baseValue
    elseif battleAttributeType == _RoleBattleAttribute.magicResistant then
        if self.data.equipmentList[3].id ~= nil then
            baseValue = baseValue + self.data.equipmentList[3].magicResistant
        end
        if self.data.equipmentList[4].id ~= nil then
            baseValue = baseValue + self.data.equipmentList[4].magicResistant
        end
        return baseValue
    elseif battleAttributeType == _RoleBattleAttribute.armor then
        if self.data.equipmentList[3].id ~= nil then
            baseValue = baseValue + self.data.equipmentList[3].armor
        end
        if self.data.equipmentList[4].id ~= nil then
            baseValue = baseValue + self.data.equipmentList[4].armor
        end
        return baseValue
    elseif battleAttributeType == _RoleBattleAttribute.hitCoefficient then
        if self.data.equipmentList[1].id ~= nil then
            baseValue = baseValue + self.data.equipmentList[1].hitCoefficient
        end
        return baseValue
    else
        return baseValue
    end
end

function RoleData:addBagEquipment(equipmentData, isInitial)
    local equipment = {}
    equipment.data = arrayDeepClone(equipmentData)
    self.data.equipmentInstanceId = self.data.equipmentInstanceId + 1
    equipment.instanceId = self.data.equipmentInstanceId
    equipment.type = _BagContent.Equipment
    table.insert(self.data.bagContent[_BagContent.Equipment], equipment)
    if not isInitial and dataMgr.playerData:npcIsTeam(self.data.id) then
        eventMgr:broadcastEvent(_EEventType.AddMessage, {{
            roleId = self.data.id, -- 角色id
            mustShow = true, -- 必须马上展示给玩家
            type = _MessageType.Battalion, -- 消息的类型
            content = "", -- 内容
            id = equipmentData.id,
            number = 1,
            contentType = _MessageContentType.GetEquipment
        }})
    end
    self:refrshSkillIdea()
    self.isDataDirty = true
end

-- 以列表形式一次性加入一些装备or消耗品(无事件推送)
function RoleData:addBagItems(dataList)
    local _hasEquip = false
    for i = 1, #dataList do
        if dataList[i].type == 1 then
            if _hasEquip == false then
                _hasEquip = true
            end
            local equipment = {}
            equipment.data = arrayDeepClone(dataList[i].data)
            self.data.equipmentInstanceId = self.data.equipmentInstanceId + 1
            equipment.instanceId = self.data.equipmentInstanceId
            equipment.type = _BagContent.Equipment
            table.insert(self.data.bagContent[_BagContent.Equipment], equipment)
        elseif dataList[i].type == 2 then
            self:addConsumable(dataList[i].modelId, dataList[i].num, true)
        end
    end
    if _hasEquip then
        self:refrshSkillIdea()
    end
    self.isDataDirty = true
end

-- unitList为是否需要唯一id的标志
function RoleData:addConsumable(id, number, isInitial)
    local isExistence = false
    for i = 1, #self.data.bagContent[_BagContent.Consumable] do
        if self.data.bagContent[_BagContent.Consumable][i].modelId == id then
            isExistence = true
            self.data.bagContent[_BagContent.Consumable][i].num =
                self.data.bagContent[_BagContent.Consumable][i].num + number
            break
        end
    end
    if isExistence == false then
        -- dataMgr.propDataMgr:getPropData(id)
        table.insert(self.data.bagContent[_BagContent.Consumable], {
            modelId = id,
            num = number,
            type = _BagContent.Consumable
        })
    end
    self.isDataDirty = true
    eventMgr:broadcastEvent(_EEventType.GetItem, {{
        itemID = id,
        amount = number
    }})
    if not isInitial then
        if dataMgr.playerData:npcIsTeam(self.data.id) then
            eventMgr:broadcastEvent(_EEventType.AddMessage, {{
                roleId = self.data.id, -- 角色id
                mustShow = true, -- 必须马上展示给玩家
                type = _MessageType.Battalion, -- 消息的类型
                content = "", -- 内容
                id = id,
                number = number,
                contentType = _MessageContentType.GetProp
            }})
        end
    end
    -- local isExistence = false
    -- if unitList == nil then -- 非最基础prop不允许重叠
    --     for i = 1, #self.data.bagContent[_BagContent.Consumable] do
    --         if self.data.bagContent[_BagContent.Consumable][i].modelId == cfgId then
    --             isExistence = true
    --             self.data.bagContent[_BagContent.Consumable][i].num =
    --                 self.data.bagContent[_BagContent.Consumable][i].num + number
    --             break
    --         end
    --     end
    --     if isExistence == false then
    --         table.insert(self.data.bagContent[_BagContent.Consumable], {
    --             modelId = cfgId,
    --             num = number,
    --             type = _BagContent.Consumable
    --         })
    --     end
    --     self.isDataDirty = true
    --     if not isInitial and self.data.id == dataMgr.roleDataMgr.playerId then
    --         eventMgr:broadcastEvent(_EEventType.GetItem, {{
    --             itemID = cfgId,
    --             amount = number
    --         }})
    --         eventMgr:broadcastEvent(_EEventType.AddMessage, {{
    --             roleId = self.data.id, -- 角色id
    --             mustShow = true, -- 必须马上展示给玩家
    --             type = _MessageType.Battalion, -- 消息的类型
    --             content = "", -- 内容
    --             id = cfgId,
    --             number = number,
    --             contentType = _MessageContentType.GetProp
    --         }})
    --     end
    -- else

    --     -- 是唯一物
    --     for i = 1, number do
    --         local _id = cfgId
    --         local _prop = dataMgr.propDataMgr:getPropData(_id)
    --         if _prop~= nil then
    --             _prop:addUseEffectBuff(unitList)
    --         else
    --             local params = {}
    --             params.id = _id
    --             params.unitList = unitList
    --             params.unitId = dataMgr.propDataMgr:spwanUnitProp(params)
    --             _id = params.unitId
    --         end

    --         table.insert(self.data.bagContent[_BagContent.Consumable], {
    --             modelId = _id,
    --             num = 1,
    --             type = _BagContent.Consumable
    --         })

    --         self.isDataDirty = true
    --         if not isInitial and self.data.id == dataMgr.roleDataMgr.playerId then
    --             eventMgr:broadcastEvent(_EEventType.GetItem, {{
    --                 itemID = _id,
    --                 amount = 1
    --             }})
    --             eventMgr:broadcastEvent(_EEventType.AddMessage, {{
    --                 roleId = self.data.id, -- 角色id
    --                 mustShow = true, -- 必须马上展示给玩家
    --                 type = _MessageType.Battalion, -- 消息的类型
    --                 content = "", -- 内容
    --                 id = _id,
    --                 number = 1,
    --                 contentType = _MessageContentType.GetProp
    --             }})
    --         end
    --     end
    -- end
end

function RoleData:changeWeapon(slotIndex, WeaponData, _isInfinite)
    if slotIndex == 1 or slotIndex == 2 then
        self:unloadEquipmentSkill(slotIndex)
    end
    self:clothCharm(slotIndex, true) -- 当前衣物对于角色的魅力值 --先取消上次的魅力
    local lua = EquipmentData.new()
    local _modelId = 0
    lua:equipRole(self.data, slotIndex, WeaponData, _isInfinite)
    self:clothCharm(slotIndex, false) -- 后面计算当前魅力
    if slotIndex == 4 then
        self:changeModelName()
    end
    if slotIndex == 1 or slotIndex == 2 then
        self:refrshSkillIdea()
    end
    self:traitEquipmentEvent()
    self.isDataDirty = true
end

-- 切换装备通知特性
function RoleData:traitEquipmentEvent()
    eventMgr:broadcastEvent(_EEventType.TraitEquipment, {{
        owner = self,
        roleId = self.data.id,
        weapon1Cfg = self:getEquipmentBySlot(_EEquipmentSlot.MainWeapon),
        weapon2Cfg = self:getEquipmentBySlot(_EEquipmentSlot.AlternateWeapon),
        clothingCfg = self:getEquipmentBySlot(_EEquipmentSlot.Clothing),
        armorCfg = self:getEquipmentBySlot(_EEquipmentSlot.Armor)
    }})
end
 --获得技艺经验
function RoleData:addTechniqueExp(index, num, isInitial)
    if not isInitial and self.data.id == dataMgr.roleDataMgr.playerId then
        eventMgr:broadcastEvent(_EEventType.AddMessage, {{
            roleId = self.data.id, -- 角色id
            mustShow = true, -- 必须马上展示给玩家
            type = _MessageType.Battalion, -- 消息的类型
            content = string.format(configMgr:getLanguage(540803 + index), num), -- 内容
            id = index,
            number = num,
            contentType = _MessageContentType.Artistry
        }})
    end
    local skillExperience = configMgr:getPublicData(9).value
    self.data.levelInfo[_EMainAttributesType.Technique][index].exp =
        self.data.levelInfo[_EMainAttributesType.Technique][index].exp + num
    local _nextExp = self:getTechniqueExp(index)[2]
    if self.data.levelInfo[_EMainAttributesType.Technique][index].lv == 5 then
        -- 目前技艺通为5级
    else
        while (self.data.levelInfo[_EMainAttributesType.Technique][index].exp >= _nextExp) do
            self.data.levelInfo[_EMainAttributesType.Technique][index].exp =
                self.data.levelInfo[_EMainAttributesType.Technique][index].exp - _nextExp
            self:upTechniqueLv(index, 1)
            eventMgr:broadcastEvent(_EEventType.AddMessage, {{
                roleId = self.data.id, -- 角色id
                mustShow = true, -- 必须马上展示给玩家
                type = _MessageType.Battalion, -- 消息的类型
                content = string.format(configMgr:getLanguage(518019), configMgr:getLanguage(800071 + index)), -- 内容
                id = index,
                contentType = _MessageContentType.Artistry
            }})
            _nextExp = self:getTechniqueExp(index)[2]
        end
    end

end

function RoleData:refreshAwaken() -- 觉醒具体增加的附加属性定下来后 需要单独存储不能直接加在原属性上
    -- 五行相性
    local _cfg = configMgr:getRoleCfg(self.data.id)
    local wuxing = {}
    table.insert(wuxing, _cfg.goldCompatibility) -- 金相性
    table.insert(wuxing, _cfg.woodCompatibility) -- 木相性
    table.insert(wuxing, _cfg.soilCompatibility) -- 土相性
    table.insert(wuxing, _cfg.waterCompatibility) -- 水相性
    table.insert(wuxing, _cfg.fireCompatibility) -- 火相性
    -- 觉醒附加五行值
    if self.data.awakening.totemId ~= 0 then
        local awakenCfg = configMgr:getAwakenByGroup(self:getAwakenTotem())
        for i = 1, #awakenCfg do
            if self.data.levelInfo[_EMainAttributesType.Wakan].lv >= awakenCfg[i].psychicLevel then
                if self.data.perrsonality.type == _HumanPersonality.Balance then
                    for j = 1, #awakenCfg[i].balance do
                        if awakenCfg[i].balance[j][1] >= 30 and awakenCfg[i].balance[j][1] <= 34 then
                            wuxing[awakenCfg[i].balance[j][1] - 29] =
                                wuxing[awakenCfg[i].balance[j][1] - 29] + awakenCfg[i].balance[j][3]
                        end
                    end
                elseif self.data.perrsonality.type == _HumanPersonality.Yin then
                    for j = 1, #awakenCfg[i].yin do
                        if awakenCfg[i].yin[j][1] >= 30 and awakenCfg[i].yin[j][1] <= 34 then
                            wuxing[awakenCfg[i].yin[j][1] - 29] =
                                wuxing[awakenCfg[i].yin[j][1] - 29] + awakenCfg[i].yin[j][3]
                        end
                    end
                else
                    for j = 1, #awakenCfg[i].yang do
                        if awakenCfg[i].yang[j][1] >= 30 and awakenCfg[i].yang[j][1] <= 34 then
                            wuxing[awakenCfg[i].yang[j][1] - 29] =
                                wuxing[awakenCfg[i].yang[j][1] - 29] + awakenCfg[i].yang[j][3]
                        end
                    end
                end
            end
        end
    end
    self.data.wuxing = wuxing
    -- 其他TODO
end

function RoleData:removeEquipment(slotIndex, isInfinite)
    if slotIndex == 1 or slotIndex == 2 then
        self:unloadEquipmentSkill(slotIndex)
    end
    self:clothCharm(slotIndex, true)
    local lua = EquipmentData.new()
    lua:remove(self.data, slotIndex, isInfinite)
    if slotIndex == 1 or slotIndex == 2 then
        self.data.equipmentList[slotIndex] = getKarateData()
    else
        self.data.equipmentList[slotIndex] = {}
    end

    if slotIndex == 4 then
        self:changeModelName()
    end
    -- if slotIndex == 1 then
    --     if self.data.equipmentList[2].id ~= nil then
    --         self:switchWeapon()
    --     end
    -- end

    self:refrshSkillIdea()
    self.isDataDirty = true
end

-- 清理背包数据（包括配置的武器）
function RoleData:clearBagData()
    for i = 1, 5 do -- 清空配置的武器
        if self.data.equipmentList[i].id ~= nil then
            self:unloadEquipmentSkill(i)
            -- self:removeEquipment(i, false)
            self:clothCharm(i, true)
            -- local lua = EquipmentData.new()
            -- lua:remove(self.data, i)
            if i <= 2 then
                self.data.equipmentList[i] = getKarateData()
            else
                self.data.equipmentList[i] = {}
                if i == 4 then
                    self:changeModelName(true)
                end
            end
        end
    end
    -- 清空背包
    self.data.bagContent[_BagContent.Equipment] = {}
    self.data.bagContent[_BagContent.Consumable] = {}
    for i = 1, #self.data.perrsonality.permanentFeatures do
        CharacterTraitCenter.AddTrait(self, self.data.perrsonality.permanentFeatures[i])
    end
    self.isDataDirty = true
end

function RoleData:discardEquipment(type, indexOrInstanceId, isInfinite) -- type为0已经装备 为1在背包当中 isInfinite是否是仓库传输

    local _id = indexOrInstanceId
    if type == 0 then
        _id = self.data.equipmentList[indexOrInstanceId].id
        self.data.equipmentList[indexOrInstanceId] = {getKarateData()}
        self:clothCharm(indexOrInstanceId, true)
        self:traitEquipmentEvent()
    end
    if type == 1 then
        local lua = EquipmentData.new()
        _id = lua:discard(self.data, indexOrInstanceId)
    end
    if self.data.id == dataMgr.roleDataMgr.playerId then
        if isInfinite ~= nil and isInfinite then
            dataMgr.playerData:addEquipmentToInfiniteBag(_id)
        end
    end
    self:refrshSkillIdea()
    self.isDataDirty = true
end

-- 以列表形式删除一些装备or消耗品(无事件推送)
function RoleData:discardItems(dataList, isInfinite)
    local lua = nil
    local hasEquip = false
    for i = 1, #dataList do
        if dataList[i].type == 1 then
            if lua == nil then
                lua = EquipmentData.new()
            end
            if hasEquip == false then
                hasEquip = true
            end
            lua:discard(self.data, dataList[i].instanceId)
        elseif dataList[i].type == 2 then
            self:discardConsum(dataList[i].modelId, dataList[i].num, isInfinite)
        end
    end
    if hasEquip then
        self:refrshSkillIdea()
    end
    self.isDataDirty = true
end

function RoleData:discardConsum(modelId, number, isInfinite) -- isInfinite是否是仓库传输
    dataMgr.propDataMgr:discardProp(self.data, modelId, number)
    if isInfinite then
        dataMgr.playerData:addConsumableToInfiniteBag(modelId, number)
    end
    self.isDataDirty = true
    if self.data.id == dataMgr.roleDataMgr.playerId then
        eventMgr:broadcastEvent(_EEventType.DiscardedItem, {{
            itemID = modelId,
            amount = number
        }})
    end
end

-- 从队伍整合背包中扣除by具体ID
function RoleData:discardConsumFromTeam(itemId, number)
    local _teamList = self:getteamRecruitmentById()
    table.insert(_teamList, dataMgr.roleDataMgr.playerId)
    for i = 1, #_teamList do
        if number <= 0 then
            break
        end
        local _thisRole = dataMgr.roleDataMgr:getRoleData(_teamList[i])
        local _roleBag = _thisRole.data.bagContent[_BagContent.Consumable]
        local _bagNum = _thisRole:getItemNumberById(itemId)
        local _disNum = (_bagNum - number < 0) and _bagNum or number
        number = number - _bagNum
        _thisRole:discardConsum(itemId, _disNum)
    end
end

-- 从队伍整合背包中扣除by细类ID（subclass）
function RoleData:discardConsumFromTeamBySubclass(sortId, number)
    local _teamList = self:getteamRecruitmentById()
    table.insert(_teamList, dataMgr.roleDataMgr.playerId)
    for i = 1, #_teamList do
        if number <= 0 then
            return
        end
        local _thisRole = dataMgr.roleDataMgr:getRoleData(_teamList[i])
        local _roleBag = _thisRole.data.bagContent[_BagContent.Consumable]
        local _itemList = _thisRole:getItemSort(_EItemSortType.Subclass, sortId, _EItemRangeType.Quality).idList
        for j = 1, #_itemList do
            local _bagNum = _thisRole:getItemNumberById(_itemList[j])
            local _disNum = (_bagNum - number < 0) and _bagNum or number
            number = number - _bagNum
            _thisRole:discardConsum(_itemList[j], _disNum)
            if number <= 0 then
                return
            end
        end
    end
end

function RoleData:giveOtherRoleConsum(modelId, number, roleIndex)
    local roleList = dataMgr.playerData:getRoleList()
    local roleId = roleList[roleIndex]
    local otherRole = dataMgr.roleDataMgr:getRoleData(roleId)
    dataMgr.propDataMgr:giveToOtherRole(self.data, modelId, number, otherRole)
    self.isDataDirty = true
end

function RoleData:useConsum(modelId, number)
    if self.data.id == dataMgr.roleDataMgr.playerId then
        eventMgr:broadcastEvent(_EEventType.DiscardedItem,
            {{ -- 任务判断交互道具数量需要用到的方法，与道具使用逻辑本身不挂钩
                itemID = modelId,
                amount = number
            }})
    end
    dataMgr.propDataMgr:uesConsum(self, modelId, number)
    self.isDataDirty = true
end

function RoleData:giveOtherRoleEquipment(parma) -- isEquipped是否装备 instanceIdOrSlotIndex槽位下标或装备实例化ID roleIndex对象角色下标
    local roleList = dataMgr.playerData:getRoleList()
    local roleId = roleList[parma.roleIndex]
    local otherRole = dataMgr.roleDataMgr:getRoleData(roleId)
    if parma.isEquipped == true then
        otherRole:addBagEquipment(self.data.equipmentList[parma.instanceIdOrSlotIndex])
        self.data.equipmentList[parma.instanceIdOrSlotIndex] = {getKarateData()}
    else
        local lua = EquipmentData.new()
        lua:giveToOtherRole(self.data, parma.instanceIdOrSlotIndex, otherRole)
    end
    self:refrshSkillIdea()
    self.isDataDirty = true
end

-- 精神气三项经验值增加
function RoleData:addSpiritExperienceValue(type, value)
    if value == 0 then
        return
    end
    -- local _value = gameTools.convertNumberToLabelString(value)
    local _value = value
    -- if self.data.id == dataMgr.roleDataMgr.playerId then
    local _content = ""
    if type == _EMainAttributesType.Strength then -- 精
        _content = string.format(configMgr:getLanguage(540801), _value)
    elseif type == _EMainAttributesType.Wisdom then -- 神
        _content = string.format(configMgr:getLanguage(540802), _value)
    else -- 气
        _content = string.format(configMgr:getLanguage(540803), _value)
    end
    eventMgr:broadcastEvent(_EEventType.AddMessage, {{
        roleId = self.data.id, -- 角色id
        mustShow = true, -- 必须马上展示给玩家
        type = _MessageType.Battalion, -- 消息的类型
        content = _content, -- 内容
        contentType = _MessageContentType.Experience
    }})
    -- end

    if type == _EMainAttributesType.Strength then -- 精
        if self.data.levelInfo[_EMainAttributesType.Strength].lv == 100 then -- 100级为满级
            return
        end
        local curStrengthLv = self.data.levelInfo[_EMainAttributesType.Strength].lv
        local curLvCfgData = configMgr:getRoleLevel(1000 + curStrengthLv)
        local nextLvCfgData = configMgr:getRoleLevel(1000 + 1 + curStrengthLv)
        self.data.levelInfo[_EMainAttributesType.Strength].exp =
            self.data.levelInfo[_EMainAttributesType.Strength].exp + value
        while self.data.levelInfo[_EMainAttributesType.Strength].exp >= curLvCfgData.requiredExperience do
            if self.data.levelInfo[_EMainAttributesType.Strength].lv == 100 then -- 100级为满级
                return
            end
            -- 若大于等于则升级
            -- 升级增加属性点
            self:changeAttributePointWrapper(1, nextLvCfgData.bloodEssence)
            self:changeAttributePointWrapper(3, nextLvCfgData.agility)
            self:changeAttributePointWrapper(2, nextLvCfgData.power)
            -- 升级增加天赋点
            self:addTalentPoint(nextLvCfgData.talent)
            -- 升级增加可支配属性点
            self.data.levelInfo[_EMainAttributesType.Strength].assignCredits =
                self.data.levelInfo[_EMainAttributesType.Strength].assignCredits + nextLvCfgData.level
            curStrengthLv = curStrengthLv + 1
            self.data.levelInfo[_EMainAttributesType.Strength].lv = curStrengthLv
            self.data.levelInfo[_EMainAttributesType.Strength].exp =
                self.data.levelInfo[_EMainAttributesType.Strength].exp - curLvCfgData.requiredExperience
            curLvCfgData = configMgr:getRoleLevel(1000 + curStrengthLv)
            nextLvCfgData = configMgr:getRoleLevel(1000 + 1 + curStrengthLv)
        end
    elseif type == _EMainAttributesType.Wisdom then -- 神
        if self.data.levelInfo[_EMainAttributesType.Wisdom].lv == 100 then -- 100级为满级
            return
        end
        local curWisdomLv = self.data.levelInfo[_EMainAttributesType.Wisdom].lv
        local curLvCfgData = configMgr:getRoleLevel(2000 + curWisdomLv)
        local nextLvCfgData = configMgr:getRoleLevel(2000 + 1 + curWisdomLv)
        self.data.levelInfo[_EMainAttributesType.Wisdom].exp =
            self.data.levelInfo[_EMainAttributesType.Wisdom].exp + value
        while self.data.levelInfo[_EMainAttributesType.Wisdom].exp >= curLvCfgData.requiredExperience do
            if self.data.levelInfo[_EMainAttributesType.Wisdom].lv == 100 then -- 100级为满级
                return
            end
            -- 若大于等于则升级
            -- 升级增加属性点
            self:changeAttributePointWrapper(5, nextLvCfgData.politicalStrategy)
            self:changeAttributePointWrapper(6, nextLvCfgData.militaryStrategy)
            self:changeAttributePointWrapper(4, nextLvCfgData.ability)
            -- 升级增加天赋点
            self:addTalentPoint(nextLvCfgData.talent)
            -- 升级增加可支配属性点
            self.data.levelInfo[_EMainAttributesType.Wisdom].assignCredits =
                self.data.levelInfo[_EMainAttributesType.Wisdom].assignCredits + nextLvCfgData.level
            curWisdomLv = curWisdomLv + 1
            self.data.levelInfo[_EMainAttributesType.Wisdom].lv = curWisdomLv
            self.data.levelInfo[_EMainAttributesType.Wisdom].exp =
                self.data.levelInfo[_EMainAttributesType.Wisdom].exp - curLvCfgData.requiredExperience
            curLvCfgData = configMgr:getRoleLevel(2000 + curWisdomLv)
            nextLvCfgData = configMgr:getRoleLevel(2000 + 1 + curWisdomLv)
        end
    else -- 气
        if self.data.levelInfo[_EMainAttributesType.Wakan].lv == 100 then -- 100级为满级
            return
        end
        local curWakanLv = self.data.levelInfo[_EMainAttributesType.Wakan].lv
        local curLvCfgData = configMgr:getRoleLevel(3000 + curWakanLv)
        local nextLvCfgData = configMgr:getRoleLevel(3000 + 1 + curWakanLv)
        self.data.levelInfo[_EMainAttributesType.Wakan].exp =
            self.data.levelInfo[_EMainAttributesType.Wakan].exp + value
        local awakenCfg = {}
        if self.data.awakening.totemId ~= 0 then
            awakenCfg = configMgr:getAwakenByGroup(self.data.awakening.totemId)
        end
        while self.data.levelInfo[_EMainAttributesType.Wakan].exp >= curLvCfgData.requiredExperience do
            if self.data.levelInfo[_EMainAttributesType.Wakan].lv == 100 then -- 100级为满级
                return
            end
            -- 若大于等于则升级
            -- 升级增加属性点
            self:changeAttributePointWrapper(7, nextLvCfgData.airSea)
            self:changeAttributePointWrapper(9, nextLvCfgData.perception)
            self:changeAttributePointWrapper(8, nextLvCfgData.spellDamage)
            -- 升级增加天赋点
            self:addTalentPoint(nextLvCfgData.talent)
            -- 升级增加可支配属性点
            self.data.levelInfo[_EMainAttributesType.Wakan].assignCredits =
                self.data.levelInfo[_EMainAttributesType.Wakan].assignCredits + nextLvCfgData.level
            curWakanLv = curWakanLv + 1
            if self.data.awakening.totemId ~= 0 then
                for i = 1, #awakenCfg do
                    if awakenCfg[i].psychicLevel <= curWakanLv then
                        self:addAwakenSkill(awakenCfg[i].id)
                    end
                end
            end
            self.data.levelInfo[_EMainAttributesType.Wakan].lv = curWakanLv
            self.data.levelInfo[_EMainAttributesType.Wakan].exp =
                self.data.levelInfo[_EMainAttributesType.Wakan].exp - curLvCfgData.requiredExperience
            -- 更新五行值
            -- self:refreshAwaken()
            curLvCfgData = configMgr:getRoleLevel(3000 + curWakanLv)
            nextLvCfgData = configMgr:getRoleLevel(3000 + 1 + curWakanLv)
        end
    end
    self.isDataDirty = true
end

-- 学派点数增加
function RoleData:addSchoolPoint(schoolType, value)
    self.data.schoolOfThought.knowledgeList[tostring(schoolType)] =
        self.data.schoolOfThought.knowledgeList[tostring(schoolType)] + value
    self.isDataDirty = true
end

-- 天赋点数增加
function RoleData:addTalentPoint(value, isInitial)
    -- self.data.talentAlllNum = self.data.talentAlllNum + value
    TalentSystem.AddTalentPoints(self.data.TalentSystem, value)
    if not isInitial then
        eventMgr:broadcastEvent(_EEventType.AddMessage, {{
            roleId = self.data.id, -- 角色id
            mustShow = true, -- 必须马上展示给玩家
            type = _MessageType.Battalion, -- 消息的类型
            content = configMgr:getLanguage(518016), -- 内容
            contentType = _MessageContentType.Talent
        }})
    end
    self.isDataDirty = true
end

-- 判断角色状态是否需要传送回家或者离开队伍
function RoleData:judgeStateOfTheRole()
    local roleList = dataMgr.playerData:getRoleList()
    for i = 1, #roleList do
        if self.data.id == roleList[i] then
            if self.data.roleState[_RoleStateType.healthy].value == 0 -- or  self.data.roleState[_RoleStateType.satiate].value == 0 or self.data.roleState[_RoleStateType.mood].value == 0  目前改成健康变为0传回家
            then
                if self.data.id == dataMgr.roleDataMgr.playerId then
                    -- 主角存在临时特性（现在还没有分负面还是正面临时特性）则被动休息到持续时间最少的特性消失所需要休息的时间
                    -- 若主角不存在临时特性 则回复到三项值（健康、饱食、心情）其中一项回复到满值所需要休息的时间
                    local needRestDay = 0
                    local type = 0 -- 1健康归0 2饱食归0 3心情归0
                    local homeCfgData = configMgr:getResidenceById(dataMgr.playerData:getHomeType())
                    -- 家的基础回复效率 未加家具装饰品的beff
                    if #self.data.perrsonality.temporaryFeatures == 0 then
                        if self.data.roleState[_RoleStateType.mood].value == 0 then
                            needRestDay = math.ceil(configMgr:getPublicData(65).value[1] / homeCfgData.mood)
                        elseif self.data.roleState[_RoleStateType.satiate].value == 0 then
                            needRestDay = math.ceil(configMgr:getPublicData(64).value[1] / homeCfgData.satiety)
                        elseif self.data.roleState[_RoleStateType.healthy].value == 0 then
                            needRestDay = math.ceil(configMgr:getPublicData(63).value[1] / homeCfgData.healthy)
                        end
                    else
                        needRestDay = 999
                        for i = 1, #self.data.perrsonality.temporaryFeatures do
                            if needRestDay > self.data.perrsonality.temporaryFeatures[i].days then
                                needRestDay = self.data.perrsonality.temporaryFeatures[i].days
                            end
                        end
                        needRestDay = math.ceil(needRestDay / homeCfgData.abnormalReplyMulti)
                    end
                    if self.data.roleState[_RoleStateType.mood].value == 0 then
                        type = 3
                    end
                    if self.data.roleState[_RoleStateType.satiate].value == 0 then
                        type = 2
                    end
                    if self.data.roleState[_RoleStateType.healthy].value == 0 then
                        type = 1
                    end
                    eventMgr:broadcastEvent(_EEventType.RoleRestPassived, {{
                        dayNumber = needRestDay,
                        replyType = type
                    }})
                else
                    -- 若其他角色三项任意一项值为0则角色不能进行战斗 不会离开队伍
                end
            end
        end
    end
end

-- 一键补满某角色状态
function RoleData:fillRoleState(stateType)
    self:roleStateChange(true, stateType, self.data.roleState[stateType].maxValue)
    self.isDataDirty = true
    local _str = "<u>" .. self:getRoleName() .. "</u>"
    if stateType == 1 then
        _str = _str .. "恢复了健康"
    elseif stateType == 2 then
        _str = _str .. "填饱了肚子"
    elseif stateType == 3 then
        _str = _str .. "心情大涨"
    end
    eventMgr:broadcastEvent(_EEventType.AddMessage, {{
        roleId = self.data.id, -- 角色id
        mustShow = true, -- 必须马上展示给玩家
        type = _MessageType.Battalion, -- 消息的类型
        content = _str, -- 内容
        contentType = _MessageContentType.RoleStateUnusal
    }})
end

-- 角色状态改变(健康度，饱食度，心情值)
function RoleData:roleStateChange(isAdd, stateType, value)
    -- Gm 指令, 锁定饱食度等状态. 
    if gameDef.IsLockingState then
        return
    end

    local isSendBattalion = false
    local _value = self.data.roleState[stateType].value
    local _maxvaue = self.data.roleState[stateType].maxValue
    local _svalue = self.data.roleState[stateType].value - value
    if isAdd == true then
        self.data.roleState[stateType].value = self.data.roleState[stateType].value + value
        if self.data.roleState[stateType].value > self.data.roleState[stateType].upperLimitValue then
            self.data.roleState[stateType].value = self.data.roleState[stateType].upperLimitValue
        end
    else
        -- 状态值减少
        if _value / _maxvaue >= 1 / 2 and _svalue / _maxvaue < 1 / 2 or _value / _maxvaue >= 1 / 4 and _svalue /
            _maxvaue < 1 / 4 or _value / _maxvaue > 0 and _svalue / _maxvaue == 0 then
            isSendBattalion = true -- 队伍中角色状态不佳
        end

        self.data.roleState[stateType].value = self.data.roleState[stateType].value - value
        if self.data.roleState[stateType].value <= 0 then
            self.data.roleState[stateType].value = 0
        end
    end
    -- 角色生命体力灵力的当前值减少
    if stateType == _RoleStateType.healthy then
        self.data.mainAttributes.hp = math.ceil(self.data.mainAttributes.Maxhp *
                                                    (self.data.roleState[stateType].value /
                                                        self.data.roleState[stateType].maxValue))
    elseif stateType == _RoleStateType.satiate then
        self.data.mainAttributes.physicalStrength = math.ceil(
            self.data.mainAttributes.MaxphysicalStrength *
                (self.data.roleState[stateType].value / self.data.roleState[stateType].maxValue))
    elseif stateType == _RoleStateType.mood then
        self.data.mainAttributes.mp = math.ceil(self.data.mainAttributes.Maxmp *
                                                    (self.data.roleState[stateType].value /
                                                        self.data.roleState[stateType].maxValue))
    end
    local curRoleList = dataMgr.playerData:getRolesInRank()
    for i = 1, #curRoleList do
        if curRoleList[i] == self.data.id then
            eventMgr:broadcastEvent(_EEventType.RoleStateChange)
            if isSendBattalion then
                local _value = _svalue / _maxvaue
                local _str = floatToInt(_svalue / _maxvaue * 100) .. "%"
                local _lanStr = {}
                -- 发送给玩家的提示消息
                if stateType == _RoleStateType.healthy then
                    _lanStr.title = configMgr:getLanguage(518001)
                    if _value <= 1 / 2 then
                        _lanStr.des = configMgr:getLanguage(518022)
                    elseif _value <= 1 / 4 then
                        _lanStr.des = configMgr:getLanguage(518023)
                    end

                    eventMgr:broadcastEvent(_EEventType.AddMessage, {{
                        roleId = self.data.id, -- 角色id
                        mustShow = true, -- 必须马上展示给玩家
                        type = _MessageType.Battalion, -- 消息的类型
                        content = "<u>" .. self:getRoleName() .. "</u>" .. _lanStr.des, -- 内容
                        contentType = _MessageContentType.RoleStateUnusal -- 内容类型
                    }})

                    -- gameTools.openFloatingPopup(self:getRoleName() .. "健康值不足" .. _str)
                elseif stateType == _RoleStateType.satiate then
                    _lanStr.title = configMgr:getLanguage(518002)
                    if _value <= 1 / 2 then
                        _lanStr.des = configMgr:getLanguage(518024)
                    elseif _value <= 1 / 4 then
                        _lanStr.des = configMgr:getLanguage(518025)
                    else
                        _lanStr.des = configMgr:getLanguage(518026)
                    end
                    eventMgr:broadcastEvent(_EEventType.AddMessage, {{
                        roleId = self.data.id, -- 角色id
                        mustShow = true, -- 必须马上展示给玩家
                        type = _MessageType.Battalion, -- 消息的类型
                        content = "<u>" .. self:getRoleName() .. "</u>" .. _lanStr.des, -- 内容
                        contentType = _MessageContentType.RoleStateUnusal -- 内容类型
                    }})

                    -- gameTools.openFloatingPopup(self:getRoleName() .. "饱食值不足" .. _str)
                else
                    _lanStr.title = configMgr:getLanguage(518003)
                    if _value <= 1 / 2 then
                        _lanStr.des = configMgr:getLanguage(518027)
                    elseif _value <= 1 / 4 then
                        _lanStr.des = configMgr:getLanguage(518028)
                    else
                        _lanStr.des = configMgr:getLanguage(518029)
                    end
                    eventMgr:broadcastEvent(_EEventType.AddMessage, {{
                        roleId = self.data.id, -- 角色id
                        mustShow = true, -- 必须马上展示给玩家
                        type = _MessageType.Battalion, -- 消息的类型
                        content = "<u>" .. self:getRoleName() .. "</u>" .. _lanStr.des, -- 内容
                        contentType = _MessageContentType.RoleStateUnusal -- 内容类型
                    }})

                    -- gameTools.openFloatingPopup(self:getRoleName() .. "心情值不足" .. _str)
                end
                -- noticeMgr:playerStateChange(_NoticeEnumType.PlayerStateBadToHome, _lanStr)
            end
        end
    end
    self.isDataDirty = true
    self:judgeStateOfTheRole()
end

-- 战斗结束后角色消耗的血量/体力/灵力反馈到健康/

-- 角色获得属性点AttributeIndex对应globalEnum中的_RoleAttribute
function RoleData:changeAttributePointWrapper(AttributeIndex, value, isReduce)
    if AttributeIndex == 1 then
        -- 体魄
        if isReduce then
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.TiPoAdd, -value)
        else
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.TiPoAdd, value)
        end
    elseif AttributeIndex == 3 then
        -- 敏捷
        if isReduce then
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.MinJieAdd, -value)
        else
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.MinJieAdd, value)
        end
    elseif AttributeIndex == 2 then
        -- 力量
        if isReduce then
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.LiLiangAdd, -value)
        else
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.LiLiangAdd, value)
        end
        -- 力量效果(暂无)
    elseif AttributeIndex == 5 then
        -- 文韬
        if isReduce then
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.WenTaoAdd, -value)
        else
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.WenTaoAdd, value)
        end
        -- 文韬效果(暂无)
    elseif AttributeIndex == 6 then
        -- 武略
        if isReduce then
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.WuLueAdd, -value)
        else
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.WuLueAdd, value)
        end
        -- 武略效果(暂无)
    elseif AttributeIndex == 4 then
        -- 才干
        if isReduce then
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.CaiZhiAdd, -value)
        else
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.CaiZhiAdd, value)
        end
        -- 才干效果(暂无)
    elseif AttributeIndex == 7 then
        if isReduce then
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.QiHaiAdd, -value)
        else
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.QiHaiAdd, value)
        end
    elseif AttributeIndex == 9 then
        -- 感知
        if isReduce then
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.GanZhiAdd, -value)
        else
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.GanZhiAdd, value)
        end
        -- 感知效果(暂无)
    elseif AttributeIndex == 8 then
        -- 灵犀
        if isReduce then
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.LingXiAdd, -value)
        else
            CharacterPropertyCenter.AddPropertyValue(self, CharacterPropertyEnum.LingXiAdd, value)
        end
    end
    self.isDataDirty = true
end
function RoleData:changeAttributePoint(AttributeIndex, value, isReduce)
    if AttributeIndex == 1 then -- 体魄
        local _pubData = configMgr:getRoleAttributeByid(101).talentEffect
        local _value1 = self.data.mainAttributes.Maxhp -- 体力
        local _value2 = self.data.battleAttributes[_RoleBattleAttribute.weight] -- 重量值
        local _value3 = self.data.variedAttributes.temCharacteristicRecoveryRate -- 临时特性恢复速率
        local _num1 = self:getAddNum(_value1, value, _pubData[1][1], not isReduce)
        local _num2 = self:getAddNum(_value2, value, _pubData[2][1], not isReduce)
        local _num3 = self:getAddNum(_value3, value, _pubData[3][1], not isReduce)

        if isReduce then
            self.data.mainAttributes.Maxhp = _value1 - _num1 * _pubData[1][2]
            -- BaiyiTODO. 此处只是临时保证了最小值为1, 但是可能会导致其他问题: 比如 体魄增加时, 最大生命变多. 
            if self.data.mainAttributes.Maxhp < 1 then
                self.data.mainAttributes.Maxhp = 1
            end
            self.data.battleAttributes[_RoleBattleAttribute.weight] = _value2 - _num2 * _pubData[2][2] -- 重量值
            self.data.variedAttributes.temCharacteristicRecoveryRate = _value3 * (1 - _num3 * _pubData[3][2])
        else
            self.data.mainAttributes.Maxhp = _value1 + _num1 * _pubData[1][2]
            self.data.battleAttributes[_RoleBattleAttribute.weight] = _value2 + _num2 * _pubData[2][2] -- 重量值
            self.data.variedAttributes.temCharacteristicRecoveryRate = _value3 * (1 + _num3 * _pubData[3][2])
        end

        self.data.mainAttributes.hp = math.ceil(self.data.roleState[_RoleStateType.healthy].value /
                                                    self.data.roleState[_RoleStateType.healthy].upperLimitValue *
                                                    self.data.mainAttributes.Maxhp)
    elseif AttributeIndex == 3 then -- 敏捷
        local _pubData = configMgr:getRoleAttributeByid(103).talentEffect
        local _value1 = self.data.battleAttributes[_RoleBattleAttribute.attackSpeed] -- 攻击速度
        local _value2 = self.data.battleAttributes[_RoleBattleAttribute.crit] -- 暴击
        local _value3 = self.data.variedAttributes.runAwayRata -- 被俘虏后每日逃跑率
        local _num1 = self:getAddNum(_value1, value, _pubData[1][1], not isReduce)
        local _num2 = self:getAddNum(_value2, value, _pubData[2][1], not isReduce)
        local _num3 = self:getAddNum(_value3, value, _pubData[3][1], not isReduce)
        if isReduce then
            self.data.battleAttributes[_RoleBattleAttribute.attackSpeed] = _value1 * (1 - _num1 * _pubData[1][2])
            self.data.battleAttributes[_RoleBattleAttribute.crit] = _value2 - _num2 * _pubData[2][2]
            self.data.variedAttributes.runAwayRata = _value3 - _num3 * _pubData[3][2]
        else
            self.data.battleAttributes[_RoleBattleAttribute.attackSpeed] = _value1 * (1 + _num1 * _pubData[1][2])
            self.data.battleAttributes[_RoleBattleAttribute.crit] = _value2 + _num2 * _pubData[2][2]
            self.data.variedAttributes.runAwayRata = _value3 + _num3 * _pubData[3][2]
        end

    elseif AttributeIndex == 2 then -- 力量
        local _pubData = configMgr:getRoleAttributeByid(102).talentEffect
        local _value1 = self.data.battleAttributes[_RoleBattleAttribute.weaponAtk] -- 物理伤害
        local _value2 = self.data.battleAttributes[_RoleBattleAttribute.block] -- 格挡
        local _value3 = self.data.backpack -- 背包重量
        local _num1 = self:getAddNum(_value1, value, _pubData[1][1], not isReduce)
        local _num2 = self:getAddNum(_value2, value, _pubData[2][1], not isReduce)
        local _num3 = self:getAddNum(_value3, value, _pubData[3][1], not isReduce)
        if isReduce then
            self.data.battleAttributes[_RoleBattleAttribute.weaponAtk] = math.floor(
                self.data.battleAttributes[_RoleBattleAttribute.weaponAtk] * (1 - _num1 * _pubData[1][2]))
            -- 物理伤害
            self.data.battleAttributes[_RoleBattleAttribute.block] =
                self.data.battleAttributes[_RoleBattleAttribute.block] - _num2 * _pubData[2][2] -- 格挡
            self.data.backpack = self.data.backpack - _num3 * _pubData[3][2] -- 背包重量
        else
            self.data.battleAttributes[_RoleBattleAttribute.weaponAtk] = math.floor(
                self.data.battleAttributes[_RoleBattleAttribute.weaponAtk] * (1 + _num1 * _pubData[1][2]))
            -- 物理伤害
            self.data.battleAttributes[_RoleBattleAttribute.block] = --[[  ]]
                self.data.battleAttributes[_RoleBattleAttribute.block] + _num2 * _pubData[1][2] -- 格挡
            self.data.backpack = self.data.backpack + _num3 * _pubData[3][2] -- 背包重量
        end
        -- 力量效果(暂无)
    elseif AttributeIndex == 5 then -- 文韬
        local _pubData = configMgr:getRoleAttributeByid(302).talentEffect
        local _value1 = self.data.variedAttributes.strategicSuccessRate -- 谋略成功率
        local _value2 = self.data.variedAttributes.defensiveForce -- 队伍单位防御力
        local _value3 = self.data.variedAttributes.teamMoveSpeed -- 队伍在一级场景的移动速率
        local _num1 = self:getAddNum(_value1, value, _pubData[1][1], not isReduce)
        local _num2 = self:getAddNum(_value2, value, _pubData[2][1], not isReduce)
        local _num3 = self:getAddNum(_value3, value, _pubData[3][1], not isReduce)
        if isReduce then
            self.data.variedAttributes.strategicSuccessRate = _value1 * (1 - _num1 * _pubData[1][2])
            self.data.variedAttributes.defensiveForce = _value2 * (1 - _num2 * _pubData[2][2])
            self.data.variedAttributes.teamMoveSpeed = _value3 * (1 - _num3 * _pubData[3][2])
        else
            self.data.variedAttributes.strategicSuccessRate = _value1 * (1 + _num1 * _pubData[1][2])
            self.data.variedAttributes.defensiveForce = _value2 * (1 + _num2 * _pubData[2][2])
            self.data.variedAttributes.teamMoveSpeed = _value3 * (1 + _num3 * _pubData[3][2])
        end
        -- 文韬效果(暂无)
    elseif AttributeIndex == 6 then -- 武略
        local _pubData = configMgr:getRoleAttributeByid(303).talentEffect
        local _value1 = self.data.variedAttributes.strategicEffect -- 谋略的效果
        local _value2 = self.data.variedAttributes.teamFillForce -- 队伍的杀伤能力
        local _value3 = self.data.variedAttributes.teamCarryNum -- 队伍中可以携带的单位数量
        local _num1 = self:getAddNum(_value1, value, _pubData[1][1], not isReduce)
        local _num2 = self:getAddNum(_value2, value, _pubData[2][1], not isReduce)
        local _num3 = self:getAddNum(_value3, value, _pubData[3][1], not isReduce)
        if isReduce then
            self.data.variedAttributes.strategicEffect = _value1 * (1 - _num1 * _pubData[1][2])
            self.data.variedAttributes.teamFillForce = _value2 * (1 - _num2 * _pubData[2][2])
            self.data.variedAttributes.teamCarryNum = _value3 - _num3 * _pubData[3][2]
        else
            self.data.variedAttributes.strategicEffect = _value1 * (1 + _num1 * _pubData[1][2])
            self.data.variedAttributes.teamFillForce = _value2 * (1 + _num2 * _pubData[2][2])
            self.data.variedAttributes.teamCarryNum = _value3 + _num3 * _pubData[3][2]
        end
        -- 武略效果(暂无)
    elseif AttributeIndex == 4 then -- 才干
        local _pubData = configMgr:getRoleAttributeByid(301).talentEffect
        local _value1 = self.data.mainAttributes.Maxmp -- 脑力值
        local _value2 = self.data.variedAttributes.survivalRate -- 己方存活率
        local _value3 = self.data.variedAttributes.teammonthConsume -- 队伍每月消耗
        local _num1 = self:getAddNum(_value1, value, _pubData[1][1], not isReduce)
        local _num2 = self:getAddNum(_value2, value, _pubData[2][1], not isReduce)
        local _num3 = self:getAddNum(_value3, value, _pubData[3][1], not isReduce)
        if isReduce then
            self.data.mainAttributes.Maxmp = _value1 - _num1 * _pubData[1][2]
            self.data.variedAttributes.survivalRate = _value2 * (1 - _num2 * _pubData[2][2])
            self.data.variedAttributes.teammonthConsume = _value3 * (1 - _num3 * _pubData[3][2])
        else
            self.data.mainAttributes.Maxmp = _value1 + _num1 * _pubData[1][2]
            self.data.variedAttributes.survivalRate = _value2 * (1 + _num2 * _pubData[2][2])
            self.data.variedAttributes.teammonthConsume = _value3 * (1 + _num3 * _pubData[3][2])
        end
        self.data.mainAttributes.mp = math.ceil(self.data.roleState[_RoleStateType.mood].value /
                                                    self.data.roleState[_RoleStateType.mood].upperLimitValue *
                                                    self.data.mainAttributes.Maxmp)
        -- 才干效果(暂无)
    elseif AttributeIndex == 7 then
        -- 气海
        local _pubData = configMgr:getRoleAttributeByid(201).talentEffect
        local _value1 = self.data.mainAttributes.MaxphysicalStrength -- 灵力
        local _value2 = self.data.variedAttributes.intensifyRate -- 五行强化效率
        local _value3 = self.data.charm -- 魅力
        local _num1 = self:getAddNum(_value1, value, _pubData[1][1], not isReduce)
        local _num2 = self:getAddNum(_value2, value, _pubData[2][1], not isReduce)
        local _num3 = self:getAddNum(_value3, value, _pubData[3][1], not isReduce)
        if isReduce then
            self.data.mainAttributes.MaxphysicalStrength = _value1 - _num1 * _pubData[1][2]
            self.data.variedAttributes.intensifyRate = _value2 * (1 - _num2 * _pubData[2][2])
            self.data.variedAttributes.intensifyRate = _value2 - _num3 * _pubData[3][2]
        else
            self.data.mainAttributes.MaxphysicalStrength = self.data.mainAttributes.MaxphysicalStrength + _num1 *
                                                               _pubData[1][2]
            self.data.variedAttributes.intensifyRate = _value2 * (1 + _num2 * _pubData[2][2])
            self.data.variedAttributes.intensifyRate = _value2 + _num3 * _pubData[3][2]
        end
        self.data.mainAttributes.physicalStrength = math.ceil(
            self.data.roleState[_RoleStateType.satiate].value /
                self.data.roleState[_RoleStateType.satiate].upperLimitValue *
                self.data.mainAttributes.MaxphysicalStrength)
    elseif AttributeIndex == 9 then -- 感知
        local _pubData = configMgr:getRoleAttributeByid(203).talentEffect
        local _value1 = self.data.variedAttributes.experienceRate -- 战斗经验获取
        local _value2 = self.data.battleAttributes[_RoleBattleAttribute.dodge] -- 闪避 
        local _value3 = self.data.variedAttributes.explorationScope -- 世界地图中信息查看的范围
        local _num1 = self:getAddNum(_value1, value, _pubData[1][1], not isReduce)
        local _num2 = self:getAddNum(_value2, value, _pubData[2][1], not isReduce)
        local _num3 = self:getAddNum(_value3, value, _pubData[3][1], not isReduce)
        if isReduce then
            self.data.variedAttributes.experienceRate = _value1 * (1 - _num1 * _pubData[1][2])
            self.data.battleAttributes[_RoleBattleAttribute.dodge] = _value2 - _num2 * _pubData[2][2]
            self.data.variedAttributes.explorationScope = _value3 * (1 - _num3 * _pubData[3][2])
        else
            self.data.variedAttributes.experienceRate = _value1 * (1 + _num1 * _pubData[1][2])
            self.data.battleAttributes[_RoleBattleAttribute.dodge] = _value2 + _num2 * _pubData[2][2]
            self.data.variedAttributes.explorationScope = _value3 * (1 + _num3 * _pubData[3][2])
        end
        -- 感知效果(暂无)
    elseif AttributeIndex == 8 then -- 灵犀
        local _pubData = configMgr:getRoleAttributeByid(202).talentEffect
        local _value1 = self.data.battleAttributes[_RoleBattleAttribute.magicInstrumentAtk] -- 法器伤害
        local _value2 = self.data.battleAttributes[_RoleBattleAttribute.breakBlock] -- 破防 
        local _value3 = self.data.variedAttributes.baseFortune -- 个人运气
        local _num1 = self:getAddNum(_value1, value, _pubData[1][1], not isReduce)
        local _num2 = self:getAddNum(_value2, value, _pubData[2][1], not isReduce)
        local _num3 = self:getAddNum(_value3, value, _pubData[3][1], not isReduce)
        if isReduce then
            self.data.battleAttributes[_RoleBattleAttribute.magicInstrumentAtk] = _value1 - _num1 * _pubData[1][2]
            self.data.battleAttributes[_RoleBattleAttribute.breakBlock] = _value2 - _num2 * _pubData[2][2]
            self.data.variedAttributes.baseFortune = _value3 - _num3 * _pubData[3][2]
        else
            self.data.battleAttributes[_RoleBattleAttribute.magicInstrumentAtk] = _value1 + _num1 * _pubData[1][2]
            self.data.battleAttributes[_RoleBattleAttribute.breakBlock] = _value2 + _num2 * _pubData[2][2]
            self.data.variedAttributes.baseFortune = _value3 + _num3 * _pubData[3][2]
        end
    end
    self.isDataDirty = true
end

-- 获得当前添加次数
function RoleData:getAddNum(value1, value2, value3, isAdd)
    local _num = 0
    if isAdd then
        for i = value1 + 1, value1 + value2 do
            local _index = i % value3
            if _index == 0 then
                _num = _num + 1
            end
        end
    else
        for i = value1 - 1, value1 + value2, -1 do
            local _index = i % value3
            if _index == 0 then
                _num = _num + 1
            end
        end
    end
    return _num
end

-- 此方法为三项一起加
function RoleData:addAttributePoint(parma, bool)
    local totalUsedPoint = 0
    for i = 1, 3 do
        totalUsedPoint = totalUsedPoint + parma.data[i]
    end
    if parma.type == _EMainAttributesType.Strength then -- 精
        for i = 1, 3 do
            self:changeAttributePointWrapper(i, parma.data[i])
        end
        -- 更新精可分配点数
        self.data.levelInfo[_EMainAttributesType.Strength].assignCredits =
            self.data.levelInfo[_EMainAttributesType.Strength].assignCredits - totalUsedPoint
    elseif parma.type == _EMainAttributesType.Wisdom then -- 神
        for i = 4, 6 do
            self:changeAttributePointWrapper(i, parma.data[i - 3])
        end
        -- 更新神可分配点数
        self.data.levelInfo[_EMainAttributesType.Wisdom].assignCredits =
            self.data.levelInfo[_EMainAttributesType.Wisdom].assignCredits - totalUsedPoint
    else -- 气
        for i = 7, 9 do
            self:changeAttributePointWrapper(i, parma.data[i - 6])
        end
        -- 更新气可分配点数
        self.data.levelInfo[_EMainAttributesType.Wakan].assignCredits =
            self.data.levelInfo[_EMainAttributesType.Wakan].assignCredits - totalUsedPoint
    end
    if bool ~= true then
        self.isDataDirty = true
    end
end

-- type为1拿当前值 为2拿总值 顺序为生命 体力 灵力
function RoleData:getRoleHpPsMp(type)
    local data = {}
    if type == 1 then
        table.insert(data, self.data.mainAttributes.hp)
        table.insert(data, self.data.mainAttributes.physicalStrength)
        table.insert(data, self.data.mainAttributes.mp)
    elseif type == 2 then
        table.insert(data, self.data.mainAttributes.Maxhp)
        table.insert(data, self.data.mainAttributes.MaxphysicalStrength)
        table.insert(data, self.data.mainAttributes.Maxmp)
    end
    return data
end
-- type为1拿当前值 为2拿总值 顺序为健康度 饱食度 心情度
function RoleData:getRoleState(type)
    local data = {}
    if type == 1 then
        table.insert(data, self.data.roleState[_RoleStateType.healthy].value)
        table.insert(data, self.data.roleState[_RoleStateType.satiate].value)
        table.insert(data, self.data.roleState[_RoleStateType.mood].value)
    elseif type == 2 then
        table.insert(data, self.data.roleState[_RoleStateType.healthy].maxValue)
        table.insert(data, self.data.roleState[_RoleStateType.satiate].maxValue)
        table.insert(data, self.data.roleState[_RoleStateType.mood].maxValue)
    end
    return data
end

-- 添加角色经历
function RoleData:addRoleExperience(experienceId, isInit)
    table.insert(self.data.perrsonality.experence, experienceId)
    self:refreshIdeaValueAndType()
    if isInit == false then
        self.isDataDirty = true
    end
end

-- 获得才智影响的报酬支付
function RoleData:getWisdomEffectSalary()
    local _caizhi = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.CaiZhi)
    local _value =
        math.floor(_caizhi / configMgr:getPublicData(156).value[1]) * (configMgr:getPublicData(156).value[2]) / 100 -- 百分比
    return _value
end

function RoleData:onUpdate()
    if self.isDataDirty then
        self:saveData()
        self.isDataDirty = false
    end
end

function RoleData:initIdea()
    local data = {}
    data[_EMainAttributesType.Strength] = {} -- 精理念
    data[_EMainAttributesType.Wakan] = {} -- 气理念
    data[_EMainAttributesType.Wisdom] = {} -- 神理念
    return data
end

function RoleData:defaultIdeaData(cfgData)
    if cfgData.concept == nil then
        cfgData.concept = {}
    end
    if #cfgData.concept ~= 0 then
        for i = 1, #cfgData.concept[1] do
            local conceptData = configMgr:getIdea(cfgData.concept[1][i])
            self:addIdeaSkill({
                type = conceptData.deviation,
                data = conceptData.id
            })
        end
    end
    -- 从理念列表中剔除
    local newTable = {}
    if #cfgData.concept ~= 0 then
        for i = 1, #cfgData.concept[1] do
            local conceptId = configMgr:getIdea(cfgData.concept[1][i]).id
            for j = 1, #self.data.perrsonality.ideaList do
                if self.data.perrsonality.ideaList[j] == conceptId then
                    self.data.perrsonality.ideaList[j] = 0
                end
            end
        end
    end
    for i = 1, #self.data.perrsonality.ideaList do
        if self.data.perrsonality.ideaList[i] ~= 0 then
            table.insert(newTable, self.data.perrsonality.ideaList[i])
        end
    end
    self.data.perrsonality.ideaList = newTable
end

function RoleData:deleteIdeaSkill(parma)
    for k, v in ipairs(self.data.perrsonality.idea[parma.type]) do
        if parma.data == v then
            table.remove(self.data.perrsonality.idea[parma.type], k)
        end
    end
    local _idea = configMgr:getIdea(parma.data)
    TalentEffectProcessor.RemoveTalentEffect(self, _idea.talentEffect)
    self:refreshIdeaValueAndType()
    self:refrshSkillIdea()
    self.isDataDirty = true
end

function RoleData:refreshIdeaValueAndType()
    -- 计算阴阳值
    self.data.perrsonality.yinValue = 0
    self.data.perrsonality.yangValue = 0
    for i = 1, #self.data.perrsonality.experence do
        local curExperienceCfg = configMgr:getExperienceById(self.data.perrsonality.experence[i])
        self.data.perrsonality.yinValue = self.data.perrsonality.yinValue + curExperienceCfg.yinAndYang[2][2]
        self.data.perrsonality.yangValue = self.data.perrsonality.yangValue + curExperienceCfg.yinAndYang[1][2]
    end
    for i = 1, #self.data.perrsonality.idea[_EMainAttributesType.Strength] do -- TODO
        local curIdeaCfg = configMgr:getIdea(self.data.perrsonality.idea[_EMainAttributesType.Strength][i])
        self.data.perrsonality.yinValue = self.data.perrsonality.yinValue + curIdeaCfg.yinAndYang[2][2]
        self.data.perrsonality.yangValue = self.data.perrsonality.yangValue + curIdeaCfg.yinAndYang[1][2]
    end
    for i = 1, #self.data.perrsonality.idea[_EMainAttributesType.Wisdom] do -- TODO
        local curIdeaCfg = configMgr:getIdea(self.data.perrsonality.idea[_EMainAttributesType.Wisdom][i])
        self.data.perrsonality.yinValue = self.data.perrsonality.yinValue + curIdeaCfg.yinAndYang[2][2]
        self.data.perrsonality.yangValue = self.data.perrsonality.yangValue + curIdeaCfg.yinAndYang[1][2]
    end
    for i = 1, #self.data.perrsonality.idea[_EMainAttributesType.Wakan] do -- TODO
        local curIdeaCfg = configMgr:getIdea(self.data.perrsonality.idea[_EMainAttributesType.Wakan][i])
        self.data.perrsonality.yinValue = self.data.perrsonality.yinValue + curIdeaCfg.yinAndYang[2][2]
        self.data.perrsonality.yangValue = self.data.perrsonality.yangValue + curIdeaCfg.yinAndYang[1][2]
    end
    -- 计算人格偏向 公式范围还没有给出来TODO
    local DiffValue = math.abs(self.data.perrsonality.yinValue - self.data.perrsonality.yangValue)
    if DiffValue / self.data.perrsonality.yinValue <= 0.2 and DiffValue / self.data.perrsonality.yangValue <= 0.2 then
        -- if self.data.perrsonality.type ~= 0 and self.data.perrsonality.type ~= _HumanPersonality.Balance and
        --     self.data.id == dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RolepPersonalityChange, _HumanPersonality.Balance)
        -- end
        self.data.perrsonality.type = _HumanPersonality.Balance
    elseif self.data.perrsonality.yinValue > self.data.perrsonality.yangValue then
        -- if self.data.perrsonality.type ~= 0 and self.data.perrsonality.type ~= _HumanPersonality.Yin and self.data.id ==
        --     dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RolepPersonalityChange, _HumanPersonality.Yin)
        -- end
        self.data.perrsonality.type = _HumanPersonality.Yin
    else
        -- if self.data.perrsonality.type ~= 0 and self.data.perrsonality.type ~= _HumanPersonality.Yang and self.data.id ==
        --     dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RolepPersonalityChange, _HumanPersonality.Yang)
        -- end
        self.data.perrsonality.type = _HumanPersonality.Yang
    end
    if self.data.perrsonality.yinValue == 0 and self.data.perrsonality.yangValue == 0 then
        -- if self.data.perrsonality.type ~= 0 and self.data.perrsonality.type ~= _HumanPersonality.Balance and
        --     self.data.id == dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RolepPersonalityChange, _HumanPersonality.Balance)
        -- end
        self.data.perrsonality.type = _HumanPersonality.Balance
    end
    if self.data.perrsonality.yinValue == 0 and self.data.perrsonality.yangValue ~= 0 then
        -- if self.data.perrsonality.type ~= 0 and self.data.perrsonality.type ~= _HumanPersonality.Yang and self.data.id ==
        --     dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RolepPersonalityChange, _HumanPersonality.Yang)
        -- end
        self.data.perrsonality.type = _HumanPersonality.Yang
    end
    if self.data.perrsonality.yinValue ~= 0 and self.data.perrsonality.yangValue == 0 then
        -- if self.data.perrsonality.type ~= 0 and self.data.perrsonality.type ~= _HumanPersonality.Yin and self.data.id ==
        --     dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RolepPersonalityChange, _HumanPersonality.Yin)
        -- end
        self.data.perrsonality.type = _HumanPersonality.Yin
    end
    -- 若气等级满足觉醒条件 更新觉醒附加属性
    -- self:refreshAwaken()
    -- 计算理念偏向
    self.data.perrsonality.ideaValue = {0, 0, 0, 0, 0, 0, 0, 0, 0}
    for i = 1, #self.data.perrsonality.idea[_EMainAttributesType.Strength] do
        local curIdeaCfg = configMgr:getIdea(self.data.perrsonality.idea[_EMainAttributesType.Strength][i])
        self.data.perrsonality.ideaValue[curIdeaCfg.school] =
            self.data.perrsonality.ideaValue[curIdeaCfg.school] + curIdeaCfg.score
    end
    for i = 1, #self.data.perrsonality.idea[_EMainAttributesType.Wisdom] do
        local curIdeaCfg = configMgr:getIdea(self.data.perrsonality.idea[_EMainAttributesType.Wisdom][i])
        self.data.perrsonality.ideaValue[curIdeaCfg.school] =
            self.data.perrsonality.ideaValue[curIdeaCfg.school] + curIdeaCfg.score
    end
    for i = 1, #self.data.perrsonality.idea[_EMainAttributesType.Wakan] do
        local curIdeaCfg = configMgr:getIdea(self.data.perrsonality.idea[_EMainAttributesType.Wakan][i])
        self.data.perrsonality.ideaValue[curIdeaCfg.school] =
            self.data.perrsonality.ideaValue[curIdeaCfg.school] + curIdeaCfg.score
    end
    -- 更新人格界面理念偏向
    local maxValue = math.max(table.unpack(self.data.perrsonality.ideaValue))
    local maxValueCount = 0
    local keyIndex = 0
    for i = 1, #self.data.perrsonality.ideaValue do
        if self.data.perrsonality.ideaValue[i] == maxValue then
            maxValueCount = maxValueCount + 1
            keyIndex = i
        end
    end
    if maxValueCount ~= 1 then
        -- 中庸
        -- if self.data.perrsonality.ideaType ~= 0 and self.data.perrsonality.ideaType ~= _ESchool.Zajia and self.data.id ==
        --     dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RoleIdeaChange, _ESchool.Zajia)
        -- end
        --self.data.perrsonality.ideaType = _ESchool.Zajia
    else
        -- if self.data.perrsonality.ideaType ~= 0 and self.data.perrsonality.ideaType ~= keyIndex and self.data.id ==
        --     dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RoleIdeaChange, keyIndex)
        -- end
        self.data.perrsonality.ideaType = keyIndex
    end
end

function RoleData:replaceIdeaSkill(parma)
    for i = 1, #self.data.perrsonality.idea[parma.type] do
        if self.data.perrsonality.idea[parma.type][i] == parma.oldEquippedID then
            self.data.perrsonality.idea[parma.type][i] = parma.newEquippedID
            local _oldIdea = configMgr:getIdea(parma.oldEquippedID)
            local _newIdea = configMgr:getIdea(parma.newEquippedID)
            TalentEffectProcessor.RemoveTalentEffect(self, _oldIdea.talentEffect)
            TalentEffectProcessor.ApplyTalentEffect(self, _newIdea.talentEffect, nil, {})
            break
        end
    end
    self:refreshIdeaValueAndType()
    self:refrshSkillIdea()
    self.isDataDirty = true
end

function RoleData:addIdeaSkill(parma)
    -- table.insert(self.data.perrsonality.idea[parma.type], parma.data)
    -- self:refreshIdeaValueAndType()
    -- self:refrshSkillIdea()
    -- self.isDataDirty = true
    self:addRoleIdeaSkill(parma.data)
end

-- 添加理念
function RoleData:addRoleIdeaSkill(id)
    local _idea = configMgr:getIdea(id)
    table.insert(self.data.perrsonality.idea[_idea.deviation], id)
    TalentEffectProcessor.ApplyTalentEffect(self, _idea.talentEffect, nil, {})
    self:refreshIdeaValueAndType()
    self:refrshSkillIdea()
    self.isDataDirty = true
end

-- 刷新理念对应技能
function RoleData:refrshSkillIdea()
    local _equipmentList = arrayDeepClone(self.data.equipmentList)
    for j = 1, 2 do
        if _equipmentList[j].id ~= nil then
            if self.data.upgradeSkillList[j] == nil then
                self.data.upgradeSkillList[j] = {0, 0}
            end
            -- local _weaponCfg = configMgr:getEquipmentById(_equipmentList[j].id)
            local key = _equipmentList[j].id
            if isKarateEquipment(self.data.equipmentList[j]) then
                key = j
            end
            if self.data.useSkillList[key] == nil then
                self.data.useSkillList[key] = {}
            end

            for i = 1, 2 do
                local _skillId = 0
                if self.data.useSkillList[key][i] == nil then
                    self.data.useSkillList[key][i] = 0
                end
                local _skillId = self.data.useSkillList[key][i]
                if _skillId == nil then
                    _skillId = 0
                end
                self.data.upgradeSkillList[j][i] = 0
                if _skillId ~= 0 then
                    local _id = CharacterPropertyCenter.GetReplaceSkillId(self, _skillId)
                    if _id == nil then
                        _id = 0
                    end
                    self.data.upgradeSkillList[j][i] = _id
                end
                -- if _skillId ~= 0 and self:ideaState(_skillId) ~= nil then
                --     local _idea = self:ideaState(_skillId)

                --     local _ideaData = configMgr:getIdea(_idea)
                --     if #_ideaData.conceptConflict > 0 then
                --         for h = 1, #_ideaData.conceptConflict do
                --             if _ideaData.conceptConflict[h] == _idea then
                --                 local _id = CharacterPropertyCenter.GetReplaceSkillId(self, _skillId)
                --             end
                --         end
                --     end
                -- end
            end
        else
            self.data.upgradeSkillList[j] = {0, 0}
        end
    end
    self.isDataDirty = true
end

-- 当前技能是否有满足条件的理念
function RoleData:ideaState(skillId)
    local _data = arrayDeepClone(self.data.perrsonality.idea)
    local _skillCfg = configMgr:getSkillById(skillId)
    for k, v in pairs(_data) do
        for i = 1, #v do
            local _ideaData = configMgr:getIdea(v[i])
            if #_ideaData.talentEffect > 0 and _ideaData.talentEffect[1][1] == 3 and
                (_skillCfg.replace[1] == _ideaData.talentEffect[1][2] or _skillCfg.replace[2] ==
                    _ideaData.talentEffect[1][2]) then
                return v[i]
            end
        end
    end
end

-- 获得升级过后的技能
function RoleData:getAccrueSkill(skillId)
    -- local _upgradeSkillList = self.data.upgradeSkillList;
    -- if _upgradeSkillList == nil then
    --     _upgradeSkillList = {{0, 0}, {0, 0}}
    -- end
    -- return _upgradeSkillList
    local _id = CharacterPropertyCenter.GetReplaceSkillId(self, skillId)
    if _id == nil then
        _id = 0
    end
    return _id
end

-- 初始学派学习数据
function RoleData:initSchoolOfThought()
    local _data = {}
    for key, value in pairs(t_schoolSkill) do
        if _data[value.school] == nil then
            _data[value.school] = {}
        end
        _data[value.school][key] = 1
    end
    return _data
end

function RoleData:schoolLockedLV()
    local _data = {}
    for i = 1, 9, 1 do
        _data[i] = 1
    end
    return _data
end

function RoleData:schoolLockedKnowledge()
    local _data = {}
    for i = 1, 9, 1 do
        _data[tostring(i)] = 0
    end
    return _data
end

function RoleData:addOpinionScore(data)
    local _data = configMgr:getIdea(data)
    local opinionscore = _data.opinionscore
    -- luaError("opinionscore[1]=====" .. opinionscore[1])
    for i = 1, #opinionscore do
        if self.data.perrsonality.opinionValue[opinionscore[i][1]] == nil then
            self.data.perrsonality.opinionValue[opinionscore[i][1]] = 0
        end
        self.data.perrsonality.opinionValue[opinionscore[i][1]] =
            self.data.perrsonality.opinionValue[opinionscore[i][1]] + opinionscore[i][2]
    end

    -- for i = 1, #data do
    --     self.data.perrsonality.opinionValue[data[i][1]] =
    --         self.data.perrsonality.opinionValue[data[i][1]] + data[i][2]
    --     self.data.perrsonality.guaxiangopinionValue[_data.diagrams] =
    --         self.data.perrsonality.guaxiangopinionValue[_data.diagrams] + data[i][2]
    -- end
    -- 改变主张
    local maxValue = math.max(table.unpack(self.data.perrsonality.opinionValue))
    local maxValueCount = 0
    local keyIndex = 0
    for i = 1, #self.data.perrsonality.opinionValue do
        if self.data.perrsonality.opinionValue[i] == maxValue then
            maxValueCount = maxValueCount + 1
            keyIndex = i
        end
    end
    if maxValueCount ~= 1 then
        -- 中庸
        -- if self.data.perrsonality.opinionType ~= 0 and self.data.perrsonality.opinionType ~= _HumanOpinion.ZhongYong and
        --     self.data.id == dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RoleOpinionopinion, _HumanOpinion.ZhongYong)
        -- end
        self.data.perrsonality.opinionType = _HumanOpinion.ZhongYong
    else
        -- if self.data.perrsonality.opinionType ~= 0 and self.data.perrsonality.opinionType ~= keyIndex and self.data.id ==
        --     dataMgr.roleDataMgr.playerId then
        --     noticeMgr:roleDataChange(_NoticeEnumType.RoleOpinionopinion, keyIndex)
        -- end
        self.data.perrsonality.opinionType = keyIndex
    end
    self.isDataDirty = true
end

function RoleData:addSchoolData(data, isinit)
    local isExistence = false
    for i = 1, #self.data.schoolOfThought.idList do
        if self.data.schoolOfThought.idList[i] == data then
            isExistence = true
        end
    end
    if isExistence then
        return
    end
    table.insert(self.data.schoolOfThought.idList, data)
    local _data = configMgr:getSchoolSkill(data)
    -- 添加主张点数
    self:addSchoolLocked(data, 2)
    local _id = tonumber(_data.talentType[1][2])
    local _conData = {}
    if _data.talentType[1][1] == 2 then
        -- self:addSkill(_id)
        -- _conData = configMgr:getSkillById(_id)
        return
    else
        self:addOpinionScore(_id)
        self:addAdeaDataById(_id)
        _conData = configMgr:getIdea(_id)
    end
    self:addSchoolPoint(_data.school, _conData.score)
    self.data.schoolOfThought.shcookNum = self.data.schoolOfThought.shcookNum + _conData.score
    self:setLockedLv(_data)
    if isinit == false then
        self.isDataDirty = true
    end
end

-- 添加理念
function RoleData:addAdeaDataById(id)
    table.insert(self.data.perrsonality.ideaList, id)
    self.isDataDirty = true
end

-- 添加解锁槽位
function RoleData:addSchoolLocked(data, type)
    local _data = configMgr:getSchoolSkill(data)
    if self.data.schoolOfThought.lockedList[_data.school] == nil then
        self.data.schoolOfThought.lockedList[_data.school] = {}
        self.data.schoolOfThought.lockedList[_data.school][data] = {}
    else
        if self.data.schoolOfThought.lockedList[_data.school][data] == 2 then
            return
        end
    end
    self.data.schoolOfThought.lockedList[_data.school][data] = type
    self.isDataDirty = true
end

-- 解锁层级
function RoleData:setLockedLv(data)
    local _hierarchy = self.data.schoolOfThought.lockedLv[data.school]
    -- if data.hierarchy >= _hierarchy then
    --     _hierarchy = data.hierarchy
    -- end
    _hierarchy = self:setLockedLv2(data.school, _hierarchy)
    self.data.schoolOfThought.lockedLv[data.school] = _hierarchy
    self.isDataDirty = true
end

--- func desc
---@param school any 学派类型
function RoleData:GetLockedLv(school)
    return self.data.schoolOfThought.lockedLv[school]
end

-- 解锁层级
function RoleData:setLockedLv2(school, hierarchy)
    local _bool = self:hierarchyLocked2(school, hierarchy)
    local _isLock = false
    local _hierarchy = hierarchy
    if _bool then
        for key, value in pairs(t_schoolSkill) do
            if school == value.school and value.hierarchy == hierarchy + 1 then
                local _schoolData = configMgr:getSchoolSkill(key)
                local _hierarchyNeed = _schoolData.hierarchyNeed
                -- luaError("当前级数:" .. _hierarchy .. "升级所需要:" ..
                --              self.data.schoolOfThought.knowledgeList[tostring(school)] .. "/" .. _hierarchyNeed)
                if self.data.schoolOfThought.knowledgeList[tostring(school)] >= _hierarchyNeed then
                    _hierarchy = _hierarchy + 1
                    if _hierarchy >= 7 then
                        _hierarchy = 7
                    end
                    return _hierarchy
                end
            end
        end
    end
    return _hierarchy
end

-- 当前层关键点解锁情况(是否全部解锁)
function RoleData:hierarchyLocked2(school, hierarchy)
    if hierarchy == 1 then
        return true
    end
    local _schlData = {}
    for key, value in pairs(t_schoolSkill) do
        if school == value.school and value.hierarchy == hierarchy then
            table.insert(_schlData, value)
        end
    end
    for i = 1, #_schlData do
        if _schlData[i].core > 0 then
            local _state = self.data.schoolOfThought.lockedList[school][_schlData[i].id]
            if _state ~= 2 then
                return false
            end
        end
    end
    return true
end

-- #region 觉醒
-- 初始角色觉醒数据 --
function RoleData:defaultAwakenAndSkillData(roleCfg)
    -- 若角色为主角 玩家自己选择
    if roleCfg.id == dataMgr.roleDataMgr.playerId then
        return
    end
    local equippedSkillNum = 0
    -- 上技能
    -- if #roleCfg.skillList == nil then
    --     return
    -- end

    -- for i = 1, #roleCfg.skillList do
    --     if equippedSkillNum < 2 then
    --         self:setRoleUseSkill(equippedSkillNum, roleCfg.skillList[i], _EEquipmentSlot.MainWeapon)
    --         equippedSkillNum = equippedSkillNum + 1
    --     end
    -- end

    -- 觉醒
    local _awakenIds = configMgr:getAwakenByCountry(roleCfg.country)
    for i = 1, #_awakenIds do
        if self.data.levelInfo[_EMainAttributesType.Wakan].lv >= _awakenIds[i].psychicLevel then
            table.insert(self.data.awakening.table, _awakenIds[i])
            self.data.awakening.level = self.data.awakening.level + 1
        end
    end
    if #_awakenIds ~= 0 then
        self.data.awakening.totemId = _awakenIds[1].groupId
    end
end

function RoleData:addAwakenSkill(awakenSkillId)
    for i = 1, #self.data.awakening.table do
        if self.data.awakening.table[i] == awakenSkillId then
            return
        end
    end
    table.insert(self.data.awakening.table, awakenSkillId)
    self.isDataDirty = true
end

function RoleData:getAwakenTotem()
    return self.data.awakening.totemId
end

function RoleData:getSchoolKnowledge()
    local _count = 0
    for k, v in pairs(self.data.schoolOfThought.knowledgeList) do
        _count = _count + v
    end
    return _count
end

---comment
---@param type any 1-9:学派类型
function RoleData:getSchoolKnowledgeByType(type)
    if self.data.schoolOfThought.knowledgeList[tostring(type)] == nil then
        self.data.schoolOfThought.knowledgeList[tostring(type)] = 0
    end
    return self.data.schoolOfThought.knowledgeList[tostring(type)]
end

-- 特性替换（只是存在于高等级替换低等级）
function RoleData:changePermanentFeatures(id, isNeedSave)
    -- local _charData = configMgr:getFeatureById(id)
    -- if self.data.id == dataMgr.roleDataMgr.playerId then
    --    -- noticeMgr:roleDataChange(_NoticeEnumType.GetCharacteristic, id)
    -- end
    -- if _charData.replacementId == 0 then -- 没有高等级
    --    table.insert(self.data.perrsonality.permanentFeatures, id)
    --    return
    -- end
    -- for i = 1, #self.data.perrsonality.permanentFeatures do
    --    local _id = self.data.perrsonality.permanentFeatures[i]
    --    local _preData = configMgr:getFeatureById(_id)
    --    if _preData.replacementId ~= 0 and _preData.replacementId == _charData.replacementId and _charData.level >
    --        _preData.level then -- 高等级的替换低等级
    --        self.data.perrsonality.permanentFeatures[i] = id
    --        return
    --    end
    -- end
    -- table.insert(self.data.perrsonality.permanentFeatures, id)
    -- if isNeedSave then
    --    self.isDataDirty = true
    -- end

    CharacterTraitCenter.AddTrait(self, id)
end

-- 技能
function RoleData:setRoleUseSkill(slotId, skillId, equipType)
    self:setUseSkill(slotId, skillId, equipType)
    self:refrshSkillIdea()
end

function RoleData:unloadRoleSkill(slotId, equipType)
    self:unloadSkill(slotId, equipType)
    self:refrshSkillIdea()
end

-- 卸载武器需要卸载武器配置的技能
function RoleData:unloadEquipmentSkill(slot)
    local _id = self.data.equipmentList[slot].id
    if _id == nil then
        luaError("当前装备初始数据应为拳头数据")
        return
    end
    local key = _id
    if isKarateEquipment(self.data.equipmentList[slot]) then
        key = slot
    end
    if self.data.useSkillList[key] == nil then
        self.data.useSkillList[key] = {0, 0}
    end
    if _id ~= nil then
        for i = 1, 2 do
            local _skillId = self.data.useSkillList[key][i]
            if _skillId ~= nil and _skillId ~= 0 then
                for j = 1, #self.data.skillList do
                    if self.data.skillList[j].id == _skillId then
                        self.data.skillList[j].isUse = 0
                        break
                    end
                end
            end
            self.data.useSkillList[key][i] = 0
        end
        self:refrshSkillIdea()
    end
end

-- 学派对于研究效率加成
function RoleData:getResearchadditionBySchool(type)
    local _allNumData = {}
    local _numData = {}
    local _allNum = 0
    local _addition = 0
    for k, v in pairs(self.data.schoolOfThought.lockedList) do
        _allNumData[k] = {}
        for key, value in pairs(v) do

            if value == 2 then -- 已经解锁
                local _schoolData = configMgr:getSchoolSkill(key)
                local _hie = _schoolData.hierarchy
                if _allNumData[k][_hie] == nil then
                    _allNumData[k][_hie] = {}
                end
                table.insert(_allNumData[k][_hie], _hie)
            end
        end
    end
    for k, v in pairs(_allNumData) do
        _numData[k] = 0
        for key, value in pairs(v) do
            _numData[k] = _numData[k] + key * #value
        end
        _allNum = _allNum + _numData[k]
    end
    --  luaError("type===="..type)
    --  luaError("_allNum====".._allNum)
    --  luaTable(_numData)
    if _allNum == 0 then -- 避免出现0报错
        return 0
    end
    return _numData[type] / _allNum * 0.5 * 100
end

-- 角色部件属性
function RoleData:reloadingRoleInfo(cfg)
    local _data = {}
    local _clothData = {}
    for k, v in pairs(configMgr:getAllChangeClothes()) do
        if cfg.gender == v.gender and v.roll == 1 then -- 男
            if _clothData[v.category] == nil then
                _clothData[v.category] = {}
                table.insert(_clothData[v.category], 0)
            end
            table.insert(_clothData[v.category], k)
        end
    end

    if #cfg.changeClothes == 0 then
        _data["hair"] = self:getClothIdByData(_clothData[1]) -- 发型
        _data["faceshape"] = self:getClothIdByData(_clothData[2]) -- 脸型
        _data["ear"] = self:getClothIdByData(_clothData[7]) -- 耳朵
        _data["eyebrow"] = self:getClothIdByData(_clothData[4]) -- 眉毛
        _data["eye"] = self:getClothIdByData(_clothData[3]) -- 眼睛
        _data["mouth"] = self:getClothIdByData(_clothData[6]) -- 嘴巴
        _data["nose"] = self:getClothIdByData(_clothData[5]) -- 鼻子
        _data["features"] = self:getClothIdByData(_clothData[9]) -- 特征
        _data["Beard"] = self:getClothIdByData(_clothData[8]) -- 胡子
        _data["rouge"] = self:getClothIdByData(_clothData[10]) -- 腮红
    else
        _data["hair"] = cfg.changeClothes[1] -- 发型
        _data["faceshape"] = cfg.changeClothes[2] -- 脸型
        _data["ear"] = cfg.changeClothes[7] -- 耳朵
        _data["eyebrow"] = cfg.changeClothes[4] -- 眉毛
        _data["eye"] = cfg.changeClothes[3] -- 眼睛
        _data["mouth"] = cfg.changeClothes[6] -- 嘴巴
        _data["nose"] = cfg.changeClothes[5] -- 鼻子
        _data["features"] = cfg.changeClothes[9] -- 特征
        _data["Beard"] = cfg.gender == 1 and cfg.changeClothes[8] or 0 -- 胡子
        _data["rouge"] = cfg.gender == 2 and cfg.changeClothes[10] or 0 -- 腮红
    end

    return _data
end

function RoleData:getClothIdByData(data)
    if data == nil then
        return 0
    end
    return data[math.random(1, #data)]
end

-- 其他需要切换的部件信息
function RoleData:modelSlot()
    local _data = {}
    _data["equipment"] = "hammer1101_shou"
end

---@param type any 面部类型
---@param data any 类型对应数据
function RoleData:setroleInfo(type, data)
    self.data.faceData[type] = data
end

function RoleData:setRoleData(data)
    self.data.faceData = data
    self.isDataDirty = true
end

-- 初始所有角色好感度（根据配置表获取初始值）
function RoleData:initSatisfaction(default, cfg)
    local _data = {}
    for i = 1, #cfg.InteractionRelationship do
        _data[cfg.InteractionRelationship[i][1]] = configMgr:getRelationInterval(cfg.InteractionRelationship[i][2])[1]
    end
    return _data
end

-- 获取所有角色的好感度
function RoleData:getAllRoleFavorability()
    return self.data.roleSatisfaction
end

-- 当前角色对该id角色的好感度
function RoleData:getFavorabilityToOthers(id)
    if self.data.roleSatisfaction == nil then
        self.data.roleSatisfaction = {}
    end
    if self.data.roleSatisfaction[id] == nil then
        local commonFavorableValue = configMgr:getPublicData(28).value[1]
        self.data.roleSatisfaction[id] = tonumber(commonFavorableValue)
        self.isDataDirty = true
    end
    return self.data.roleSatisfaction[id]
end

-- 设置当前角色最新好感度 isIncrease 是否是增加
function RoleData:changeFavorabilityToOthers(id, num, isIncrease, isNeedSendEvent)
    self:getFavorabilityToOthers(id) -- 方便第一次交互时初始一下好感度
    num = self:influenceModifyCharm(num, isIncrease)
    if isIncrease then
        self.data.roleSatisfaction[id] = self.data.roleSatisfaction[id] + num
        if self.data.roleSatisfaction[id] > configMgr:getRelationInterval(_ERolesRelationType.BosomFriend)[2] then
            self.data.roleSatisfaction[id] = configMgr:getRelationInterval(_ERolesRelationType.BosomFriend)[2]
        end
    else
        self.data.roleSatisfaction[id] = self.data.roleSatisfaction[id] - num
        if self.data.roleSatisfaction[id] < configMgr:getRelationInterval(_ERolesRelationType.Hatred)[1] then
            self.data.roleSatisfaction[id] = configMgr:getRelationInterval(_ERolesRelationType.Hatred)[1]
        end
    end
    if isNeedSendEvent then
        eventMgr:broadcastEvent(_EEventType.RoleFavorateChange)
        -- 当前角色的好感度降到一定数值剔除队伍
        local favoriateLevel = configMgr:getFavorabilityLevel(self.data.roleSatisfaction[id])
        if favoriateLevel == _ERolesFavoriteType.Hate then
            local _team = self.data.teamRecruitment
            if _team[id] ~= nil then
                self:removeRoleByTeam(id)
            end
        end
    end
    self.isDataDirty = true
end

-- 好感度改变时，其他数据会影响改变值(后续影响好感度改变值都需要这里处理)
---@param value 待修改值 isIncrease 是否是增加
function RoleData:influenceModifyCharm(value, isIncrease)
    local _value = value
    local _charm = GetCharmType(self:getCharm()) -- 魅力值影响好感度的改变值
    local _pubId = 147
    if _charm == _ECharmType.Hated then
        _pubId = 144
    elseif _charm == _ECharmType.Despised then
        _pubId = 145
    elseif _charm == _ECharmType.Shabby then
        _pubId = 146
    elseif _charm == _ECharmType.Common then
        _pubId = 147
    elseif _charm == _ECharmType.Imposing then
        _pubId = 148
    elseif _charm == _ECharmType.Handsome then
        _pubId = 149
    end
    local _influence = configMgr:getPublicData(_pubId).value
    local _num = isIncrease == true and _influence[1] or _influence[2]
    _value = _value * (1 + _num)
    return _value
end

-- 设置魅力值
function RoleData:setCharm(num)
    self.data.charm = num
    self.isDataDirty = true
end

-- 衣物对魅力值的影响
---@param slotIndex 武器槽位 isRemove 是否还原衣物带来的魅力改变
function RoleData:clothCharm(slotIndex, isRemove)
    local id = self.data.equipmentList[slotIndex].id
    if slotIndex ~= 4 or id == nil then
        return
    end
    local _equip = configMgr:getEquipmentById(id)
    -- 当前衣物对于角色的魅力值
    local _glamour = _equip.glamour
    if _glamour == 0 then
        return
    end
    self:modifyCharm(not isRemove, _glamour) -- 减掉之前衣物带来的魅力值
end

-- 修改魅力值
function RoleData:modifyCharm(isAdd, value)
    local charmPublicCfg = configMgr:getPublicData(81).value
    if isAdd then
        self.data.charm = self.data.charm + value
        if self.data.charm > charmPublicCfg[7] then
            self.data.charm = charmPublicCfg[7]
        end
    else
        self.data.charm = self.data.charm - value
        if self.data.charm < charmPublicCfg[1] then
            self.data.charm = charmPublicCfg[1]
        end
    end
    self.isDataDirty = true
end

-- 获取魅力值
function RoleData:getCharm()
    return self.data.charm
end

-- #endregion

function RoleData:getCountry()
    return self.data.country
end

-- 更新当前角色的工作状态
function RoleData:setRolePostState(value)
    self.data.stateType = value
    self.isDataDirty = true
end

-- 获取当前角色工作状态
function RoleData:getRolePostState()
    return self.data.stateType
end

function RoleData:dispatchAssignment(assignmentId)
    local _cfg = configMgr:getAssignment(assignmentId)
    self.data.assignment = {}
    self.data.assignment.id = assignmentId
    self.isDataDirty = true
end

-- 添加势力角色声望
---@param id 刷新npcid
---@param factionId 势力id
function RoleData:addFactionPopularity(factionId)
    local needSaveData = false
    if self.data.factionReputation[factionId] == nil then
        -- 所有普通角色都走这一套逻辑 特殊角色配表来修改对应势力中的声望
        -- 统一逻辑
        if factionId == 0 then
            return
        end
        local factionCfg = configMgr:getFactionById(factionId)
        self.data.factionReputation[factionId] = factionCfg.Initialreputation
        -- 表格当中特殊的处理
        needSaveData = true
    end
    if needSaveData then
        self.isDataDirty = true
    end
end

-- 根据id获取声望
---@param id 刷新npcid
---@param factionId 势力id
function RoleData:getFactionPopularityByid(factionId)
    -- self:addFactionPopularity(factionId)
    if self.data.factionReputation[factionId] == nil then
        self:addFactionPopularity(factionId)
    end
    return self.data.factionReputation[factionId]
end

-- 修改势力对应角色或者npc的声望值
---@param factionId 势力中的ID
---@param num 修改的值 正负值都可以 正值加 负值减
function RoleData:changeFactionPopularity(factionId, num)
    local factionCfg = configMgr:getFactionById(factionId)
    if self.data.factionReputation[factionId] == nil then
        self:addFactionPopularity(factionId)
    end
    if self.data.factionReputation[factionId] <= 0 then
        return
    end
    local _num = self.data.factionReputation[factionId] + num

    if _num >= factionCfg.reputationNum[5][3] then
        _num = factionCfg.reputationNum[5][3]
    end
    if _num < 0 then
        self.data.factionReputation[factionId] = 0
    else
        self.data.factionReputation[factionId] = _num
    end
    -- luaError("factionId====="..factionId)
    -- luaError("self.data.factionReputation[factionId]======"..self.data.factionReputation[factionId])
    eventMgr:broadcastEvent(_EEventType.ChangeFactionPopularity, {{
        factionId = self.data.organizationId,
        roleId = self.data.id,
        value = num,
        type = 1
    }})

    local _str = ""
    if num > 0 then
        _str = string.format(configMgr:getLanguage(518048), configMgr:getLanguage(factionCfg.name), num)
    else
        _str = string.format(configMgr:getLanguage(518047), configMgr:getLanguage(factionCfg.name), num)
    end
    eventMgr:broadcastEvent(_EEventType.AddMessage, {{
        roleId = self.data.id, -- 角色id
        mustShow = true, -- 必须马上展示给玩家
        type = _MessageType.Influence, -- 消息的类型
        content = _str, -- 内容
        factionId = factionId,
        num = num,
        contentType = _MessageContentType.FactionPopularity
    }})

    self.isDataDirty = true
end

-- 获取当前角色的所有势力下的声望
function RoleData:getFactionPopularity()
    return self.data.factionReputation
end

-- 获取势力
function RoleData:getFaction()
    return self.data.organizationId
end

-- 获取姓
function RoleData:getSurname()
    return self.data.surname
end

-- 获取氏
function RoleData:getFamilyName()
    return self.data.familyName
end

-- 获取性别
function RoleData:getGender()
    return self.data.gender
end

-- 获取身份
function RoleData:getIdentity()
    return self.data.identity
end

function RoleData:setIdentity(identity, isInit)
    self.data.identity = identity
    if self.data.id == dataMgr.roleDataMgr.playerId then
        if identity == _EIdentity.Wang then
            homeMgr.playerHomeSceneId = _EHomeSceneID.FuDi -- 测试 应该是GongDian
        elseif identity <= _EIdentity.Jun then
            homeMgr.playerHomeSceneId = _EHomeSceneID.FuDi
        elseif identity <= _EIdentity.ShiRen then
            homeMgr.playerHomeSceneId = _EHomeSceneID.jiaZhai
        elseif identity <= _EIdentity.PuRen then
            homeMgr.playerHomeSceneId = _EHomeSceneID.CaoWu
        elseif identity == _EIdentity.NuLi then
            homeMgr.playerHomeSceneId = _EHomeSceneID.ChaiFang
        end
    end
    if not isInit then
        self.isDataDirty = true
    end
end

-- 获取工资
function RoleData:getSalary()
    return self.data.salary
end

function RoleData:setSalary(value)
    self.data.salary = value
end

function RoleData:dispatchAssignment(id)
    self.data.assignment.id = id
end

function RoleData:getAssignment()
    return self.data.assignment
end

-- 获取特性
function RoleData:getPermanentFeatures()
    return self.data.perrsonality.permanentFeatures
end

-- 获取学派
function RoleData:getSchoolSkill()
    return self.data.schoolOfThought
end

-- 获取人格
function RoleData:getPerrsonality()
    return self.data.perrsonality
end

function RoleData:addBehaviorLog(info)
    table.insert(self.data.behaviorLog, info)
    self.isDataDirty = true
end

function RoleData:getBehaviorLog()
    return self.data.behaviorLog
end

-- 获取穿戴中的装备
function RoleData:getWearingEquipment()
    return self.data.equipmentList
end

-- 获取英雄主张
function RoleData:getOpinionType()
    return self.data.perrsonality.opinionType
end

-- 设置角色所在地
function RoleData:setPositionId(cityId)
    self.data.positionId = cityId
    self.isDataDirty = true
end

function RoleData:getPositionId()
    return self.data.positionId
end

-- 是否可以跑
function RoleData:modifyNoRunning(bool)
    self.data.noRunning = bool
    if self.id == dataMgr.roleDataMgr.playerId and bool == false then -- 当前是主角
        dataMgr.playerData:setPlayerMoveType(_EFsmStateType.Walk)
    end
    self.isDataDirty = true
end
-- 设置月例
function RoleData:setMonthInterEvent(type)
    if self.data.mouthInterEvents == nil then
        self.data.mouthInterEvents = {}
    end
    self.data.mouthInterEvents[type] = true
    self.isDataDirty = true
end

function RoleData:getMonthInterEvent(type)
    if self.data.mouthInterEvents == nil then
        self.data.mouthInterEvents = {}
        self.data.mouthInterEvents[type] = false
    end
    if self.data.mouthInterEvents[type] == nil then
        self.data.mouthInterEvents[type] = false
    end
    return self.data.mouthInterEvents[type]
end

-- 与玩家初次交流
function RoleData:setFirstMeet()
    self.data.firstMeet = true
end

-- 是否与玩家交流过
function RoleData:getFirstMeet()
    return self.data.firstMeet
end

-- 跟新解锁的锻造图谱
function RoleData:refreshForgeFormula()
    self.data.unlockForgeFormula = {}
    local _lv = self.data.levelInfo[_EMainAttributesType.Technique][_ETechniqueType.Forge].lv
    local _data = configMgr:getForgeFormula()

    local _list = {}
    for k, v in pairs(_data) do
        if v.unlock <= _lv and v.display == 1 then
            table.insert(_list, tonumber(v.id))
        end
    end
    -- 对data进行排序
    table.sort(_list)
    self.data.unlockForgeFormula = _list
end

-- 获得已解锁的锻造图谱
function RoleData:getRoleForgeFormula()
    return self.data.unlockForgeFormula
end

-- 跟新解锁的庖厨图谱
function RoleData:refreshCookFormula()
    self.data.unlockCookFormula = {}
    local _lv = self.data.levelInfo[_EMainAttributesType.Technique][_ETechniqueType.Cook].lv
    local _data = configMgr:getCookFormula()

    local _list = {}
    for k, v in pairs(_data) do
        if v.unlock <= _lv and v.display == 1 then
            table.insert(_list, tonumber(v.id))
        end
    end
    -- 对data进行排序
    table.sort(_list)
    self.data.unlockCookFormula = _list
end

-- 获得已解锁的庖厨图谱
function RoleData:getRoleCookFormula()
    return self.data.unlockCookFormula
end

-- 跟新解锁医术图谱
function RoleData:refreshMedicalFormula()
    self.data.unlockMedicalFormula = {}
    local _lv = self.data.levelInfo[_EMainAttributesType.Technique][_ETechniqueType.Medical].lv
    local _data = configMgr:getMedicalFormula()

    local _list = {}
    for k, v in pairs(_data) do
        if v.unlock <= _lv and v.display == 1 then
            table.insert(_list, tonumber(v.id))
        end
    end
    -- 对data进行排序
    table.sort(_list)
    self.data.unlockMedicalFormula = _list
end

-- 获得已解锁的医术图谱
function RoleData:getRoleMedicalFormula()
    return self.data.unlockMedicalFormula
end

-- 获得年纪名称
function RoleData:getBracketName()
    return self.data.ageBracket
end

-- 更新年纪名字
function RoleData:refreshRoleAgeBracketName()
    local _arg = {}
    _arg.gender = self.data.gender
    _arg.age = self.data.age
    _arg.category = self.data.category
    local _cfg = configMgr:getAgeBracket(_arg)
    if _cfg ~= nil then
        self.data.ageBracket = configMgr:getLanguage(_cfg.age)
    end
end

function RoleData:roleGrow(num)
    self.data.age = self.data.age + num
    self:refreshRoleAgeBracketName()
end

-- todo根据身份获得所在区域
function RoleData:getHomeZoneByIdentity(cfg)
    local _arg = {}
    _arg.zone = {}
    _arg.buildId = 900101 -- 建筑资源配置表
    _arg.homeType = _EDomicileType.Homes
    _arg.zone.idType = _EHomeZoneIDType.ZoningBuilding -- 区划模板表
    _arg.zone.id = 0
    return _arg
end

-- 获取当前住所数据
function RoleData:getCurHomeData()
    return self.data.homeData[#self.data.homeData]
end

-- 检查此city的客栈是否为玩家租住的客房
function RoleData:checkIsRoleTempTavern(cityId)
    luaTable(self.data.tempTavern)
    for i = 1, #self.data.tempTavern do
        if self.data.tempTavern[i].cityId == cityId then
            return true
        end
    end
    return false
end

-- 添加临时住所
function RoleData:addTempTavern(cityId, day)
    for i = 1, #self.data.tempTavern do
        if self.data.tempTavern[i].cityId == cityId then
            self.data.tempTavern[i].day = day + self.data.tempTavern[i].day
            return
        end
    end
    local _arg = {}
    _arg.cityId = cityId
    _arg.day = day
    table.insert(self.data.tempTavern, _arg)
    luaTable(self.data.tempTavern)
end

-- 移除临时住所
function RoleData:discardTempTavern(cityId)
    for i = 1, #self.data.tempTavern do
        if self.data.tempTavern[i].cityId == cityId then
            table.remove(self.data.tempTavern, i)
            return
        end
    end
end

-- 临时住所每日事件
function RoleData:tempTavernDataChage()
    if self.data.tempTavern == nil or #self.data.tempTavern <= 0 then
        return
    end
    luaTable(self.data.tempTavern)
    for i = 1, #self.data.tempTavern do
        self.data.tempTavern[i].day = self.data.tempTavern[i].day - 1
        if self.data.tempTavern[i].day <= 0 then
            local _cityId = self.data.tempTavern[i].cityId
            self:discardTempTavern(_cityId)
        end
    end
end

-- 每日事件
function RoleData:onPassedDay()
    self:tempTavernDataChage()
end
