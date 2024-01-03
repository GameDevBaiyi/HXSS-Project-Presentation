require "game/gameData/dataBase"
---@class AttributeDataBase:DataBase
AttributeDataBase = Class(DataBase)
function AttributeDataBase:cotr()
    self.isDataDirty = false
end
function AttributeDataBase:base_defaultData(cfg)
    local _default = {}
    _default.id = cfg.id
    _default.levelInfo = {} -- 等级
    _default.mainAttributes = {} -- 主属性
    _default.variedAttributes = {} -- 杂属性
    _default.battleAttributes = {} -- 战斗属性
    _default.skillList = {} -- 学会的技能列表
    _default.useSkillList = {} -- 使用中的技能
    _default.upgradeSkillList = {} -- 升级过后的技能

    _default.modelId = cfg.modelId
    _default.wuxing = {}
    _default.backpack = cfg.backpack
    -- region 角色状态（健康、饱食、心情）
    _default.roleState = {}
    -- #endregion
    -- 1:主武器
    -- 2:副武器
    -- 3:盔甲
    -- 4:衣物
    -- 5:法器
    -- 6:坐骑
    _default.equipmentList = { 1, 2, 3, 4, 5 } -- 装备列表
    _default.talentAlllNum = 0 ---总获取天赋点
    _default.wuxing = self:InitWuxing(cfg)
    self:initLevelInfo(_default.levelInfo, cfg)
    self:initMainAttributes(_default.mainAttributes, cfg)
    self:initvariedtAttributes(_default.variedAttributes, cfg)
    self:initBattleAttributes(_default.battleAttributes, cfg)
    self:initEquipment(_default.equipmentList, cfg)
    self:initRoleState(_default.roleState)

    -- 队伍数据
    _default.joinTeamID = 0 -- 雇主id
    _default.teamRecruitment = self:initTeamRecruitment(cfg)
    _default.teamFollower = {} -- 扈从
    return _default
end

function AttributeDataBase:initRoleState(roleState)
    -- 当前血量通过 当前值/最大值 普通回复的限制看上限值
    roleState[_RoleStateType.healthy] = {} -- 健康
    roleState[_RoleStateType.healthy].maxValue = 100
    roleState[_RoleStateType.healthy].value = 100
    roleState[_RoleStateType.healthy].upperLimitValue = 100 -- 能回复的上限值 某些特性会导致上限值减少
    roleState[_RoleStateType.satiate] = {} -- 饱食
    roleState[_RoleStateType.satiate].maxValue = 100
    roleState[_RoleStateType.satiate].value = 100
    roleState[_RoleStateType.satiate].upperLimitValue = 100
    roleState[_RoleStateType.mood] = {} -- 心情
    roleState[_RoleStateType.mood].maxValue = 100
    roleState[_RoleStateType.mood].value = 100
    roleState[_RoleStateType.mood].upperLimitValue = 100
end

function AttributeDataBase:initMainAttributes(mainAttributes, cfg)
    mainAttributes.hp = cfg.bloodEssence * configMgr:getRoleAttributeByid(101).talentEffect[1][2] -- 生命
    mainAttributes.physicalStrength = 0 -- 体力
    mainAttributes.mp = cfg.airSea * configMgr:getRoleAttributeByid(201).talentEffect[1][2] -- 灵力
    mainAttributes.Maxhp = mainAttributes.hp -- 总值
    mainAttributes.MaxphysicalStrength = 0
    mainAttributes.Maxmp = mainAttributes.mp
end

-- 其他杂属性
function AttributeDataBase:initvariedtAttributes(variedAttributes, cfg)
    variedAttributes.temCharacteristicRecoveryRate = 1 -- 临时特性恢复速率
    variedAttributes.runAwayRata = 0 -- 被俘虏后每日逃跑率
    variedAttributes.intensifyRate = 0 -- 五行强化效率
    variedAttributes.baseFortune = 0 -- 个人运气
    variedAttributes.experienceRate = 0 -- 战斗经验获取
    variedAttributes.explorationScope = 0 -- 世界地图中信息查看的范围
    variedAttributes.survivalRate = 0 -- 己方存活率
    variedAttributes.teammonthConsume = 0 -- 队伍每月消耗
    variedAttributes.strategicSuccessRate = 0 -- 谋略成功率
    variedAttributes.defensiveForce = 0 -- 队伍单位防御力
    variedAttributes.teamMoveSpeed = 0 -- 队伍在一级场景的移动速率
    variedAttributes.strategicEffect = 0 -- 谋略的效果
    variedAttributes.teamFillForce = 0 -- 队伍的杀伤能力
    variedAttributes.teamCarryNum = 0 -- 队伍中可以携带的单位数量
end

function AttributeDataBase:getModel()
    -- local _cfg = configMgr:
end

