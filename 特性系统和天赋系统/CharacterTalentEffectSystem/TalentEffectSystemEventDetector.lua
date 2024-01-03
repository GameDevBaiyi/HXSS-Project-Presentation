---@class TalentEffectSystemEventDetector:Class


TalentEffectSystemEventDetector = Class(UnitBase)
TalentEffectSystemEventDetector.IsLogging = false

function TalentEffectSystemEventDetector:ctor()
end

require("game/CharacterSystems/CharacterTalentEffectSystem/TalentEffectSystemEventDetector_Counter")

function TalentEffectSystemEventDetector:Initialize()
    eventMgr:registerEvent(_EEventType.TraitBattleCritPer, handler(self.onBattleCritPer, self))
    eventMgr:registerEvent(_EEventType.TraitBattleThump, handler(self.onBattleThump, self))
    eventMgr:registerEvent(_EEventType.TraitBattleBlockPer, handler(self.onBattleBlockPer, self))
    eventMgr:registerEvent(_EEventType.TraitBattleDodge, handler(self.onBattleDodge, self))
    eventMgr:registerEvent(_EEventType.TraitEquipment, handler(self.onTraitEquipment, self))
    eventMgr:registerEvent(_EEventType.TraitBattleStagger, handler(self.onTraitBattleStagger, self))
    eventMgr:registerEvent(_EEventType.TraitBattleBeStagger, handler(self.onTraitBattleBeStagger, self))
end

function TalentEffectSystemEventDetector:onBattleCritPer(params)
    local role = params[1].role;
    if role == nil then
        luaError("暴击 的事件 的参数 role 为空")
        return
    end

    -- 根据state值，决定是增加还是减少IsCrittingAdd的值。
    local valueChange = params[1]['state'] == 1 and 1 or -1
    TalentConditionMonitor_Battle.SetValue(role, "IsCritting", valueChange)
end

function TalentEffectSystemEventDetector:onBattleThump(params)
    local role = params[1].role;
    if role == nil then
        luaError("破防 的事件 的参数 role 为空")
        return
    end

    local valueChange = params[1]['state'] == 1 and 1 or -1
    TalentConditionMonitor_Battle.SetValue(role, "IsBreakingDefense", valueChange)
end

function TalentEffectSystemEventDetector:onBattleBlockPer(params)
    local role = params[1].role;
    if role == nil then
        luaError("格挡 的事件 的参数 role 为空")
        return
    end

    local valueChange = params[1]['state'] == 1 and 1 or -1
    TalentConditionMonitor_Battle.SetValue(role, "IsParrying", valueChange)
end

function TalentEffectSystemEventDetector:onBattleDodge(params)
    local role = params[1].role;
    if role == nil then
        luaError("闪避 的事件 的参数 role 为空")
        return
    end

    local valueChange = params[1]['state'] == 1 and 1 or -1
    TalentConditionMonitor_Battle.SetValue(role, "IsDodging", valueChange)
end

function TalentEffectSystemEventDetector:onTraitEquipment(params)
    local role = params[1].role;
    if role == nil then
        luaError("切换装备 的事件 的参数 role 为空")
        return
    end

    if (params[1].weapon1Cfg == nil) then
        luaError("切换装备的事件 的参数 weapon1Id 为空")
        return
    end
    mainWeaponConfig = params[1].weapon1Cfg or {}
    -- luaTable(mainWeaponConfig)
    if mainWeaponConfig.equipmentCategory == nil then
        -- luaError("切换装备的事件的参数的类型 equipmentCategory 为空. ")
        TalentConditionMonitor_Battle.SetValue(role, "EquipmentCategory", 0);
        TalentConditionMonitor_Battle.SetValue(role, "WeaponType", 0)
    else
        TalentConditionMonitor_Battle.SetValue(role, "EquipmentCategory", mainWeaponConfig.equipmentCategory);
        TalentConditionMonitor_Battle.SetValue(role, "WeaponType", mainWeaponConfig.weaponType)
    end
end

function TalentEffectSystemEventDetector:onTraitBattleStagger(params)
    local role = params[1].role;
    if role == nil then
        luaError("攻击使敌人硬直 的参数 role 为空")
        return
    end

    TalentConditionMonitor_Battle.SetValue(role, "IsStiffing", 1);
    TalentConditionMonitor_Battle.SetValue(role, "IsStiffing", -1);
end

function TalentEffectSystemEventDetector:onTraitBattleBeStagger(params)
    local role = params[1].role;
    if role == nil then
        luaError("被攻击使自己硬直 的参数 role 为空")
        return
    end

    TalentConditionMonitor_Battle.SetValue(role, "IsStiffed", 1);
    TalentConditionMonitor_Battle.SetValue(role, "IsStiffed", -1);
end