# YumEdit

**实验性 App：专为 CH/A 国行 iPhone 尝试启用 Siri AI。** 修改的是系统 MobileGestalt 缓存，可能造成系统异常或需要恢复设备。使用前务必备份整机。界面参考 SideInstaller 的深色蓝色渐变与玻璃卡片；没有复制其代码或资源。

## 行为

- 原生 Siri AI iPhone：按 GestaltEdit 的机型映射，只改 `CacheExtra` 的国家码、销售区域与监管型号。
- 旧机型实验模式：iOS 27+、iPhone 11 起、非原生 AI 型号；可选择 iPhone 15 Pro 至 iPhone 17 系列的已知 Siri AI 机型。在全屏红色风险确认后，额外伪装产品、硬件与 CPU 型号，并设置 `SiriMode = 2`。**可能失去 Face ID、发生循环重启或需要恢复设备；功能未经真机验证。**
- 写入前把原始 plist 保存到应用 Documents/GestaltBackups，读回验证备份；主文件参照 BQTool 的原位写入方式保留 inode，再读回验证完整数据及关键字段。写入或验证失败时尝试原位恢复原始数据。
- 1.0.0 增加恢复按钮：恢复最近一次由 YumEdit 保存的 MobileGestalt plist，并在恢复前另存当前缓存。若安装 YumEdit 前已用其他工具改过设备、因而没有 YumEdit 备份，可从“文件”导入**同一设备**的原始 plist 再恢复。备份本身若已被修改，恢复后也仍是修改后的状态；本工具无法凭空生成出厂 plist，也不会故意破坏缓存以触发系统重建。恢复后需重启。
- 按钮有应用内合成的轻触音效。
- 未知型号或区域字段异常时拒绝写入。新型号需核实对应美版监管型号后才能加入映射。

## 构建与签名

打开 `YumEdit.xcodeproj`。目标默认 Team ID 为 B2F9932GMA、Bundle ID 为 `com.hyumpix.yumedit`，App Group 为 `group.com.hyumpix.yumedit`。签名 profile 必须授权至少一个 App Group；App 会读取签名中实际授予的组名。P12 证书本身不会授予 App Group，若侧载工具移除该权限，漏洞无法运行。iPhone Duo 窗口采用最大 600pt 的居中布局。

本项目基于 forcequitOS/worse_query 的 GPL-3.0 漏洞 PoC，并保留其 LICENSE。界面及区域写入逻辑为新实现。监管型号表参考 frs0n/GestaltEdit；伪装硬件型号和芯片映射参考 libimobiledevice/libirecovery；SiriMode 键参考 PoomSmart/MGKeys。未在真机执行写入，也未验证 Siri AI 服务端资格。请先完成整机备份。