-- #region 等级信息
function AttributeDataBase:initLevelInfo(levelInfo, cfg)
    -- 三大项技艺数据的保存TODO
    -- #region 精等级 最开始精属性包括 体魄 力量 敏捷后改为精血 体质 力量 到23/5/31又重新改回来了 
    levelInfo[_EMainAttributesType.Strength] = {}
    levelInfo[_EMainAttributesType.Strength].exp = 0
    levelInfo[_EMainAttributesType.Strength].lv = cfg.powerLevel
    levelInfo[_EMainAttributesType.Strength].assignCredits = 0 -- 精等级剩余点数
    -- #endregion

    -- #region 神等级
    levelInfo[_EMainAttributesType.Wisdom] = {}
    levelInfo[_EMainAttributesType.Wisdom].exp = 0
    levelInfo[_EMainAttributesType.Wisdom].lv = cfg.intelligenceLevel
    levelInfo[_EMainAttributesType.Wisdom].assignCredits = 0 -- 神等级剩余点数
    -- #endregion

    -- #region 气等级
    levelInfo[_EMainAttributesType.Wakan] = {}
    levelInfo[_EMainAttributesType.Wakan].exp = 0
    levelInfo[_EMainAttributesType.Wakan].lv = cfg.psychicLevel
    levelInfo[_EMainAttributesType.Wakan].assignCredits = 0 -- 气等级剩余点数
    -- #endregion

    -- #region 技艺等级
    levelInfo[_EMainAttributesType.Technique] = {}
    -- 目前角色配置表当中没有配技艺的等级和经验，默认初始等级为0，最高5
    for i = 1, 18 do
        local data = {}
        data.lv = 0
        data.exp = 0
        table.insert(levelInfo[_EMainAttributesType.Technique], data)
    end
    -- #endregion

    -- luaError("Strength2:" .. tableToString(levelInfo[_EMainAttributesType.Strength]))
end

-- #endregion

-- 获取角色的总等级
function AttributeDataBase:getTotalLevel()
    return self.data.levelInfo[_EMainAttributesType.Wakan].lv + self.data.levelInfo[_EMainAttributesType.Strength].lv +
            self.data.levelInfo[_EMainAttributesType.Wisdom].lv
end

function AttributeDataBase:getArmorSpeed()
    return isTableEmpty(self.data.equipmentList[3]) and 0 or tonumber(self.data.equipmentList[3].movingSpeed);
end

-- #region 主属性
function AttributeDataBase:getLevelInfo()
    return self.data.levelInfo
end

function AttributeDataBase:getStrengthAttributes()
    return self.data.levelInfo[_EMainAttributesType.Strength]
end

function AttributeDataBase:getWisdomAttributes()
    return self.data.levelInfo[_EMainAttributesType.Wisdom]
end

function AttributeDataBase:getWakanLv()
    return self.data.levelInfo[_EMainAttributesType.Wakan].lv
end

function AttributeDataBase:getTechniqueLv(techniqueType)
    return self.data.levelInfo[_EMainAttributesType.Technique][techniqueType].lv
end

-- 获得技艺经验 返回值1为curExp  2为nextLvtotal
function AttributeDataBase:getTechniqueExp(techniqueType)
    local _lv = self.data.levelInfo[_EMainAttributesType.Technique][techniqueType].lv
    local _curExp = self.data.levelInfo[_EMainAttributesType.Technique][techniqueType].exp
    if _curExp == nil then
        _curExp = 0
    end
    local _typeIndex = math.ceil(techniqueType / 6)
    if _typeIndex == 2 then
        _typeIndex = 3
    elseif _typeIndex == 3 then
        _typeIndex = 2
    end
    local _nextLvId = 0
    local _needExp = 0
    if _lv < 5 then
        _nextLvId = _typeIndex .. string.format("%02d", techniqueType) .. "0" .. (_lv + 2)
        _needExp = configMgr:getTechnique(tonumber(_nextLvId)).unlockingConditions[1]
    else
        _needExp = 99999
    end

    return { _curExp, _needExp }
end

-- #endregion

-- #region 战斗属性
function AttributeDataBase:initBattleAttributes(battleAttributes, cfg)
    -- 换装备后以下属性值没有更新（因为战斗属性还没有确定，战斗没有用到这里来，也不知道战斗是否做属性值的计算还是直接用这里的值）
    battleAttributes[_RoleBattleAttribute.weaponAtk] = 0 -- 武器伤害 (第一把武器)
    battleAttributes[_RoleBattleAttribute.magicInstrumentAtk] = 0 -- 法器伤害
    battleAttributes[_RoleBattleAttribute.armor] = 0 -- 护甲
    battleAttributes[_RoleBattleAttribute.armorValue] = 0 -- 护甲值 ？？？
    battleAttributes[_RoleBattleAttribute.weight] = cfg.weight + cfg.bloodEssence -- 重量
    battleAttributes[_RoleBattleAttribute.movingSpeed] = cfg.movingSpeed -- 移速
    battleAttributes[_RoleBattleAttribute.dodge] = cfg.dodge -- 闪避
    battleAttributes[_RoleBattleAttribute.breakBlock] = cfg.breakDefense -- 破防
    battleAttributes[_RoleBattleAttribute.crit] = cfg.critPer -- 暴击
    battleAttributes[_RoleBattleAttribute.critPower] = cfg.critAtk -- 暴击倍率
    battleAttributes[_RoleBattleAttribute.block] = cfg.blockPer + cfg.power -- 格挡
    battleAttributes[_RoleBattleAttribute.blockPower] = cfg.blockAtk -- 格挡倍率     
    battleAttributes[_RoleBattleAttribute.attackSpeed] = 0 -- 攻击速度
    battleAttributes[_RoleBattleAttribute.physicalInjury] = 0 -- 物理伤害
