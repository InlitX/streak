<div align="center">

<img src="assets/icon.svg" width="120" alt="Streak 标志" />

# Streak

### 一款用 Flutter 打造的极简、私密、无广告的习惯追踪应用

一键记录习惯，保持势头，看着你的连续记录不断增长。

<br/>

<p>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white" />
  <img alt="Android" src="https://img.shields.io/badge/Android-3DDC84?style=flat&logo=android&logoColor=white" />
  <img alt="MIT 许可证" src="https://img.shields.io/badge/License-MIT-7C3AED?style=flat&logo=opensourceinitiative&logoColor=white" />
  <img alt="无广告、无追踪" src="https://img.shields.io/badge/No%20ads%20%C2%B7%20No%20tracking-22C55E?style=flat&logo=shield&logoColor=white" />
</p>

<br/>

<a href="https://f-droid.org/packages/com.streak.app/"><img alt="在 F-Droid 上获取" src="assets/badges/get-it-on-fdroid.png" height="60" /></a>
&nbsp;
<a href="https://github.com/InlitX/streak/releases"><img alt="在 GitHub 上获取" src="assets/badges/get-it-on-github.png" height="60" /></a>

<br/>
<br/>

[English](README.md) · [Español](README.es.md) · **中文**

</div>

---

> [!TIP]
> **完全属于你。** 无需账号、无订阅、无广告、无追踪。
> 每个习惯和设置都保存在你的设备上，而且全部源代码开放。

## 概览

Streak 是一款尊重你的习惯追踪应用。你可以创建任意多个习惯，一键记录，并通过类似
GitHub 的活动网格、连续记录计数器和统计面板来跟踪你的进度。它快速、可离线使用，
并且力求让人感到平静，而非催促。

---

## 截图

<p align="center">
  <img src="docs/screenshots/01-today.png" alt="今天" width="150" />
  <img src="docs/screenshots/02-stats.png" alt="统计" width="150" />
  <img src="docs/screenshots/03-insights.png" alt="洞察" width="150" />
  <img src="docs/screenshots/04-customize.png" alt="个性化" width="150" />
  <img src="docs/screenshots/05-free.png" alt="免费且私密" width="150" />
</p>

<div align="center"><sub><b>今天</b> · <b>统计</b> · <b>洞察</b> · <b>个性化</b> · <b>免费且私密</b></sub></div>

---

## 下载

