Formulas_Battle = {
    IsLogging = false,
}

-- 相性修正 = (攻击方相性 - 防守方相性) * 10%
function Formulas_Battle.CalculateXiangXingXiuZheng(attackXiangXing, defenceXiangXing)
    local value = (attackXiangXing - defenceXiangXing) * 0.1;
    if (Formulas_Battle.IsLogging) then
        local message = "相性修正_" .. tostring(value) .. " = " .. "(攻击方相性_" .. tostring(attackXiangXing) .. " - " ..
                "防守方相性_" .. tostring(defenceXiangXing) .. ") * 10%";
        luaLog(message)
    end
    return value;
end

-- 闪避率, 破防率, 招架率, 暴击率. 都有一个泛性的公式: 概率 = （a*攻击方属性值+b*防守方属性值）/（c*攻击方属性值+d*防守方属性值）+e
-- a b c d e 的来源分别是 PublicData 的 650, 651, 652, 653.
-- 获得泛性公式参数: 
function Formulas_Battle.GetDodgeGenericFormulaParams(propertyEnum)
    local configId;
    if (propertyEnum == PropertyEnum.Dodge) then
        configId = 650;
    elseif (propertyEnum == PropertyEnum.PoFang) then
        configId = 651;
    elseif (propertyEnum == PropertyEnum.ZhaoJia) then
        configId = 652;
    elseif (propertyEnum == PropertyEnum.Crit) then
        configId = 653;
    else
        luaError("不支持的寻找泛性公式的属性: " .. tostring(propertyEnum));
        return ;
    end
    local config = t_publicData.getConfigById(configId);
    if (config == nil) then
        luaError("找不到泛性公式的参数: " .. tostring(configId));
        return ;
    end
    local a = config.value[1];
    local b = config.value[2];
    local c = config.value[3];
    local d = config.value[4];
    local e = config.value[5];
    return a, b, c, d, e;
end
-- 闪避泛性公式: 概率 = （a*攻击方属性值+b*防守方属性值）/（c*攻击方属性值+d*防守方属性值）+e + 额外加值.
function Formulas_Battle.CalculateDodgeGenericFormula(propertyEnum, attackProperty, defenceProperty, propertyAdd)
    local a, b, c, d, e = Formulas_Battle.GetDodgeGenericFormulaParams(propertyEnum);
    local dividend = c * attackProperty + d * defenceProperty;
    if (dividend == 0) then
        return e + propertyAdd;
    end
    local value = (a * attackProperty + b * defenceProperty) / (c * attackProperty + d * defenceProperty) + e + propertyAdd;
    if (Formulas_Battle.IsLogging) then
        local propertyName;
        if (propertyEnum == PropertyEnum.Dodge) then
            propertyName = "闪避率";
        elseif (propertyEnum == PropertyEnum.PoFang) then
            propertyName = "破防率";
        elseif (propertyEnum == PropertyEnum.ZhaoJia) then
            propertyName = "招架率";
        elseif (propertyEnum == PropertyEnum.Crit) then
            propertyName = "暴击率";
        else
            luaError("不支持的寻找泛性公式的属性: " .. tostring(propertyEnum));
            return ;
        end
        local message = propertyName .. "_" .. tostring(value) .. " = " .. "(a_" .. tostring(a) .. " * 攻击方属性值_" .. tostring(attackProperty) .. " + " ..
                "b_" .. tostring(b) .. " * 防守方属性值_" .. tostring(defenceProperty) .. ") / " ..
                "(c_" .. tostring(c) .. " * 攻击方属性值_" .. tostring(attackProperty) .. " + " ..
                "d_" .. tostring(d) .. " * 防守方属性值_" .. tostring(defenceProperty) .. ") + " ..
                "e_" .. tostring(e) .. " + " ..
                "额外加值_" .. tostring(propertyAdd);
        luaLog(message);
    end
    return value;
end

-- 暴击增伤 = [未招架且暴击时，暴击倍率]，其他[100%]
function Formulas_Battle.CalculateCritMul(isZhaoJia, isCrit, critMul)
    local value;
    if isZhaoJia or not isCrit then
        value = 1;
    else
        value = critMul;
    end
    return value;
end
-- 物理抗性修正 = [破防时, 100%]，[招架时, 1 - 20/ (20+物理抗性) * (1 -  招架倍率)]， [未破防且未招架时, 1 - 20/ (20+物理抗性)]
function Formulas_Battle.CalculatePhysResAdj(isPoFang, isZhaoJia, physRes, zhaoJiaMul)
    local value;
    if isPoFang then
        value = 1;
    elseif isZhaoJia then
        value = 1 - 20 / (20 + physRes) * (1 - zhaoJiaMul);
    else
        value = 1 - 20 / (20 + physRes);
    end

    return value;