end

-- 五行相性
function AttributeDataBase:InitWuxing(cfg)
    -- 1 - 5分别为金木土水火
    local wuxing = {}
    table.insert(wuxing, cfg.goldCompatibility) -- 金相性
    table.insert(wuxing, cfg.woodCompatiteamRecruitmentbility) -- 木相性
    table.insert(wuxing, cfg.soilCompatibility) -- 土相性
    table.insert(wuxing, cfg.waterCompatibility) -- 水相性
    table.insert(wuxing, cfg.fireCompatibility) -- 火相性
    return wuxing
end

-- 获得角色基础战斗属性
---@return Temp_BattleData 战斗用到的基础属性
function AttributeDataBase:getBattleAttributes()
    ---@class Temp_BattleData

    local _battleData = {}
    -- 基础属性
    -- 体魄 '精'
    _battleData.bloodEssence = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.TiPo)
    -- 力量 '精'
    _battleData.power = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.LiLiang)
    -- 敏捷 '精'
    _battleData.agility = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.MinJie)
    -- 精等级
    _battleData.powerLevel = self.data.levelInfo[_EMainAttributesType.Strength].lv

    -- 气海 '气'
    _battleData.airSea = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.QiHai)
    -- 灵息 '气'
    _battleData.spellDamage = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.LingXi)
    -- 感知 '气'
    _battleData.perception = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.GanZhi)
    -- 气等级
    _battleData.psychicLevel = self.data.levelInfo[_EMainAttributesType.Wakan].lv

    -- 才智 '神'
    _battleData.ability = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.CaiZhi)
    -- 文韬 '神'
    _battleData.politicalStrategy = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.WenTao)
    -- 武略 '神'
    _battleData.militaryStrategy = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.WuLue)
    -- 神等级
    _battleData.intelligenceLevel = self.data.levelInfo[_EMainAttributesType.Wisdom].lv

    local _cfg = configMgr:getRoleCfg(self.data.id)
    -- 物理抗性
    _battleData.physicalResistance = _cfg.physicalResistance
    -- 法术抗性
    _battleData.magicResistant = _cfg.magicResistant
    -- 移速
    _battleData.movingSpeed = _cfg.movingSpeed + self:getArmorSpeed() + gameDef.walkSpeedIncrease
    -- 大世界步行速率
    _battleData.worldWalkSpeed = (_cfg.worldWalkSpeed + gameDef.walkSpeedIncrease) *
            (1 + math.floor(_battleData.ability / 5) * 0.01)
    -- 大世界奔跑速率
    _battleData.worldRunSpeed = (_cfg.worldRunSpeed + gameDef.runSpeedIncrease) *
            (1 + math.floor(_battleData.ability / 5) * 0.01)
    -- 二级场景步行速度
    _battleData.secondarysceneWalkSpeed = _cfg.secondarysceneWalkSpeed + self:getArmorSpeed() +
            gameDef.walkSpeedIncrease
    -- 二级场景奔跑速度
    _battleData.secondarysceneRunSpeed = _cfg.secondarysceneRunSpeed + self:getArmorSpeed() + gameDef.runSpeedIncrease
    -- 重量
    _battleData.weight = _cfg.weight + _battleData.bloodEssence
    -- 暴击
    _battleData.critPer = _cfg.critPer + _battleData.agility
    -- 暴击倍率
    _battleData.critAtk = _cfg.critAtk
    -- 格挡
    _battleData.blockPer = _cfg.blockPer + _battleData.power
    -- 格挡倍率
    _battleData.blockAtk = _cfg.blockAtk
    -- 破防
    _battleData.breakDefense = _cfg.breakDefense
    -- 闪避
    _battleData.dodge = _cfg.dodge
    -- 金相性
    _battleData.goldCompatibility = _cfg.goldCompatibility
    -- 木相性
    _battleData.woodCompatibility = _cfg.woodCompatibility
    -- 土相性
    _battleData.soilCompatibility = _cfg.soilCompatibility
    -- 水相性
    _battleData.waterCompatibility = _cfg.waterCompatibility
    -- 火相性
    _battleData.fireCompatibility = _cfg.fireCompatibility

    return _battleData
end

-- 初始化角色队伍
function AttributeDataBase:initTeamRecruitment(cfg)
    local _data = {}
    local _team = {}
    for i = 1, #_team do
        _data[cfg.id] = 1
    end
    return _data
end

-- #endregion

-- #region 技能
function AttributeDataBase:getAllSkill()
    local _newList = {}
    for i = 1, #self.data.skillList do
        if self.data.skillList[i].isUse == 0 then
            table.insert(_newList, self.data.skillList[i])
        end
    end
    return _newList
end

function AttributeDataBase:getUseSkill()
    -- local _weaponCfg = configMgr:getEquipmentById(self.data.equipmentList[1].id)
    local _weaponCfg = self:getEquipmentBySlot(_EEquipmentSlot.MainWeapon)
    local key = _weaponCfg.id
    if isTableEmpty(_weaponCfg) then
        return {}
    else
        if isKarateEquipment(_weaponCfg) then
            key = _EEquipmentSlot.MainWeapon
        end
        if self.data.useSkillList[key] == nil then
            self.data.useSkillList[key] = {}
        end
        return self.data.useSkillList[key]
    end
