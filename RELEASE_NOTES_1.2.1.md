# YumEdit 1.2.1 (build 12)

## 简体中文

**旧机型 Siri AI 方法重构：感谢 [@snow_femos](https://x.com/snow_femos) 打破长期沿用的 GestaltEdit 式硬件伪装路线。** YumEdit 现在保留设备真实产品、板号与 CPU，按真实机型严格匹配国行或欧版监管型号，再写入美版销售区域和对应监管型号。iOS 27 上的已适配旧款 iPhone 另写入 `SiriMode=2` 与生成式模型能力标记 `1`。写入后请完整重启设备。

- 主页自动读取机型、缓存产品型号、监管型号和销售地区；旧机型额外显示 SiriMode 与生成式能力值。国行／欧版改为左右切换，目标值已写入时主按钮禁用。
- 旧版硬件伪装可从历史备份恢复真实身份，再应用新方法。逐份核对设备、`CacheData`、`CacheUUID`、板号和 CPU；找不到可信备份就拒绝自动恢复。
- 实验页移除独立 SiriMode 与 Face ID 排障入口，改为“还原回对应机型并修改美版”。保留外接屏等独立实验功能。
- 核对了已适配 iPhone、iPad 与 iPhone Duo 的监管型号映射；新增文案覆盖现有 26 种语言。每次写入前备份，写后读回校验，失败时尝试恢复原缓存。

用户在 iPhone 13 Pro 上报告完整重启后出现 Apple Intelligence 入口。其他机型与 Siri AI 服务可用性仍需分别验证。安装包未签名；重新签名时须保留 App Group 权限。

## English

**A new Siri AI path for older devices, inspired by [@snow_femos](https://x.com/snow_femos), moves beyond the longstanding GestaltEdit-style hardware spoofing approach.** YumEdit now keeps the real product, board and CPU identity. It checks the physical model against the original sales region and regulatory model, then writes the matching US region and model. On mapped older iPhones running iOS 27, it also sets `SiriMode=2` and the generative-model capability flag to `1`. A full reboot is required.

- The home screen reads the current model, cached product, regulatory model and sales region. Older models also show the SiriMode and generative capability cache values. A China/EU segmented selector replaces the toggle, and the main action is disabled once all target values are present.
- Devices modified by the older spoofing flow can recover their real identity from a verified historical backup before applying the new method. Backups must match the device, `CacheData`, `CacheUUID`, board and CPU; otherwise automatic recovery is refused.
- The experiments page replaces the separate SiriMode and Face ID troubleshooting actions with a restore-and-switch-to-US action. External display experiments remain separate.
- Mappings for supported iPhones, iPads and iPhone Duo were reviewed. New interface text covers the existing 26 languages. Writes are backed up and read back for verification, with rollback attempted on failure.

A user reported that the Apple Intelligence entry appeared on an iPhone 13 Pro after a full reboot. Other devices and Siri AI service availability still require their own testing. The IPA is unsigned; preserve the App Group entitlement when signing it.

Asset: `YumEdit-1.2.1-b12-unsigned.ipa`
