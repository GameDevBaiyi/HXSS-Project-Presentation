function PropertyCenter.Initialize(role)
    local roleConfig = RoleConfigExtensions.GetRoleConfig(role);

    -- 初始化九维. 
    PropertyCenter.AddProperty(role, PropertyEnum.TiPoBase, roleConfig.bloodEssence) -- 体魄
    PropertyCenter.AddProperty(role, PropertyEnum.LiLiangBase, roleConfig.power) -- 力量
    PropertyCenter.AddProperty(role, PropertyEnum.MinJieBase, roleConfig.agility) -- 敏捷
    PropertyCenter.AddProperty(role, PropertyEnum.QiHaiBase, roleConfig.airSea) -- 气海
    PropertyCenter.AddProperty(role, PropertyEnum.LingXiBase, roleConfig.spellDamage) -- 灵犀
    PropertyCenter.AddProperty(role, PropertyEnum.GanZhiBase, roleConfig.perception) -- 感知
    PropertyCenter.AddProperty(role, PropertyEnum.WenTaoBase, roleConfig.politicalStrategy) -- 文韬
    PropertyCenter.AddProperty(role, PropertyEnum.WuLueBase, roleConfig.militaryStrategy) -- 武略
    PropertyCenter.AddProperty(role, PropertyEnum.CaiZhiBase, roleConfig.ability) -- 才智
    -- 初始化五行相性.
    PropertyCenter.AddProperty(role, PropertyEnum.JinXiangXingBase, roleConfig.goldCompatibility) -- 金相性
    PropertyCenter.AddProperty(role, PropertyEnum.MuXiangXingBase, roleConfig.woodCompatibility) -- 木相性
    PropertyCenter.AddProperty(role, PropertyEnum.TuXiangXingBase, roleConfig.soilCompatibility) -- 水相性
    PropertyCenter.AddProperty(role, PropertyEnum.ShuiXiangXingBase, roleConfig.waterCompatibility) -- 火相性
    PropertyCenter.AddProperty(role, PropertyEnum.HuoXiangXingBase, roleConfig.fireCompatibility) -- 土相性

    -- 物理抗性
    PropertyCenter.AddProperty(role, PropertyEnum.PhysResBase, roleConfig.physicalResistance)
    -- 招架倍率
    PropertyCenter.AddProperty(role, PropertyEnum.ZhaoJiaMulBase, roleConfig.blockAtk)
    -- 暴击倍率
    PropertyCenter.AddProperty(role, PropertyEnum.CritMulBase, roleConfig.critAtk)

    -- 重量
    PropertyCenter.AddProperty(role, PropertyEnum.WeightBase, roleConfig.weight)
end

function PropertyCenter.GetValue(role, propertyEnum)
    local propertyCenter = role.data.PropertyCenter;
    local value = propertyCenter.Enum_Value[propertyEnum] or 0;

    if propertyEnum == PropertyEnum.LiLiangBase or
            propertyEnum == PropertyEnum.TiPoBase or
            propertyEnum == PropertyEnum.MinJieBase or
            propertyEnum == PropertyEnum.QiHaiBase or
            propertyEnum == PropertyEnum.LingXiBase or
            propertyEnum == PropertyEnum.GanZhiBase or
            propertyEnum == PropertyEnum.WenTaoBase or
            propertyEnum == PropertyEnum.WuLueBase or
            propertyEnum == PropertyEnum.CaiZhiBase then
        -- 如果是 9 维属性的 Base, 限制到 0 到 100.
        value = Mathf.Clamp(value, 0, 100);
    elseif propertyEnum >= PropertyEnum.JinXiangXing and propertyEnum <= PropertyEnum.HuoXiangXing then
        -- 如果是 五行相性, 限制到 -100 到 100.
        value = Mathf.Clamp(value, -100, 100);
    elseif propertyEnum == PropertyEnum.PhysRes then
        -- 物理抗性, 最小为 0.
        value = Mathf.Clamp(value, 0, value);
    elseif propertyEnum == PropertyEnum.DaJi then
        -- 打击值, 最小为 0.
        value = Mathf.Clamp(value, 0, value);
    elseif propertyEnum == PropertyEnum.ZhaoJiaMul then
        -- 招架倍率, 0 到 1.
        value = Mathf.Clamp(value, 0, 1);
    elseif propertyEnum == PropertyEnum.CritMul then
        -- 暴击倍率, 最小为 0.
        value = Mathf.Clamp(value, 0, value);
    elseif propertyEnum == PropertyEnum.CdReduc then
        -- 如果是 技能冷却, 限制最大值 0.9.
        value = Mathf.Clamp(value, value, 0.9);
    elseif propertyEnum == PropertyEnum.MaxHp then
        -- 最大体力, 最小有 1 点.
        value = Mathf.Clamp(value, 1, value);
    elseif propertyEnum == PropertyEnum.MaxMp then
        -- 最大 Mp, 最小为 0.
        value = Mathf.Clamp(value, 0, value);
    elseif propertyEnum == PropertyEnum.PhysicalDmg then
        -- 物理伤害, 最小为 0.
        value = Mathf.Clamp(value, 0, value);
    elseif propertyEnum == PropertyEnum.MagicalDmg then
        -- 法术伤害, 最小为 0.
        value = Mathf.Clamp(value, 0, value);
    elseif propertyEnum == PropertyEnum.JiQi then
        -- 集气, 最小为 0.
        value = Mathf.Clamp(value, 0, value);
    elseif propertyEnum == PropertyEnum.HuaQi then
        -- 化气, 最小为 0.
        value = Mathf.Clamp(value, 0, value);
    elseif propertyEnum == PropertyEnum.Weight then
        -- 重量, 最小为 0.
        value = Mathf.Clamp(value, 0, value);
    elseif propertyEnum == PropertyEnum.Dodge or propertyEnum == PropertyEnum.PoFang or propertyEnum == PropertyEnum.ZhaoJia or propertyEnum == PropertyEnum.Crit then
        -- 闪避率, 破防率, 招架率, 暴击率, 都是 0 ~ 1.
        value = Mathf.Clamp(value, 0, 1);
    end

    return value;