end

function AttributeDataBase:addSkill(skillId)
    local data = {
        id = skillId,
        isUse = 0
    }
    for i = 1, #self.data.skillList do
        if self.data.skillList[i].id == skillId then
            --luaError("添加重复技能" .. skillId)
            return
        end
    end
    table.insert(self.data.skillList, data)
    self.isDataDirty = true
end

-- 设置技能
function AttributeDataBase:setUseSkill(slotId, skillId, equipType)
    if self.data.equipmentList[equipType].id == nil then
        return
    end
    -- local _weaponCfg = configMgr:getEquipmentById(self.data.equipmentList[1].id)
    local _equipmentId = self.data.equipmentList[equipType].id
    local key = _equipmentId
    if isKarateEquipment(self.data.equipmentList[equipType]) then
        key = equipType
    end
    if self.data.useSkillList[key] == nil then
        self.data.useSkillList[key] = {}
    end
    if self.data.useSkillList[key][slotId] == nil then
        self.data.useSkillList[key][slotId] = 0
    end
    local _lastSkill = self.data.useSkillList[key][slotId]
    if _lastSkill ~= nil or _lastSkill ~= 0 then
        for i = 1, #self.data.skillList do
            if self.data.skillList[i].id == _lastSkill then
                self.data.skillList[i].isUse = 0
            end
        end
    end
    self.data.useSkillList[key][slotId] = skillId
    for i = 1, #self.data.skillList do
        if self.data.skillList[i].id == skillId then
            self.data.skillList[i].isUse = 1
        end
    end
    self.isDataDirty = true
end

-- 卸载技能
function AttributeDataBase:unloadSkill(slotId, equipType)
    -- local _weaponCfg = configMgr:getEquipmentById(self.data.equipmentList[1].id)
    local _equipmentId = self.data.equipmentList[equipType].id
    local key = _equipmentId
    if isKarateEquipment(self.data.equipmentList[equipType]) then
        key = equipType
    end
    if self.data.useSkillList[key][slotId] == nil then
        self.data.useSkillList[key][slotId] = 0
    end

    local _skillId = self.data.useSkillList[key][slotId]
    if _skillId ~= nil or _skillId ~= 0 then
        for i = 1, #self.data.skillList do
            if self.data.skillList[i].id == _skillId then
                self.data.skillList[i].isUse = 0
            end
        end
    end
    self.data.useSkillList[key][slotId] = 0

    self.isDataDirty = true
end

function AttributeDataBase:getUseSkillBySlot(slotId, equipSlot)
    if self.data.equipmentList[equipSlot].id == nil then
        return 0
    end
    local _weaponCfg = configMgr:getEquipmentById(self.data.equipmentList[equipSlot].id)
    local _equipmentId = self.data.equipmentList[equipSlot].id
    local key = _equipmentId
    if isKarateEquipment(self.data.equipmentList[equipSlot]) then
        key = equipSlot
    end
    if self.data.useSkillList[key] == nil then
        self.data.useSkillList[key] = {}
    end
    if self.data.useSkillList[key][slotId] == nil then
        self.data.useSkillList[key][slotId] = 0
    end
    local _skillId = self.data.useSkillList[key][slotId]
    if _skillId == nil then
        _skillId = 0
    end
    return _skillId
end

-- #region 装备

function AttributeDataBase:initEquipment(equipmentList, cfg)
    -- 没有装备的话 对应ID0 对象装备大类表别改
    if cfg.weaponList == nil or #cfg.weaponList == 0 then
        -- 主武器
        equipmentList[1] = {}
        -- 副武器
        equipmentList[2] = {}
    else
        -- 主武器
        if cfg.weaponList[1] == 0 or cfg.weaponList[1] == nil then
            equipmentList[1] = {}
        else
            equipmentList[1] = configMgr:getEquipmentById(cfg.weaponList[1])
        end
        -- 副武器
        if cfg.weaponList[2] == 0 or cfg.weaponList[2] == nil then
            equipmentList[2] = {}
        else
            equipmentList[2] = configMgr:getEquipmentById(cfg.weaponList[2])
        end
    end
    -- 盔甲
    if cfg.armorId == nil or cfg.armorId == 0 then
        equipmentList[3] = {}
    else
        equipmentList[3] = configMgr:getEquipmentById(cfg.armorId)
    end

    if cfg.clothingId == nil or cfg.clothingId == 0 then
        equipmentList[4] = {}
    else
        equipmentList[4] = configMgr:getEquipmentById(cfg.clothingId)
    end
    -- 法器
    if cfg.magicInstrumentId == nil or cfg.magicInstrumentId == 0 then
        equipmentList[5] = {}
    else
        equipmentList[5] = configMgr:getEquipmentById(cfg.magicInstrumentId)
    end
    -- 坐骑
    -- if cfg.mountId == nil or cfg.mountId == 0 then
    --     equipmentList[6] = {}
    -- else
    --     equipmentList[6] = configMgr:getEquipmentById(cfg.mountId)
    -- end
    if isTableEmpty(equipmentList[1]) then
        equipmentList[1] = getKarateData()
    end

    if isTableEmpty(equipmentList[2]) then
        equipmentList[2] = getKarateData()
    end