end
-- 物理伤害值 = (武器伤害 + 模板物理伤害 * 模板物理伤害修正 * (1 + 力量 * 1%)) * 技能系数 * 物理抗性修正 * 暴击增伤 * (1 + 天赋物伤加成率)
function Formulas_Battle.CalculatePhysDmg(weaponDmg, templatePhysicalDmg, physDmgRatio, liLiang, skillMul, physResAdj, critMul, talentPhysDmgPct)
    local value = (weaponDmg + templatePhysicalDmg * physDmgRatio * (1 + liLiang * 0.01)) * skillMul * physResAdj * critMul * (1 + talentPhysDmgPct);
    if (Formulas_Battle.IsLogging) then
        local message = "物理伤害值_" .. tostring(value) .. " = " .. "(武器伤害_" .. tostring(weaponDmg) .. " + " ..
                "模板物理伤害_" .. tostring(templatePhysicalDmg) .. " * 模板物理伤害修正_" .. tostring(physDmgRatio) .. " * (1 + 力量_" .. tostring(liLiang) .. " * 1%)) * " ..
                "技能系数_" .. tostring(skillMul) .. " * 物理抗性修正_" .. tostring(physResAdj) .. " * 暴击增伤_" .. tostring(critMul) .. " * (1 + 天赋物伤加成率_" .. tostring(talentPhysDmgPct) .. ")";
        luaLog(message)
    end
    return value;
end

-- 法术伤害 = (法器伤害 + 模板法术伤害 * 模板法术伤害修正 * (1 + 灵犀 * 1%)) * 技能系数 * 相性修正 * (1 + 天赋法伤加成率)
function Formulas_Battle.CalculateMagicDmg(weaponDmg, templateMagicalDmg, magicDmgRatio, lingXi, skillMul, xiangXingXiuZheng, talentMagicDmgPct)
    local value = (weaponDmg + templateMagicalDmg * magicDmgRatio * (1 + lingXi * 0.01)) * skillMul * xiangXingXiuZheng * (1 + talentMagicDmgPct);
    if (Formulas_Battle.IsLogging) then
        local message = ""
        luaLog(message)
    end
    return value;
end

-- 位移冷却 = (位移技能冷却 + 装备提供的位移恢复时间数值) * (1 - INT(敏捷 /10) * 5%), 取值在 [0,60], 单位是 s.
function Formulas_Battle.CalculateDisplacementCd(skillCd, cdAdd, minJie)
    local value = Mathf.Clamp((skillCd + cdAdd) * (1 - math.floor(minJie / 10) * 0.05), 0, 60);
    if (Formulas_Battle.IsLogging) then
        local message = "位移冷却_" .. tostring(value) .. " = " .. "(位移技能冷却_" .. tostring(skillCd) .. " + 装备提供的位移恢复时间数值_" ..
                tostring(cdAdd) .. ") * (1 - 敏捷_" .. tostring(minJie) .. " /10) * 5%)";
        luaLog(message)
    end
    return value;
end

-- 物理受击等级 和 物理距离系数公式: 
-- 参数: 单次血量伤害(血量伤害指被护甲抵挡的部分不计), 受击角色体力上限, 打击值, 打击系数, 受击角色重量.
-- 返回值: 物理受击等级, 物理距离系数.
function Formulas_Battle.CalculatePhysHitLevelAndDistanceCoefficient(singleBloodDamage, targetMaxHp, daJi, hitCoefficient, targetWeight)
    local hitLevel = 0

    if singleBloodDamage > 0.2 * targetMaxHp and singleBloodDamage < 0.5 * targetMaxHp then
        -- 武器技能单次血量伤害大于被击方体力上限 20%（但 <50%），受击等级 + 1；
        hitLevel = hitLevel + 1
    elseif singleBloodDamage > 0.5 * targetMaxHp then
        --武器技能单次血量伤害大于被击方体力上限 50%，受击等级 + 2；
        hitLevel = hitLevel + 2
    end

    if daJi * hitCoefficient > targetWeight and daJi * hitCoefficient < 3 * targetWeight then
        -- 武器打击值*打击系数 > 被击方重量, 但 < 3*被击方重量，受击等级 + 1；
        hitLevel = hitLevel + 1
    elseif daJi * hitCoefficient > 3 * targetWeight then
        -- 武器打击值*打击系数 > 3*被击方重量，受击等级 + 2；
        hitLevel = hitLevel + 2
    end

    -- 距离系数 = 血量伤害/目标体力上限 + 打击值*打击系数/被击方重量/6，最大不超过1
    local distanceCoefficient = singleBloodDamage / targetMaxHp + daJi * hitCoefficient / (6 * targetWeight)
    if distanceCoefficient > 1 then
        distanceCoefficient = 1
    end

    return hitLevel, distanceCoefficient;
end
-- 法术受击等级 和 法术距离系数公式:
function Formulas_Battle.CalculateMagicHitLevelAndDistanceCoefficient(singleBloodDamage, targetMaxHp)
    local hitLevel = 0

    -- 法术技能单次伤害大于被击方体力上限 30%，受击等级 + 1.
    if singleBloodDamage > 0.3 * targetMaxHp then
        hitLevel = hitLevel + 1
    end

    -- 距离系数 = 法术伤害/目标体力上限
    local distanceCoefficient = singleBloodDamage / targetMaxHp

    return hitLevel, distanceCoefficient
end
