# YumEdit 1.3.0 (build 13) — 实验性预发布

旧机型增加明确标注为**实验性**的两阶段流程：

1. 临时伪装为选定机型，写入美区销售字段及整数 `SiriMode = 2`；自动保存并校验操作前的完整 MobileGestalt plist。完整重启后，等待系统资源下载。
2. 用户确认下载完成后，从同一设备、同 `CacheData` 和 `CacheUUID` 的历史备份中恢复真实产品、板号、CPU 和原监管型号；保留当前美区销售字段与 SiriMode。找不到可信备份时拒绝写入。再次完整重启，测试 Face ID、听写及 Apple Intelligence。

此流程**不会自动写入或修改** `DeviceSupportsGenerativeModelSystems`；预设中的该字段快捷项已移除。旧版本曾自动写入它，1.3.0 不会自动撤销既有修改。字段编辑器仍允许用户自行编辑。

已补齐两阶段流程的 26 种界面语言文案。IPA 是**未签名包**；侧载时需保留 App Group 权限。两阶段恢复后的 Siri AI 可用性尚未验证；下载进度不代表功能已启用。请先备份整机。

## English

**Experimental prerelease.** Older supported iPhones now have a two-stage flow: temporarily spoof a selected model to request system resources, then, after the user confirms the download, restore the real product, board, CPU, and original regulatory model from a verified backup of the same device, CacheData, and CacheUUID. Sales region and SiriMode remain unchanged in stage two. Each write creates and verifies a full plist backup; missing trusted backups block restoration.

The flow does **not** automatically write or change `DeviceSupportsGenerativeModelSystems`. Its preset shortcut has been removed. Previous releases may have changed this field; 1.3.0 does not undo those changes. The IPA is unsigned and requires App Group entitlement when signed. Reboot after each stage and test Face ID, dictation, and Apple Intelligence. Resource download and final functionality remain unverified.