最简单的方式是 [**F-Droid**](https://f-droid.org/packages/com.streak.app/)，它会安装
Streak 并自动保持更新。

想要直接下载 APK？前往 [**Releases**](https://github.com/InlitX/streak/releases) 页面获取。
构建按 CPU 架构拆分，以保持每个下载包都很小——请选择与你手机匹配的版本（大多数
现代设备为 **arm64-v8a**）：

| APK | 适用于 |
|-----|--------|
| `Streak-arm64-v8a.apk` | 现代 64 位手机（推荐） |
| `Streak-armeabi-v7a.apk` | 较旧的 32 位设备 |
| `Streak-x86_64.apk` | 模拟器 / x86 平板 |

> [!NOTE]
> Streak 未上架 Play 商店。由于该 APK 不是来自应用商店，Android 在首次安装时
> 可能会要求你允许从浏览器或文件管理器安装。

---

## 功能

<table>
<tr>
<td width="50%" valign="top">

**追踪**
- 在主屏幕一键记录
- 每日、每周和每月目标
- 当前连续记录与最佳连续记录计数器
- 基于近期坚持度的习惯“强度”

</td>
<td width="50%" valign="top">

**可视化**
- 类似 GitHub 的活动网格（周 / 月 / 年）
- 带趋势和总计的统计面板
- 可分享的进度卡片，导出为精美图片

</td>
</tr>
<tr>
<td width="50%" valign="top">

**个性化**
- 极简图标包并支持表情符号
- 自定义强调色，配有完整取色器
- 浅色 / 深色主题以及可选背景
- 分类、重新排序、个人资料名称和头像

</td>
<td width="50%" valign="top">

**数据与平台**
- 按你选择的日期为每个习惯设置提醒
- 以便携 JSON 文件备份和恢复
- 三个主屏幕小组件
- 支持英语和西班牙语，完全离线

</td>
</tr>
</table>

---

## 技术栈

| 方面 | 选择 |
|------|------|
| 框架 | Flutter (Dart) |
| 状态管理 | provider |
| 本地存储 | hive_ce |
| 图表 | fl_chart |
| 通知 | flutter_local_notifications + timezone |
| 主屏幕小组件 | home_widget + Jetpack Glance (Kotlin) |
| 图标 | Lucide |

---

## 项目结构

<details open>
<summary><b>目录布局</b></summary>

```
lib/
├── main.dart                 应用入口与主屏幕小组件回调
├── app/                      应用外壳、导航宿主与主题
│   └── theme/                调色板、设计令牌、浅色/深色主题
├── core/                     横切的基础模块
│   ├── database/             本地持久化（Hive）
│   ├── extensions/           日期辅助方法
│   ├── i18n/                 本地化字符串
│   ├── icons/                图标与表情符号目录
│   ├── routing/              导航与页面过渡
│   ├── utils/                Snackbar 与辅助工具
│   └── widgets/              共享的 UI 基础组件
├── features/                 以功能为先的模块
│   ├── habits/               data · state · pages · widgets
│   ├── statistics/           统计面板
│   ├── settings/             偏好设置与关于
│   └── onboarding/           首次启动体验
└── services/                 通知、主屏幕小组件、备份

android/                      Android 宿主工程与小组件布局
assets/                       应用图标与内置图片
fonts/                        Figtree 与 Playfair Display
docs/screenshots/             本 README 中使用的宣传截图
tool/                         图标生成脚本（仅开发用）
```

</details>

---

## 快速开始

### 前置条件

- Flutter SDK（stable 通道）
- Android Studio 或 Android SDK，并准备一台设备或模拟器

### 运行

```bash
git clone https://github.com/InlitX/streak.git
cd streak
flutter pub get
flutter run
```

### 构建发布版 APK

```bash
# 每种架构一个 APK（arm64-v8a、armeabi-v7a、x86_64）
flutter build apk --release --split-per-abi
```

推送 `v*` 标签会触发 GitHub Actions 工作流，构建这些拆分的 APK 以及一个源代码
压缩包，并将它们附加到新的 GitHub Release。

> [!TIP]
> 要为发布版构建签名，请创建 `android/key.properties` 并填入你的 keystore 信息。
> 该文件和任何 keystore 都被有意地加入了 git 忽略；如果没有它们，发布版构建会
> 回退到调试签名密钥。

---

## 架构说明

- **以功能为先的布局。** 每个功能都拥有自己的数据模型、状态控制器、页面和
  组件，使边界清晰。
- **单一数据源。** 习惯、分类和设置都持久化在 Hive 中，并通过 `ChangeNotifier`
  控制器对外暴露。
- **健壮的存储。** 损坏或与结构不匹配的记录会被跳过，而不是使启动崩溃；非关键的
  启动工作（通知、小组件）被隔离，因此绝不会阻止应用启动。
- **一致的导航。** 每次跳转都经过单一的 navigator，并使用不透明的页面过渡，
  因此屏幕在动画期间绝不会相互透出。

---

## 隐私

> [!IMPORTANT]
> Streak **没有任何分析统计、没有广告 SDK，也没有网络后端**。
> 应用绝不会将你的数据发送到任何地方——它们都留在你的设备上。唯一的对外操作
> 是你自己选择打开的链接。

---

## 支持

<div align="center">

如果 Streak 帮助你更常坚持下来，一个 star 或一杯咖啡都意义重大：

<a href="https://github.com/InlitX/streak"><img src="https://img.shields.io/badge/Star%20on%20GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="在 GitHub 上加 Star" height="38" /></a>
&nbsp;&nbsp;
<a href="https://ko-fi.com/inlitx"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="在 Ko-fi 上支持我" height="38" /></a>

</div>

---

## 贡献

欢迎提交 issue 和 pull request。对于较大的改动，请先开一个 issue 讨论方向。

---

## 许可证

基于 [MIT 许可证](LICENSE) 发布。