end

function PropertyCenter.OnAddProperty(role, propertyEnum, addend)
end

function PropertyCenter.UpdateLv2MainProperty(role, mainProperty)
    local propertyCenter = role.data.PropertyCenter;
    local roleConfig = RoleConfigExtensions.GetRoleConfig(role);
    if (mainProperty == PropertyEnum.MaxHp) then
        -- MaxHp = 模板体力上限 * 模板体力上限修正 * (1 + 体魄 * 1%)
        -- 模板体力上限
        local templateMaxHp = PropertyCenter.GetValue(role, PropertyEnum.TemplateMaxHp);
        -- 模板体力上限修正
        local maxHpRatio = roleConfig.HpRatio;
        -- 体魄
        local tiPo = PropertyCenter.GetValue(role, PropertyEnum.TiPo);
        propertyCenter.Enum_Value[mainProperty] = templateMaxHp * maxHpRatio * (1 + tiPo * 0.01);
    elseif (mainProperty == PropertyEnum.MaxMp) then
        -- MaxMp = 气海 * 10
        local qiHai = PropertyCenter.GetValue(role, PropertyEnum.QiHai);
        propertyCenter.Enum_Value[mainProperty] = qiHai * 10;
    elseif (mainProperty == PropertyEnum.PhysicalDmg) then
        -- PhysicalDmg = 武器伤害 + 模板物理伤害 * 模板物理伤害修正 * (1 + 力量 * 1%)
        -- 武器伤害
        local weaponDmg = PropertyCenter.GetValue(role, PropertyEnum.WeaponDmg);
        -- 模板物理伤害
        local templatePhysicalDmg = PropertyCenter.GetValue(role, PropertyEnum.TemplatePhysicalDmg);
        -- 模板物理伤害修正
        local physicalDmgRatio = roleConfig.AtkRatio;
        -- 力量
        local liLiang = PropertyCenter.GetValue(role, PropertyEnum.LiLiang);
        propertyCenter.Enum_Value[mainProperty] = weaponDmg + templatePhysicalDmg * physicalDmgRatio * (1 + liLiang * 0.01);
    elseif (mainProperty == PropertyEnum.MagicalDmg) then
        -- MagicalDmg = 法器伤害 + 模板法术伤害 * 模板法术伤害修正 * （1 + 灵犀 * 1%)
        -- 法器伤害
        local faQiDmg = PropertyCenter.GetValue(role, PropertyEnum.FaQiDmg);
        -- 模板法术伤害
        local templateMagicalDmg = PropertyCenter.GetValue(role, PropertyEnum.TemplateMagicalDmg);
        -- 模板法术伤害修正
        local magicalDmgRatio = roleConfig.MagicAtkRatio;
        -- 灵犀
        local lingXi = PropertyCenter.GetValue(role, PropertyEnum.LingXi);
        propertyCenter.Enum_Value[mainProperty] = faQiDmg + templateMagicalDmg * magicalDmgRatio * (1 + lingXi * 0.01);
    elseif (mainProperty == PropertyEnum.JiQi) then
        -- JiQi = 1 +（气海/5）* 1%
        local qiHai = PropertyCenter.GetValue(role, PropertyEnum.QiHai);
        propertyCenter.Enum_Value[mainProperty] = 1 + math.floor(qiHai / 5) * 0.01;
    elseif (mainProperty == PropertyEnum.HuaQi) then
        -- HuaQi = 1 + INT（感知/5）* 1%
        local ganZhi = PropertyCenter.GetValue(role, PropertyEnum.GanZhi);
        propertyCenter.Enum_Value[mainProperty] = 1 + math.floor(ganZhi / 5) * 0.01;
    elseif (mainProperty == PropertyEnum.Weight) then
        -- Weight = Base + Add + 体魄. 角色重量值 认为是 Base, 护甲重量值 认为是 Add. 
        local base = PropertyCenter.GetValue(role, PropertyEnum.WeightBase);
        local add = PropertyCenter.GetValue(role, PropertyEnum.WeightAdd);
        local tiPo = PropertyCenter.GetValue(role, PropertyEnum.TiPo);
        propertyCenter.Enum_Value[mainProperty] = base + add + tiPo;
    elseif (mainProperty == PropertyEnum.Dodge) then
        -- 闪避率 = 感知 / (感知 + 5 * 模板感知) - 0.15 + 总额外闪避率
        local ganZhi = PropertyCenter.GetValue(role, PropertyEnum.GanZhi);
        local templateGanZhi = PropertyCenter.GetValue(role, PropertyEnum.TemplateGanZhi);
        local dodgeAdd = PropertyCenter.GetValue(role, PropertyEnum.DodgeAdd);
        propertyCenter.Enum_Value[mainProperty] = Formulas_Battle.CalculateDodgeGenericFormula(PropertyEnum.Dodge, templateGanZhi, ganZhi, dodgeAdd);
    elseif (mainProperty == PropertyEnum.PoFang) then
        -- 破防率 = 1.2 * 灵犀 / (灵犀 + 4 * 模板灵犀值) - 0.24 + 总额外破防率
        local lingXi = PropertyCenter.GetValue(role, PropertyEnum.LingXi);
        local templateLingXi = PropertyCenter.GetValue(role, PropertyEnum.TemplateLingXi);
        local poFangAdd = PropertyCenter.GetValue(role, PropertyEnum.PoFangAdd);
        propertyCenter.Enum_Value[mainProperty] = Formulas_Battle.CalculateDodgeGenericFormula(PropertyEnum.PoFang, templateLingXi, lingXi, poFangAdd);
    elseif (mainProperty == PropertyEnum.ZhaoJia) then
        -- 招架率 = 力量 / (力量 + 3 * 模板力量值) - 0.25  + 总额外招架率
        local liLiang = PropertyCenter.GetValue(role, PropertyEnum.LiLiang);
        local templateLiLiang = PropertyCenter.GetValue(role, PropertyEnum.TemplateLiLiang);
        local zhaoJiaAdd = PropertyCenter.GetValue(role, PropertyEnum.ZhaoJiaAdd);
        propertyCenter.Enum_Value[mainProperty] = Formulas_Battle.CalculateDodgeGenericFormula(PropertyEnum.ZhaoJia, templateLiLiang, liLiang, zhaoJiaAdd);
    elseif (mainProperty == PropertyEnum.Crit) then
        -- 暴击率 = 敏捷 / (敏捷 + 5 * 模板敏捷值) + 总额外暴击率
        local minJie = PropertyCenter.GetValue(role, PropertyEnum.MinJie);
        local templateMinJie = PropertyCenter.GetValue(role, PropertyEnum.TemplateMinJie);
        local critAdd = PropertyCenter.GetValue(role, PropertyEnum.CritAdd);
        propertyCenter.Enum_Value[mainProperty] = Formulas_Battle.CalculateDodgeGenericFormula(PropertyEnum.Crit, templateMinJie, minJie, critAdd);
    end
end

PropertyCenter.MainProperty_AffectedProperties = {
    -- 九维影响
    [PropertyEnum.LiLiang] = {
        PropertyEnum.PhysicalDmg,
        PropertyEnum.ZhaoJia,
    },
    [PropertyEnum.TiPo] = {
        PropertyEnum.MaxHp,
        PropertyEnum.Weight,
    },
    [PropertyEnum.QiHai] = {
        PropertyEnum.MaxMp,
        PropertyEnum.JiQi,
    },
    [PropertyEnum.GanZhi] = {
        PropertyEnum.HuaQi,
        PropertyEnum.Dodge,
    },
    [PropertyEnum.LingXi] = {
        PropertyEnum.PoFang,
    },
    [PropertyEnum.MinJie] = {
        PropertyEnum.Crit,
    },

    -- 其他影响
    [PropertyEnum.WeaponDmg] = {
        PropertyEnum.PhysicalDmg,
    },
    [PropertyEnum.FaQiDmg] = {
        PropertyEnum.MagicalDmg,
    },
}


