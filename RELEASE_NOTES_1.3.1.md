# YumEdit 1.3.1 (build 17)

相较于 1.2.1：

- 重做旧机型开启流程：先写入美区销售字段、SiriMode、生成式模型能力和三处已知 CacheData 槽位。临时伪装 ProductType 由用户选择；下载完成后，可从同设备可信历史备份恢复真实机型，保留能力与区域字段。已写入能力值的设备仍可进入两阶段页面补做临时伪装。
- 对扩图能力字段异常提供检测与修正入口；恢复真实机型后突出提示不要进入「设置 → Siri」。
- 主入口不再限定国行和欧版；实验性机型伪装支持产品标识、板号、CPU、监管型号和销售地区组合，并在型号旁显示易读名称。无法核实目标监管型号时拒绝写入。
- 补齐旧 iPad 机型识别、调整主页纵向布局，在信息按钮上直接显示版本和构建号，并更新界面翻译。

IPA 未签名；签名时须保留 App Group 权限。旧机型两阶段及部分实验性功能的最终效果尚需更多真机验证。写入前请备份整机，每阶段写入后完整重启。

## English

Compared with 1.2.1, this release redesigns the older-device flow. It writes US sales fields, SiriMode, generative-model capability and three known CacheData slots. Temporary ProductType spoofing is optional; after resource download, the real model can be restored from a verified backup of the same device while preserving capability and region fields. Devices that already have the capability fields can still enter the flow and choose temporary spoofing.

It also adds detection and repair for two anomalous Photos capability values, a prominent warning against opening Settings → Siri after restoring the real model, broader region eligibility, a guarded advanced spoofing form, more iPad identifiers, improved layout, visible version/build information and updated translations.

The IPA is unsigned and requires App Group entitlement when signed. Back up the device and reboot after each write. Final behavior of the older-device flow and some experimental options needs further device testing.
