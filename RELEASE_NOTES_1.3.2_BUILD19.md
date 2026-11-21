# YumEdit 1.3.2（build 19）

- 主页固定新增「覆写为美版」开关，默认开启。
- 关闭时，原生支持机型保持当前销售地区且不执行区域写入。
- 关闭时，旧机型第一阶段保留原 `CountryCode / RegionInfo`；临时伪装使用原销售地区对应的监管型号，第二阶段恢复真实机型与原行货监管型号。
- 开启时写入 `LL / LL/A`，临时与真实机型均匹配对应美版监管型号。
- 两阶段流程统一显示为「两步一键开启苹果智能」；原「实验性选项」入口改称「高级选项」。
- 设备状态卡扩大并支持区域内滚动，增加系统版本、硬件身份与开启方式信息。
- 「恢复最近一次备份」与 Respring 按钮等高，主页移除恢复按钮中的 `plist` 字样。

两阶段写入仍属于高风险操作。请先完成整机备份，并在真机上逐阶段验证。

IPA 未签名；签名时须保留 App Group 权限。旧机型两阶段流程的最终效果仍需真机验证。

## English

- Added a home screen switch to overwrite the sales region as US, enabled by default.
- With the switch off, natively supported devices skip region writes. Older devices retain their original sales region during the first stage; regulatory models match the selected temporary device and current region, then return to the original device model in the second stage.
- Renamed the two-step Apple Intelligence flow and advanced options, expanded the scrollable device status card, and aligned the restore and Respring buttons.

The IPA is unsigned and requires the App Group entitlement when signed. Back up the device before writing. The older-device flow still needs verification on a physical device.