end

-- 当前装备是否被装备
function AttributeDataBase:getEquipmentById(unitId)
    for i = 1, #self.data.equipped do
        if self.data.equipped[i] ~= i and self.data.equipped[i].unitId == unitId then
            return true
        end
    end
    return false
end

-- 更新已经装备上的物品
function AttributeDataBase:refreshEquipeedData(value, data)
    self.data.equipped[value] = data
end

function AttributeDataBase:getEquipmentBySlot(slot)
    return self.data.equipmentList[slot]
end

-- 切换武器
function AttributeDataBase:switchWeapon()
    if self.data.upgradeSkillList == nil then
        self.data.upgradeSkillList = { { 0, 0 }, { 0, 0 } }
    end
    if self.data.upgradeSkillList[1] == nil then
        self.data.upgradeSkillList[1] = { 0, 0 }
    end
    if self.data.upgradeSkillList[2] == nil then
        self.data.upgradeSkillList[2] = { 0, 0 }
    end
    local _tempData = self.data.equipmentList[1]
    local _tempData2 = self.data.equipmentList[2]
    if isKarateEquipment(_tempData) and isKarateEquipment(_tempData2) then
        local _useSkillList1 = arrayDeepClone(self.data.useSkillList[1])
        local _useSkillList2 = arrayDeepClone(self.data.useSkillList[2])
        self.data.useSkillList[1] = _useSkillList2
        self.data.useSkillList[2] = _useSkillList1
    end
    if isKarateEquipment(_tempData2) and not isKarateEquipment(_tempData) then
        --local _useSkillList1 = arrayDeepClone(self.data.useSkillList[_tempData.id])
        local _useSkillList2 = arrayDeepClone(self.data.useSkillList[2])
        --self.data.useSkillList[_tempData.id] = _useSkillList1
        self.data.useSkillList[1] = _useSkillList2
        self.data.useSkillList[2] = { 0, 0 }
    end

    if isKarateEquipment(_tempData) and not isKarateEquipment(_tempData2) then
        local _useSkillList1 = arrayDeepClone(self.data.useSkillList[1])
        --local _useSkillList2 = arrayDeepClone(self.data.useSkillList[_tempData2.id])
        self.data.useSkillList[2] = _useSkillList1
        self.data.useSkillList[1] = { 0, 0 }
        --self.data.useSkillList[_tempData2.id] = _useSkillList2
    end

    local _upgradeSkill = self.data.upgradeSkillList[1]
    self.data.equipmentList[1] = self.data.equipmentList[2]
    self.data.equipmentList[2] = _tempData
    self.data.upgradeSkillList[1] = self.data.upgradeSkillList[2]
    self.data.upgradeSkillList[2] = _upgradeSkill
    self.isDataDirty = true
end

function AttributeDataBase:addExp(params)
    self.data.levelInfo[params.type].exp = self.data.levelInfo[params.type].exp + params.value
    local _data = {}
    local _num = 0
    if params.type == _EMainAttributesType.Strength then
        _num = 1000
    end
    if params.type == _EMainAttributesType.Wisdom then
        _num = 2000
    end
    if params.type == _EMainAttributesType.Wakan then
        _num = 3000
    end
    _data = configMgr:getRoleLevel(_num + self.data.levelInfo[params.type].lv)
    if self.data.levelInfo[params.type].exp > _data.requiredExperience then
        self.data.levelInfo[params.type].exp = self.data.levelInfo[params.type].exp - _data.requiredExperience
        self.data.levelInfo[params.type].lv = self.data.levelInfo[params.type].lv + 1
        if _data.level > 0 then
            self.data.levelInfo[params.type].assignCredits = self.data.levelInfo[params.type].assignCredits + _data.level
        end
    end
end

function AttributeDataBase:getExp(type)
    return self.data.levelInfo[type].exp
end

function AttributeDataBase:getAllElement()
    local _elementArr = {}
    for i = 1, 10 do
        _elementArr[i] = 0
    end
    -- 技能提供的元素属性
    for weaponType, skillArr in pairs(self.data.useSkillList) do
        for k, value in pairs(skillArr) do
            if value ~= 0 then
                local _skillCfg = configMgr:getSkillById(value)
                for i = 1, #_skillCfg.element do
                    _elementArr[_skillCfg.element[i][1]] = _elementArr[_skillCfg.element[i][1]] +
                            _skillCfg.element[i][2]
                end
            end
        end
    end
    -- 当前武器提供的元素属性
    if self.data.equipmentList[1].id ~= nil then
        for i = 1, #self.data.equipmentList[1].carryingSkills do
            local _skillCfg = configMgr:getSkillById(self.data.equipmentList[1].carryingSkills[i])
            for j = 1, #_skillCfg.element do
                _elementArr[_skillCfg.element[j][1]] = _elementArr[_skillCfg.element[j][1]] + _skillCfg.element[j][2]
            end
        end
    end
    return _elementArr
end

-- 获得精气神等级的和
function AttributeDataBase:getLevelCount()
    return self.data.levelInfo[_EMainAttributesType.Strength].lv + self.data.levelInfo[_EMainAttributesType.Wisdom].lv +
            self.data.levelInfo[_EMainAttributesType.Wakan].lv
