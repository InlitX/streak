# Streak 鸿蒙版 GPLv3 商业化设计文档

> 状态：已批准方向（2026-11-05，四项决策见下）。执行排期在 Phase 1 收尾之后。
> 性质：合规 + 上架实施计划，不改变 Phase 1 代码工作。

## 决策记录（用户拍板，2026-11-05）

| 决策点 | 结论 |
|---|---|
| 商业化路线 | GPLv3 合规商用（公开源码 + 商店分发） |
| 品牌 | **日新 / Renew**（2026-11-05 定名，源自《礼记·大学》"苟日新，日日新，又日新"） |
| 收费模式 | 先免费上架，暂不考虑收费 |
| 开发者身份 | 华为个人开发者 |
| 平台范围 | HarmonyOS（AGC）首发；Android/桌面维持现状 |

## 1. 法律边界（不展开，只列约束）

- 上游 InlitX/streak 为 GPLv3；本仓库是演绎作品，必须以 GPLv3 整体发布。
- 你不是唯一版权人（InlitX + Weblate 众译者），**不存在闭源双许可路径**。
- GPLv3 义务触发点是"分发"：上架 AGC 的那一刻，对应版本的完整源码必须可获得。
- 免费上架同样是分发，义务相同；只是无收费环节。
- iOS 不在范围（GPL 与 App Store 条款冲突）。

## 2. GPL 合规模块（P0，代码/仓库层面，可立即开工）

### 2.1 署名与声明
- README 顶部加 fork 声明：基于 `InlitX/streak`（GPLv3），由 chenbf 做鸿蒙适配，注明修改年份（§5a 要求）。
- `about_page.dart` 改造（当前链接指向 InlitX/streak）：
  - 保留原作者署名 "Original: InlitX — github.com/InlitX/streak"；
  - 追加 "HarmonyOS adaptation: chenbf — github.com/<your-fork>"；
  - 保留现有 LICENSE 入口（`about_page.dart:241`）。
- `LICENSE` 原样保留；源码文件头部版权行不动。
- 翻译贡献者：Weblate 译者名单若上游有 CREDITS/TRANSLATORS 文件则保留。

### 2.2 源码公开工作流
- 仓库设为 Public（GitHub, InlitX/streak 的 fork 或独立仓）。
- 每次上架打 tag（`v<version>-ohos.<n>`），HAP 必须能从 tag 复现（pubspec.lock 已全 pin，满足）。
- 推送纪律（已写入 notes.md triage）：永不 `git add -A`；`ohos/build-profile.json5` 的签名块只在本地；推送前 `git status` 只剩这一个有意修改。
- 历史清白检查：推送前 `git log -p --all | grep -i "password\|certpath"` 抽样确认无密钥入史。

## 3. 品牌模块（P0，上架前必须完成）

**新名称：日新 / Renew（已定，2026-11-05）。** 核查记录（2026-11-05）：
- 习惯打卡品类内无同名 app（web 检索未见"日新"打卡产品，仅有掘金"日新计划"活动名）；
- GitHub 无同名知名项目（"rixin"检索均为个人小仓库）；
- 域名：rixin.app 未注册（可用），rixin.cn / rixin.com 已被注册；
- 商标：web 检索显示"日新"字样在第 9 类存在相关记录（约 41 条相关商标信息，如"商场日日新"）——**CNIPA 官方库的正式精查仍未做，上架前必须完成**（中国商标网 sbj.cnipa.gov.cn 需交互验证码，须人工）。

改名触及点（一次任务可完成）：
- `ohos/AppScope/app.json5`: `bundleName` com.streak.streak → 新 id（**注意：bundle id 变更是新应用，需重新在 AGC 创建应用和签名 profile**）；
- `ohos/AppScope/resources/base/element/string.json` + `entry/src/main/resources/{base,en_US,zh_CN}/element/string.json`：应用显示名；
- 图标：`ohos/AppScope/resources/base/media/app_icon.png` + `entry/.../media/icon.png`（新设计）；
- `pubspec.yaml` `name:` 可保留（Dart 包名不外显）；
- Android `applicationId` 若后续上架 Android 渠道再议（本期不动）；
- 应用内标题/关于页文案。

## 4. 上架模块（P1，Phase 2 期间并行准备）

### 4.1 账号与资质（用户本人操作，无法代办）
1. 华为开发者联盟注册 + 个人实名认证（身份证，1-2 工作日审核）。
2. AGC 创建应用（新 bundle id，HarmonyOS 应用）。
3. 生成发布证书：AGC → 证书管理 → 创建发布证书（.cer）+ 发布 profile（.p7b），本地 .p12 用 DevEco 生成。
4. App 备案：工信部 ICP App 备案（AGC 后台入口，需实名后提交，审核约 1-2 周——**这是关键路径，最早启动**）。

### 4.2 构建与签名（代码/配置）
- `ohos/build-profile.json5` 增加 release signingConfig（本地保留，沿用现有"提交时剥离"纪律，备份到 D:\ohos-tmp）。
- Release 构建：`flutter build hap --release`；上架包需要 `.app`（App Pack）格式 —— 验证 hvigor `assembleApp --mode module -p product=default -p buildMode=release` 产出路径，写进 notes.md。
- Release 体积与混淆：确认 R8/代码混淆对 fork 的适用性；记录最终包体（debug 176 MB 无参考价值）。

### 4.3 隐私与审核材料
- 隐私政策页面：数据全部本地存储（Hive，path_provider 文档目录），仅声明 INTERNET 权限，无账号系统、无统计 SDK —— 政策文本可以很简短，托管在 GitHub Pages / 仓库 md 直接引用。
- 权限说明：INTERNET（用途：分享/链接打开）；Phase 2 加通知后再补 POST_NOTIFICATIONS。
- 商店素材：4-5 张截图（真机 1320×2760 直接可用）、应用介绍（zh+en）、分类（效率）、年龄分级。
- 隐私标签：AGC 后台按实际勾选（不收集 = 全否）。

## 5. 时间表

```
现在          Phase 1 收尾（Task 7 验收，进行中）
P0 立即        §2 合规模块（README/关于页/推送纪律）—— 可并行开工
P0 用户侧      定新名称；注册华为开发者 + 实名认证；提交 App 备案（关键路径 1-2 周）
P1 Phase 2    通知/时区适配等 functional gap 补齐
P1 并行        §3 品牌模块（改名换图标）；§4.2 release 构建验证
P2 上架        §4.3 材料 → AGC 提审 → 上架
明确不做       收费/IAP、企业认证、iOS、服务卡片（后续版本再议）
```

## 6. 风险

| 风险 | 缓解 |
|---|---|
| 备案审核周期不可控 | 账号下来第一天就提交，不等功能完 |
| 同名应用商店撞车 | 改名换牌已规避；上架前 AGC 搜一遍候选名 |
| 用户投诉"抄袭开源应用" | README + 关于页 + 商店介绍三处显著署名 |
| 发布证书丢失 | .p12/.cer/.p7b 备份到 D:\ohos-tmp 之外的持久位置（用户自选云盘/U盘），丢证 = 无法更新已上架应用 |
| GPL 合规瑕疵被举报 | 每次上架对应 tag 可复现；源码仓保持 Public |
