Formulas_BattleWrapper = {}

-- 相性修正 =  (攻击方相性 - 防守方相性) * 10%
function Formulas_BattleWrapper.CalculateXiangXingXiuZheng(attackRole, defenceRole, xiangXingEnum)
    local attackXiangXing = PropertyCenter.GetValue(attackRole, xiangXingEnum);
    local defenceXiangXing = PropertyCenter.GetValue(defenceRole, xiangXingEnum);
    return Formulas_Battle.CalculateXiangXingXiuZheng(attackXiangXing, defenceXiangXing);
end

-- 闪避率 = 防守方感知 / (防守方感知 + 5 * 攻击方感知) - 0.15 + 总额外闪避率
function Formulas_BattleWrapper.CalculateDodge(attackRole, defenceRole)
    local attackGanZhi = PropertyCenter.GetValue(attackRole, PropertyEnum.GanZhi);
    local defenceGanZhi = PropertyCenter.GetValue(defenceRole, PropertyEnum.GanZhi);
    local extraDodgeRate = PropertyCenter.GetValue(attackRole, PropertyEnum.DodgeAdd);
    return Formulas_Battle.CalculateDodgeGenericFormula(PropertyEnum.Dodge, attackGanZhi, defenceGanZhi, extraDodgeRate);
end
-- 破防率 = 1.2 * 攻击方灵犀 / (攻击方灵犀 + 4 * 防守方灵犀) - 0.24 + 总额外破防率
function Formulas_BattleWrapper.CalculatePoFang(attackRole, defenceRole)
    local attackLingXi = PropertyCenter.GetValue(attackRole, PropertyEnum.LingXi);
    local defenceLingXi = PropertyCenter.GetValue(defenceRole, PropertyEnum.LingXi);
    local extraPoFangRate = PropertyCenter.GetValue(attackRole, PropertyEnum.PoFangAdd);
    return Formulas_Battle.CalculateDodgeGenericFormula(PropertyEnum.PoFang, attackLingXi, defenceLingXi, extraPoFangRate);
end
-- 招架率 = 防守方力量 / (防守方力量 + 3 * 攻击方力量) - 0.25 + 总额外招架率
function Formulas_BattleWrapper.CalculateZhaoJia(attackRole, defenceRole)
    local attackLiLiang = PropertyCenter.GetValue(attackRole, PropertyEnum.LiLiang);
    local defenceLiLiang = PropertyCenter.GetValue(defenceRole, PropertyEnum.LiLiang);
    local extraZhaoJiaRate = PropertyCenter.GetValue(attackRole, PropertyEnum.ZhaoJiaAdd);
    return Formulas_Battle.CalculateDodgeGenericFormula(PropertyEnum.ZhaoJia, attackLiLiang, defenceLiLiang, extraZhaoJiaRate);