end

function AttributeDataBase:getAttributeDataBase()
    return self.data.battleAttributes
end

function AttributeDataBase:getMainAttributes()
    return self.data.mainAttributes
end

-- 获取所有队伍里的所有角色
function AttributeDataBase:getroleReamList()
    return self.data.teamRecruitment
end

-- 添加队伍角色
---@param id 角色id
---@param type 1:队友,2:门客
function AttributeDataBase:addRoleToTeam(id, type)
    self.data.teamRecruitment[id] = type
    local _teamRole = dataMgr.roleDataMgr:getRoleData(id)
    _teamRole:changeJoinTeamID(self.data.id)
    if type == _TeamRecruitmentEnum.Team then
        dataMgr.playerData:addRole(id)
        -- local _lanStr = {}
        -- _lanStr.title = "新事件"
        -- _lanStr.des = _teamRole:getRoleName() .. "已加入你的队伍"
        -- noticeMgr:playerStateChange(_NoticeEnumType.PureTxtDes, _lanStr)

    else
        -- local _lanStr = {}
        -- _lanStr.title = "新事件"
        -- _lanStr.des = _teamRole:getRoleName() .. "已成为你的门客"
        -- noticeMgr:playerStateChange(_NoticeEnumType.PureTxtDes, _lanStr)
    end
    eventMgr:broadcastEvent(_EEventType.AddMessage, { {
                                                          roleId = id, -- 角色id
                                                          mustShow = true, -- 必须马上展示给玩家
                                                          type = _MessageType.Battalion, -- 消息的类型
                                                          content = "<u>" .. _teamRole:getRoleName() .. "</u>" .. configMgr:getLanguage(518039), -- 内容
                                                          contentType = _MessageContentType.RoleStateUnusal
                                                      } })
    self.isDataDirty = true
end
-- 替换门客和队友位置
function AttributeDataBase:changeTeamData(id, type)
    if type == _TeamRecruitmentEnum.Doorman then
        dataMgr.playerData:removeRole(id)
    else
        dataMgr.playerData:addRole(id)
    end

    self.data.teamRecruitment[id] = type
    self.isDataDirty = true
end

-- 移除队伍角色
function AttributeDataBase:removeRoleByTeam(id)
    if self.data.teamRecruitment[id] == _TeamRecruitmentEnum.Team then
        dataMgr.playerData:removeRole(id)
    end
    self.data.teamRecruitment[id] = nil
    local _teamRole = dataMgr.roleDataMgr:getRoleData(id)
    _teamRole:changeJoinTeamID(0)
    eventMgr:broadcastEvent(_EEventType.AddMessage, { {
                                                          roleId = id, -- 角色id
                                                          mustShow = true, -- 必须马上展示给玩家
                                                          type = _MessageType.Battalion, -- 消息的类型
                                                          content = "<u>" .. _teamRole:getRoleName() .. "</u>" .. configMgr:getLanguage(518040), -- 内容
                                                          contentType = _MessageContentType.RoleStateUnusal
                                                      } })
    self.isDataDirty = true
end

-- 查找队伍或门客
function AttributeDataBase:getteamRecruitmentById(type)
    local _data = {}
    for k, v in pairs(self.data.teamRecruitment) do
        if v == type then
            table.insert(_data, k)
        end
    end
    return _data
end

-- 获得此人所有扈从
function AttributeDataBase:getAllFollowers()
    return self.data.teamFollower
end

-- 用扈从自身设定的金钱购买他,使用前先用checkCanAddFollower判断
function AttributeDataBase:addFollowerByMoney(id)

    local _needMoney = configMgr:getFollowerById(id).recruitCost
    self:discardConsum(101001, _needMoney)
    self:addFollower(id)
end

-- 检查是否可以加入扈从。 若传id则默认附加检测是否够购买此扈从的钱
function AttributeDataBase:checkCanAddFollower(id)
    if id ~= nil then
        local _needMoney = configMgr:getFollowerById(id).recruitCost
        local _myRole = dataMgr.roleDataMgr:getRoleData(self.data.id)
        local _myMoney = _myRole:getItemNumberById(101001) -- 钱币写死
        if _needMoney > _myMoney then
            return 0 -- 没钱支付
        end
    end

    local _wulueValue = CharacterPropertyCenter.GetValue(self, CharacterPropertyEnum.WuLue)
    local hcMaxCount = math.floor(_wulueValue / configMgr:getPublicData(153).value[1]) *
            (configMgr:getPublicData(153).value[2]) -- 百分比
    if #self.data.teamFollower >= hcMaxCount then
        return -1 -- 没有空扈从位置
    end
    return 1
end

