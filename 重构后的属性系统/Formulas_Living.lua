Formulas_Living = {}
-- 大世界触碰逃跑几率：自身敏捷 / （敌方最高敏捷 + 自身敏捷）；
function Formulas_Living.CalculateWorldEscapeRate(selfMinJie, hightestEnemyMinJie)
    return selfMinJie / (selfMinJie + hightestEnemyMinJie);
end
