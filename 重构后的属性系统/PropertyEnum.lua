PropertyEnum = {
    None = 0,

    -- 1. 只包含 Base 和 Add 和 Pct. 公式为 Main = (Base + Add) * (1 + Pct)
    -- 九维. Base 属性较为特殊, 限制到 0~100, 所以实际的公式为 Main = (Clamp(Base,0,100) + Add) * (1 + Pct)
    TiPo = 1000, -- 体魄
    TiPoBase = 10001,
    TiPoAdd = 10002,
    TiPoPct = 10003,

    LiLiang = 1001, -- 力量 
    LiLiangBase = 10011,
    LiLiangAdd = 10012,
    LiLiangPct = 10013,

    MinJie = 1002, --敏捷
    MinJieBase = 10021,
    MinJieAdd = 10022,
    MinJiePct = 10023,

    QiHai = 1003, -- 气海
    QiHaiBase = 10031,
    QiHaiAdd = 10032,
    QiHaiPct = 10033,

    LingXi = 1004, -- 灵犀
    LingXiBase = 10041,
    LingXiAdd = 10042,
    LingXiPct = 10043,

    GanZhi = 1005, -- 感知
    GanZhiBase = 10051,
    GanZhiAdd = 10052,
    GanZhiPct = 10053,

    WenTao = 1006, -- 文韬
    WenTaoBase = 10061,
    WenTaoAdd = 10062,
    WenTaoPct = 10063,

    WuLue = 1007, -- 武略
    WuLueBase = 10071,
    WuLueAdd = 10072,
    WuLuePct = 10073,

    CaiZhi = 1008, -- 才智
    CaiZhiBase = 10081,
    CaiZhiAdd = 10082,
    CaiZhiPct = 10083,

    -- 五行相性.
    JinXiangXing = 1009, -- 金相性
    JinXiangXingBase = 10091,
    JinXiangXingAdd = 10092,
    JinXiangXingPct = 10093,

    MuXiangXing = 1010, -- 木相性
    MuXiangXingBase = 10101,
    MuXiangXingAdd = 10102,
    MuXiangXingPct = 10103,

    TuXiangXing = 1011, -- 土相性
    TuXiangXingBase = 10111,
    TuXiangXingAdd = 10112,
    TuXiangXingPct = 10113,

    ShuiXiangXing = 1012, -- 水相性
    ShuiXiangXingBase = 10121,
    ShuiXiangXingAdd = 10122,
    ShuiXiangXingPct = 10123,

    HuoXiangXing = 1013, -- 火相性
    HuoXiangXingBase = 10131,
    HuoXiangXingAdd = 10132,
    HuoXiangXingPct = 10133,

    -- 其他一级父属性.
    WeaponDmg = 1014, -- 武器伤害
    WeaponDmgBase = 10141,
    WeaponDmgAdd = 10142,
    WeaponDmgPct = 10143,

    PhysRes = 1015, -- 物理抗性 
    PhysResBase = 10151,
    PhysResAdd = 10152,
    PhysResPct = 10153,

    FaQiDmg = 1016, -- 法器伤害
    FaQiDmgBase = 10161,
    FaQiDmgAdd = 10162,
    FaQiDmgPct = 10163,

    DaJi = 1017, -- 打击值
    DaJiBase = 10171,
    DaJiAdd = 10172,
    DaJiPct = 10173,

    ZhaoJiaMul = 1018, -- 招架倍率
    ZhaoJiaMulBase = 10181,
    ZhaoJiaMulAdd = 10182,
    ZhaoJiaMulPct = 10183,

    CritMul = 1019, -- 暴击倍率
    CritMulBase = 10191,
    CritMulAdd = 10192,
    CritMulPct = 10193,

    CdReduc = 1020, -- 冷却缩减
    CdReducBase = 10201,
    CdReducAdd = 10202,
    CdReducPct = 10203,

    TalentPhysDmgPct = 1021, -- 天赋物伤加成率
    TalentPhysDmgPctBase = 10211,
    TalentPhysDmgPctAdd = 10212,
    TalentPhysDmgPctPct = 10213,

    TalentMagicDmgPct = 1022, -- 天赋法伤加成率
    TalentMagicDmgPctBase = 10221,
    TalentMagicDmgPctAdd = 10222,
    TalentMagicDmgPctPct = 10223,

    -- 2. 包含 其他父属性 或者 特殊构成值 作为依赖. 公式各不相同. 
    MaxHp = 2000, -- 最大体力
    TemplateMaxHp = 20001, -- 模板最大体力

    MaxMp = 2001, -- 最大灵力

    PhysicalDmg = 2002, -- 物理伤害
    TemplatePhysicalDmg = 20021, -- 模板物理伤害

    MagicalDmg = 2003, -- 法术伤害
    TemplateMagicalDmg = 20031, -- 模板法术伤害

    JiQi = 2004, -- 集气

    HuaQi = 2005, -- 化气

    Weight = 2006, -- 重量
    WeightBase = 20061,
    WeightAdd = 20062,

    Dodge = 2007, -- 闪避
    DodgeAdd = 20072,
    TemplateGanZhi = 20073, -- 模板感知

    PoFang = 2008, -- 破防
    PoFangAdd = 20082,
    TemplateLingXi = 20083, -- 模板灵犀

    ZhaoJia = 2009, -- 招架
    ZhaoJiaAdd = 20092,
    TemplateLiLiang = 20093, -- 模板力量

    Crit = 2010, -- 暴击
    CritAdd = 20102,
    TemplateMinJie = 20103, -- 模板敏捷
}