-- 添加扈从(自动按兵种高到低排序)，使用前先用checkCanAddFollower判断
function AttributeDataBase:addFollower(hcId)
    local _hcData = configMgr:getFollowerById(hcId)
    local _role = dataMgr.roleDataMgr:getRoleData(_hcData.roleId)
    local _arg = {}
    _arg.id = hcId -- 扈从id
    _arg.roleId = _role.id -- 唯一id
    _arg.exp = 0

    if #self.data.teamFollower == 0 then
        table.insert(self.data.teamFollower, _arg)
    else
        for i = 1, #self.data.teamFollower do
            local _data = configMgr:getFollowerById(self.data.teamFollower[i].id)
            if i ~= #self.data.teamFollower and _data.level < _hcData.level then
                table.insert(self.data.teamFollower, _arg, i)
                break
            end
            if i == #self.data.teamFollower then
                table.insert(self.data.teamFollower, _arg)
            end
        end
    end

    eventMgr:broadcastEvent(_EEventType.AddMessage, { {
                                                          roleId = _hcData.roleId, -- 角色id
                                                          mustShow = true, -- 必须马上展示给玩家
                                                          type = _MessageType.Battalion, -- 消息的类型
                                                          content = "<u>" .. _role:getRoleName() .. "</u>" .. "成为了你的扈从", -- 内容
                                                          contentType = _MessageContentType.RoleStateUnusal
                                                      } })
    self.isDataDirty = true
end

function AttributeDataBase:getAllFollowerCost()
    local _total = 0
    for i = 1, #self.data.teamFollower do
        _total = _total + configMgr:getFollowerById(self.data.teamFollower[i].id).recruitCost
    end
    return _total
end

function AttributeDataBase:getFollowCurExp(id)
    for i = 1, #self.data.teamFollower do
        if self.data.teamFollower[i].id == id then
            if self.data.teamFollower[i].exp == nil then
                self.data.teamFollower[i].exp = 0
            end
            return self.data.teamFollower[i].exp
        end
    end
    return 0
end

-- 扈从加经验
function AttributeDataBase:teamFollowerAddExpById(id, value)
    local _hcData = configMgr:getFollowerById(id)
    local _nextId = _hcData.nextLevelId
    for i = 1, #self.data.teamFollower do
        if self.data.teamFollower[i].id == id then
            self.data.teamFollower[i].exp = self.data.teamFollower[i].exp + value
            if _nextId ~= 0 and self.data.teamFollower[i].exp >= _hcData.unlockingConditions then
                self.data.teamFollower[i].id = _nextId
                self.data.teamFollower[i].exp = 0
            end
            self.isDataDirty = true
            break
        end
    end
end

-- 扈从加经验
function AttributeDataBase:teamFollowerAddExp(value)
    if #self.data.teamFollower == 0 then
        return
    end
    for i = 1, #self.data.teamFollower do
        self.data.teamFollower[i].exp = self.data.teamFollower[i].exp + value
        local _hcData = configMgr:getFollowerById(self.data.teamFollower[i].id)
        local _nextId = _hcData.nextLevelId
        if _nextId ~= 0 and self.data.teamFollower[i].exp >= _hcData.unlockingConditions then
            self.data.teamFollower[i].id = _nextId
            self.data.teamFollower[i].exp = 0
        end
    end
    local _role = dataMgr.roleDataMgr:getRoleData(self.data.id)
    local _str = ""
    if value > 0 then
        _str = string.format(configMgr:getLanguage(518050), value)
    else
        _str = string.format(configMgr:getLanguage(518049), value)
    end
    eventMgr:broadcastEvent(_EEventType.AddMessage, { {
                                                          roleId = self.data.id, -- 角色id
                                                          mustShow = true, -- 必须马上展示给玩家
                                                          type = _MessageType.Battalion, -- 消息的类型
                                                          content = _str, -- 内容
                                                          contentType = _MessageContentType.RoleStateUnusal
                                                      } })
    self.isDataDirty = true
end

-- 移除目标扈从
function AttributeDataBase:removeFollower(roleId, removeType)
    local _data = {}
    for i = 1, #self.data.teamFollower do
        if self.data.teamFollower[i].roleId == roleId then
            table.remove(self.data.teamFollower, i)
            break
        end
    end
    local _role = dataMgr.roleDataMgr:getRoleData(roleId)

    local id = 0
    if removeType == _EFollowerDismissType.Automatic then
        id = 518051
    elseif removeType == _EFollowerDismissType.Manual then
        id = 518052
    end

    eventMgr:broadcastEvent(_EEventType.AddMessage, { {
                                                          roleId = roleId, -- 角色id
                                                          mustShow = true, -- 必须马上展示给玩家
                                                          type = _MessageType.Battalion, -- 消息的类型
                                                          content = string.format(configMgr:getLanguage(id), "<u>" .. _role:getRoleName() .. "</u>"), -- 内容
                                                          contentType = _MessageContentType.RoleStateUnusal
                                                      } })
    self.isDataDirty = true
end

function AttributeDataBase:removeAllFollowers()
    local _arr = arrayDeepClone(self.data.teamFollower)
    for i = 1, #_arr do
        self:removeFollower(_arr[i].roleId, _EFollowerDismissType.Automatic)
    end
end

-- 修改雇主
function AttributeDataBase:changeJoinTeamID(id)
    self.data.joinTeamID = id
    self.isDataDirty = true
end

-- 角色是否已经加入了队伍
function AttributeDataBase:roleJoinTeam()
    return self.data.joinTeamID ~= 0
end

function AttributeDataBase:getJoinTeamId()
    return self.data.joinTeamID
end

-- 当前类型的招募人数是否已经满
function AttributeDataBase:roleNumListByTeam(type)
    local _num = 0
    for k, v in pairs(self.data.teamRecruitment) do
        if v == type then
            _num = _num + 1
        end
    end
    return _num
