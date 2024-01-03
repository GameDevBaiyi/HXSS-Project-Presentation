华夏史诗战国, 个人负责项代码展示, 主要展示 Lua 语言. 

1. 角色属性系统重构. 角色属性系统是 RPG 游戏中的底层构筑, 没有一个系统化的框架, 对于属性的监测, Buff 等依赖系统的实现会造成很大的困难. 

之前的属性系统: AttributeDataBase 和 RoleData. 违背了 Single Resposibility 原则. 接口不统一化. 未考虑属性之间的关联. 

重构后的属性系统(实际上 ET 内置的属性管理框架也是这一套): PropertyCenter. 获取属性, 修改属性, 属性公式 的接口统一化. 属性之间的关联系统化(将属性构成分成主属性和子属性). 
