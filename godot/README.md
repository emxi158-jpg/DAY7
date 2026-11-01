# 第七日 · 等待室

当前场景阶段交付日期：2026-11-01。[交付说明](../docs/场景阶段交付_20261101.md)。

用 **Godot 4.6 / Forward+** 导入本目录的 `project.godot`，等待资源导入完成后按 **F5** 运行完整项目。

## 操作

| 操作 | 按键 |
| --- | --- |
| 移动、观察 | WASD、鼠标 |
| 交互 | E |
| 挂钟 | E 打开面板，选择时针或分针后输入数值 |
| 切换验证用 Loop | 1–4 |
| Loop 3 砸坏龙头 | Shift+E |
| 放下柜门把手 | G |
| Loop 4 同款挂钟放大 | L |
| 回到等待室 | R |
| 释放鼠标、关闭钟针面板 | Esc |

## 编辑位置

建筑、家具、灯光位于 `room_decor.scn`；交互资产位于 `assets/finished/`；游戏逻辑位于 `scripts/`。

- 墙色：`assets/materials/user_wall_20261029/Plaster.tres`。
- 环境：IndoorEnvironment，曝光 0.27、环境光能量 1.0。
- 小射灯：Lighting / ClockSconce_Warm，强度 4.8。
- 管线：Architecture / ElectricalServices_CleanRouting。
- 柜体受光修正：`assets/materials/locker_enamel_normal_corrected.gdshader`。

## 当前检查

在项目路径下，用 Godot 的无窗口模式运行：

```
godot --headless --path . --script res://tests/verify_assets.gd
godot --headless --path . --script res://tests/verify_three_sources.gd
```

其余较早的制作对照记录应结合对应阶段的文档使用。