end

-- 招募角色
function AttributeDataBase:isTeamRecruit(id)
    local type = _TeamRecruitmentEnum.Team
    local _npcdata = dataMgr.roleDataMgr:getRoleData(id)
    local favoriateValue = _npcdata:getFavorabilityToOthers(self.data.id)
    local favoriateLevel = configMgr:getFavorabilityLevel(favoriateValue)
    -- if _npcdata.data.identity < _EIdentity.ShiRen then
    --     type = _TeamRecruitmentEnum.Doorman
    -- else
    --     type = _TeamRecruitmentEnum.Team
    -- end
    local _recruitNum = configMgr:getResidenceById(dataMgr.playerData:getHomeType()).customersLimit
    -- if favoriateLevel ~= _ERolesFavoriteType.Soulmate then ----暂时屏蔽招募限制（2023/7/20）
    --     gameTools.openFloatingPopup(configMgr:getLanguage(618011))
    --     return false
    -- end
    -- if _recruitNum == 0 then
    --     gameTools.openFloatingPopup(configMgr:getLanguage(618012))
    --     return
    -- end
    -- if #self.data.teamRecruitment >= _recruitNum then
    --     gameTools.openFloatingPopup(configMgr:getLanguage(618013))
    --     return false
    -- end
    if #_npcdata.data.teamRecruitment > 0 then
        -- 当前角色是队长
        gameTools.openFloatingPopup(configMgr:getLanguage(618014))
        return false
    end
    if id == self.data.id then
        gameTools.openFloatingPopup(configMgr:getLanguage(618015))
        return false
    end
    local _teamNum = self:roleNumListByTeam(_TeamRecruitmentEnum.Team)
    if type == _TeamRecruitmentEnum.Team then
        if _teamNum >= 4 then
            gameTools.openFloatingPopup(configMgr:getLanguage(618016))
            return false
        end
    end
    if not _npcdata:roleJoinTeam() then
        -- 当前角色没有被招募
        if self:isSatisfyCondition(id, type) then
            self:addRoleToTeam(id, type)
            return true
        end
    else
        if self:isSatisfyConditionTwo(id) then
            self:addRoleToTeam(id, type)
            return true
        end
    end
end

-- 是否满足队友的招募条件
function AttributeDataBase:isSatisfyCondition(id, type)
    local _npcdata = dataMgr.roleDataMgr:getRoleData(id)
    local _opinion = _npcdata.data.opinionType -- 角色主张
    if _opinion == _HumanOpinion.WangDao then
        if type == _TeamRecruitmentEnum.Team then
            if self.data.identity > _EIdentity.ShiRen then
                gameTools.openFloatingPopup(configMgr:getLanguage(618017))
                return false
            end
        end
        if type == _TeamRecruitmentEnum.Doorman then
            if _npcdata.data.officialPosition ~= 0 then
                gameTools.openFloatingPopup(configMgr:getLanguage(618018))
                return false
            end
        end
    end
    if _opinion == _HumanOpinion.BaDao then
        if _npcdata.data.identity > self.data.identity then
            gameTools.openFloatingPopup(configMgr:getLanguage(618019))
            return false
        end
    end
    if _opinion == _HumanOpinion.WoDao then
        local teamRec = dataMgr.teamRecruitmentMgr:getRoleInteractive(_npcdata.data.id)
        if teamRec ~= nil and not teamRec.gift.state then
            gameTools.openFloatingPopup(configMgr:getLanguage(618020))
            return false
        end
    end
    if _opinion == _HumanOpinion.XiaDao then
        local teamRec = dataMgr.teamRecruitmentMgr:getRoleInteractive(_npcdata.data.id)
        if teamRec ~= nil and not teamRec.quest.state then
            gameTools.openFloatingPopup(configMgr:getLanguage(618021))
            return false
        end
    end
    return true
end

-- 角色已经加入其他队伍，继续招募(队友和门客)
function AttributeDataBase:isSatisfyConditionTwo(id)
    local _npcdata = dataMgr.roleDataMgr:getRoleData(id)
    local _employerId = _npcdata.data.joinTeamID -- 雇主id
    local favoriateValue = _npcdata:getFavorabilityToOthers(_employerId)
    local favoriateLevel = configMgr:getFavorabilityLevel(favoriateValue)
    if _employerId == self.data.id then
        -- 如果此npc已经被自己招募
        gameTools.openFloatingPopup(configMgr:getLanguage(618022))
        return false
    end
    if favoriateLevel == _ERolesFavoriteType.Soulmate then
        gameTools.openFloatingPopup(configMgr:getLanguage(618023))
        return false
    end
    if favoriateLevel == _ERolesFavoriteType.Friendly then
        if _npcdata.data.opinionType ~= self.data.opinionType then
            gameTools.openFloatingPopup(configMgr:getLanguage(618024))
            return false
        end
    end
    if favoriateLevel == _ERolesFavoriteType.Common then
        local teamRec = dataMgr.teamRecruitmentMgr:getRoleInteractive(_npcdata.data.id)
        if teamRec ~= nil and not teamRec.game.state then
            gameTools.openFloatingPopup(configMgr:getLanguage(618025))
            return false
        end
    end
    return true
end