end
-- 暴击率 = 攻击方敏捷 / (攻击方敏捷 + 5*防守方敏捷）+ 总额外暴击率
function Formulas_BattleWrapper.CalculateCrit(attackRole, defenceRole)
    local attackMinJie = PropertyCenter.GetValue(attackRole, PropertyEnum.MinJie);
    local defenceMinJie = PropertyCenter.GetValue(defenceRole, PropertyEnum.MinJie);
    local extraCritRate = PropertyCenter.GetValue(attackRole, PropertyEnum.CritAdd);
    return Formulas_Battle.CalculateDodgeGenericFormula(PropertyEnum.Crit, attackMinJie, defenceMinJie, extraCritRate);
end

-- 暴击增伤 = [未招架且暴击时，暴击倍率]，其他[100%]
function Formulas_BattleWrapper.CalculateCritMul(isZhaoJia, isCrit, attackRole)
    local critMul = PropertyCenter.GetValue(attackRole, PropertyEnum.CritMul);
    return Formulas_Battle.CalculateCritMul(isZhaoJia, isCrit, critMul)
end
-- 物理抗性修正 = [破防时, 100%]，[招架时, 1 - 20/ (20+物理抗性) * (1 -  招架倍率)]， [未破防且未招架时, 1 - 20/ (20+物理抗性)]
function Formulas_BattleWrapper.CalculatePhysResAdj(isPoFang, isZhaoJia, defenceRole)
    local physRes = PropertyCenter.GetValue(defenceRole, PropertyEnum.PhysRes);
    local zhaoJiaMul = PropertyCenter.GetValue(defenceRole, PropertyEnum.ZhaoJiaMul);
    return Formulas_Battle.CalculatePhysResAdj(isPoFang, isZhaoJia, physRes, zhaoJiaMul)
end
-- 物理伤害值 = (武器伤害 + 模板物理伤害 * 模板物理伤害修正 * (1 + 力量 * 1%)) * 技能系数 * 物理抗性修正 * 暴击增伤 * (1 + 天赋物伤加成率)
function Formulas_BattleWrapper.CalculatePhysDmg(attackRole, skillMul, physResAdj)
    local weaponDmg = PropertyCenter.GetValue(attackRole, PropertyEnum.WeaponDmg);
    local templatePhysicalDmg = PropertyCenter.GetValue(attackRole, PropertyEnum.TemplatePhysicalDmg);
    local roleConfig = RoleConfigExtensions.GetRoleConfig(attackRole);
    local physDmgRatio = roleConfig.AtkRatio;
    local liLiang = PropertyCenter.GetValue(attackRole, PropertyEnum.LiLiang);
    local critMul = PropertyCenter.GetValue(attackRole, PropertyEnum.CritMul);
    local talentPhysDmgPct = PropertyCenter.GetValue(attackRole, PropertyEnum.TalentPhysDmgPct);
    return Formulas_Battle.CalculatePhysDmg(weaponDmg, templatePhysicalDmg, physDmgRatio, liLiang, skillMul, physResAdj, critMul, talentPhysDmgPct)
end
-- 法术伤害 = (法器伤害 + 模板法术伤害 * 模板法术伤害修正 * (1 + 灵犀 * 1%)) * 技能系数 * 相性修正 * (1 + 天赋法伤加成率)
function Formulas_BattleWrapper.CalculateMagicDmg(attackRole, skillMul, xiangXingXiuZheng)
    local faqiDmg = PropertyCenter.GetValue(attackRole, PropertyEnum.FaQiDmg);
    local templateMagicalDmg = PropertyCenter.GetValue(attackRole, PropertyEnum.TemplateMagicalDmg);
    local roleConfig = RoleConfigExtensions.GetRoleConfig(attackRole);
    local magicDmgRatio = roleConfig.MagicAtkRatio;
    local lingXi = PropertyCenter.GetValue(attackRole, PropertyEnum.LingXi);
    local talentMagicDmgPct = PropertyCenter.GetValue(attackRole, PropertyEnum.TalentMagicDmgPct);
    return Formulas_Battle.CalculateMagicDmg(faqiDmg, templateMagicalDmg, magicDmgRatio, lingXi, skillMul, xiangXingXiuZheng, talentMagicDmgPct)
end

-- 位移冷却 = (位移技能冷却 + 装备提供的位移恢复时间数值) * (1 - INT(敏捷 /10) * 5%), 取值在 [0,60], 单位是 s.
function Formulas_BattleWrapper.CalculateDisplacementCd(role, skillCd, cdAdd)
    local minJie = PropertyCenter.GetValue(role, PropertyEnum.MinJie);
    return Formulas_Battle.CalculateDisplacementCd(skillCd, cdAdd, minJie)
end

-- 物理受击等级 和 物理距离系数公式: 
function Formulas_BattleWrapper.CalculatePhysHitLevelAndDistanceRatio(attackRole, defenceRole, singleBloodDamage, hitCoefficient)
    local targetMaxHp = PropertyCenter.GetValue(defenceRole, PropertyEnum.MaxHp);
    local daJi = PropertyCenter.GetValue(attackRole, PropertyEnum.DaJi);
    local targetWeight = PropertyCenter.GetValue(defenceRole, PropertyEnum.Weight);
    return Formulas_Battle.CalculatePhysHitLevelAndDistanceCoefficient(singleBloodDamage, targetMaxHp, daJi, hitCoefficient, targetWeight)
end
-- 法术受击等级 和 法术距离系数公式:
function Formulas_BattleWrapper.CalculateMagicHitLevelAndDistanceRatio(defenceRole, singleBloodDamage)
    local targetMaxHp = PropertyCenter.GetValue(defenceRole, PropertyEnum.MaxHp);
    return Formulas_Battle.CalculateMagicHitLevelAndDistanceCoefficient(singleBloodDamage, targetMaxHp)
end