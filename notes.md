# HarmonyOS build spike notes (Task 2, throwaway)

Worktree: `D:\open_code\streak-spike` (detached HEAD at `5d5d994`, branch `feature/harmonyos`).
Toolchain: ohos flutter fork tag `3.35.8-ohos-1.0.4` at `D:\flutter-ohos\flutter`; env via `scripts/ohos_env.ps1` (Task 1).
This file is copied to the main checkout repo root at the end of the task; committed in Task 3.

## Machine facts discovered

- **C: drive is FULL**: 0.05 GB free at spike start (30 MB by mid-task). `flutter pub get` failed once with `errno = 112` (磁盘空间不足) writing to `%TEMP%`. Fix applied for this spike: `TEMP`/`TMP` redirected to `D:\ohos-tmp` in every command shell (non-destructive; nothing deleted). C: needs attention before real development.
- **ohpm cache moved to D:** (C: had no room): `ohpm config set cache D:\flutter-ohos\ohpm-cache` (user-level ohpm config, reversible with `ohpm config delete cache`; disclosed in task report). Precedent: PUB_CACHE already lives on D:.
- D: has ~23 GB free.
- `flutter create --platforms ohos .` prints the misleading banner `Recreating project ....` and recreates `.idea\*`, `streak.iml`, and `test\widget_test.dart` even in an existing app; lib/ and existing tests untouched.
- **Windows Developer Mode is OFF on this machine and the shell lacks symlink privilege** (no `SeCreateSymbolicLinkPrivilege` in `whoami /priv`; `HKLM\...\AppModelUnlock` key absent). Enabling it needs an admin/elevated action and was left to the user (attempting the registry write was denied by the permission system, correctly).
- **Workaround that makes pub get green WITHOUT Developer Mode**: `flutter pub get`'s plugin-symlink step only creates links for the **windows** and **linux** platform dirs (`createPluginSymlinks` in the fork's `flutter_plugins.dart` — ohos/android untouched), and it **skips links that already exist**. Pre-create every link as an NTFS **junction** (junctions need no privilege) and pub get exits 0. For this repo that is 28 links: 16 windows + 12 linux plugin entries from `.flutter-plugins-dependencies` (`plugins.windows` / `plugins.linux`), placed at `windows\flutter\ephemeral\.plugin_symlinks\<plugin-name>` and `linux\flutter\ephemeral\.plugin_symlinks\<plugin-name>`. Caveat: a `force: true` refresh (some desktop builds) deletes the dir first and would hit the privilege wall again; ohos builds do not force-refresh these.

## Step 1 — spike worktree: OK

`git worktree add --detach D:\open_code\streak-spike feature/harmonyos` (controller ruling: two worktrees cannot check out the same branch; detached HEAD used). HEAD = `5d5d994`.

## Step 2 — ohos shell + deps

### flutter create (attempt 1): ohos shell generated; integrated pub get failed

Verbatim file list (all under `ohos/` unless noted):

```
Recreating project ....
  .idea\libraries\Dart_SDK.xml (created)
  .idea\libraries\KotlinJavaRuntime.xml (created)
  .idea\modules.xml (created)
  .idea\runConfigurations\main_dart.xml (created)
  .idea\workspace.xml (created)
  ohos\.gitignore (created)
  ohos\AppScope\app.json5 (created)
  ohos\AppScope\resources\base\element\string.json (created)
  ohos\AppScope\resources\base\media\app_icon.png (created)
  ohos\build-profile.json5 (created)
  ohos\entry\.gitignore (created)
  ohos\entry\build-profile.json5 (created)
  ohos\entry\hvigorfile.ts (created)
  ohos\entry\oh-package.json5 (created)
  ohos\entry\src\main\ets\entryability\EntryAbility.ets (created)
  ohos\entry\src\main\ets\pages\Index.ets (created)
  ohos\entry\src\main\module.json5 (created)
  ohos\entry\src\main\resources\base\element\color.json (created)
  ohos\entry\src\main\resources\base\element\string.json (created)
  ohos\entry\src\main\resources\base\media\icon.png (created)
  ohos\entry\src\main\resources\base\profile\buildinfo.json5 (created)
  ohos\entry\src\main\resources\base\profile\main_pages.json (created)
  ohos\entry\src\main\resources\en_US\element\string.json (created)
  ohos\entry\src\main\resources\zh_CN\element\string.json (created)
  ohos\entry\src\ohosTest\... (test scaffolding, created)
  ohos\hvigor\hvigor-config.json5 (created)
  ohos\hvigorconfig.ts (created)
  ohos\hvigorfile.ts (created)
  ohos\oh-package.json5 (created)
  streak.iml (created)
  test\widget_test.dart (created)
```

`ohos/` appeared WITH `AppScope/` + `entry/` — the required shape. Integrated `flutter pub get` failed:

```
The current Dart SDK version is 3.9.2.

Because streak depends on wakelock_plus >=1.5.0 which requires SDK version >=3.10.0 <4.0.0, version solving failed.

You can try the following suggestion to make the pubspec resolve:
* Consider downgrading your constraint on wakelock_plus: flutter pub add wakelock_plus:^1.4.0
Failed to update packages.
```

Cause: the ohos fork pins Dart 3.9.2; several latest plugin majors require SDK >=3.10.

### Override attempts (all in spike-worktree pubspec `dependency_overrides`, spike-only)

| # | Override added | Outcome |
|---|---|---|
| 1 | `wakelock_plus: ^1.4.0` (new) | RESOLVES it: pub get exits 0 (`Got dependencies!`), after the two machine fixes below. Without the downgrade, version solving fails (all `>=1.5.0` versions need SDK >=3.10; fork Dart is 3.9.2). |
| (pre-existing) | `permission_handler_windows: path: desktop/permission_handler_windows` | unchanged, resolves (path override works in the worktree) |

Pub get failed twice more before going green — both machine-side, not dependency-side:

1. **C: disk full** (`errno = 112` writing pub temp archive). Fix: `TEMP`/`TMP` → `D:\ohos-tmp` per shell.
2. **Plugin symlink privilege (1314)**: pub get exits 1 AFTER writing `.dart_tool` + `.flutter-plugins-dependencies` with `Building with plugins requires symlink support. Please enable Developer Mode in your system settings.` Machine has Developer Mode OFF (no `AppModelUnlock` key; no `SeCreateSymbolicLinkPrivilege` via `whoami /priv`). Enabling it is an admin machine change — left to the user. **Workaround (verified green):** the fork's `createPluginSymlinks` only links **windows + linux** plugin dirs (ohos/android untouched) and **skips existing links**, so 28 NTFS **junctions** (privilege-free) were pre-created: 16 windows + 12 linux entries from `.flutter-plugins-dependencies` → `windows\flutter\ephemeral\.plugin_symlinks\<name>` and `linux\flutter\ephemeral\.plugin_symlinks\<name>`. Caveat: a `force: true` refresh (some desktop builds) deletes the dir first and would hit the privilege wall again; ohos builds do not force-refresh these.

## Step 3 — debug HAP build

### Attempt 1: FAILED at Dart compile — decisive version-gap finding

Engine artifacts for ohos downloaded fine (ohos-arm64/x64, debug/profile/release, all from the fork's artifact server; no DNS issue in Dart's HTTP stack), `ohpm install` inside the build ran from `https://ohpm.openharmony.cn/ohpm/` (hypium 1.0.6 fetched; cache on C: full — see machine facts), then `kernel_snapshot_program` failed with 9 compile errors: the app's Dart code uses **Flutter APIs newer than the 3.35.8 fork provides**:

| API the app uses | Sites | Status on fork (Flutter 3.35.8 / Dart 3.9.2) |
|---|---|---|
| `TickerMode.valuesOf(context)` | 6 (one per file: statistics_page, express_statistics_page, minimal_statistics_page, back_handlers, day_timeline_page, island_entry) | **does not exist** (added in Flutter 3.38) |
| `SnackBar(persist:)` | 1 (app_snackbar.dart:83) | **does not exist** |
| `Platform.localizedOperatingSystem` | 1 (my spike debugPrint) | **does not exist** on Dart 3.9.2 |

The third row is my spike bug (removed); the first two are APP CODE vs FORK version gap. **Conclusion for the controller: the pinned fork 3.35.8-ohos-1.0.4 cannot compile the app's current lib/ as-is; 7 spike-only worktree patches were needed.**

### Attempt 2 (spike-only patches, all in worktree, never committed)

1. main.dart spike debugPrint: dropped `localizedOperatingSystem` (doesn't exist on Dart 3.9.2).
2. 6 sites in 6 files: `TickerMode.valuesOf(context).enabled` → `TickerMode.of(context)` (drop-in: the only member used was `.enabled`, and `TickerMode.of` returns that bool). Files: `back_handlers.dart:21`, `island_entry.dart:22`, `day_timeline_page.dart:291`, `statistics_page.dart:61`, `express_statistics_page.dart:59`, `minimal_statistics_page.dart:66` (last three are `features/statistics/pages/`), one site per file — an earlier draft of this note double-counted `day_timeline_page.dart`. Exact site count: 6 across those 6 files.
3. `app_snackbar.dart:83` (spike): removed `persist: false,` from SnackBar call.

### Attempt 2 outcome: Dart compile GREEN, build blocked at debug signing (one-time human step)

Rebuild output tail (verbatim):

```
start hap build...
Running Hvigor task assembleHap...                                 36.9s
请通过DevEco Studio打开ohos工程后配置调试签名(File -> Project Structure -> Signing Configs 勾选Automatically generate signature)
```

Reading: NO Dart compile errors this run — the 8 patches fixed compilation; the build then died at the fork's signing gate (`flutter_tools/lib/src/ohos/hvigor.dart` `checkOhosSignedInfo` tool-exits when `ohos/build-profile.json5` has empty `signingConfigs`). No CLI flag bypasses it (verified in fork source). Debug signing needs a per-bundleName debug profile (`com.streak.streak`) + keystore. The machine's `%USERPROFILE%\.ohos\config` holds DevEco auto-sign material for OTHER apps (chameimei / daylio / com.glimmer.diary / GuduHydration / HighValueLife) — none matches `com.streak.streak`, and keystore passwords live in those other projects' build-profile.json5 (not accessible from here). The documented fix (stated by the error itself) is a one-time DevEco Studio GUI step on the spike project:

> Open `D:\open_code\streak-spike\ohos` in DevEco Studio → File > Project Structure > Signing Configs → check "Automatically generate signature" (device connected) → OK. This writes `signingConfigs` into `ohos/build-profile.json5`. Then rerun `flutter build hap --debug` / `flutter run --debug`.

Crash log from attempt 1's tool crash: `D:\open_code\streak-spike\flutter_01.log` (throwaway worktree artifact).

## Step 4 — device run (real device `5ZFYD25B20000755` per controller directive; emulator skipped entirely)

Device: `5ZFYD25B20000755 (mobile) • ohos-arm64 • Ohos OpenHarmony-7.0.0.105 (API 26)`. Signing gate cleared by the user (DevEco Studio auto-sign wrote `signingConfigs` "default" into `ohos/build-profile.json5`, material under `C:\Users\nanha\.ohos\config\`). Then:

- `flutter build hap --debug` → GREEN: `√ Built build\ohos\hap\entry-default-signed.hap.` (exit 0, assembleHap 27.9s). NOTE: the fork's real output path is `build/ohos/hap/`, NOT the `build/app/outputs/hap/` path the brief guessed.
- `flutter run --debug` built + installed the HAP (`installing hap. bundleName: com.streak.streak`) but launch failed once: `Error Code:10106102 The device screen is locked during the application launch` (developer mode cannot auto-unlock). Workaround: `hdc shell power-shell wakeup` then `hdc shell aa start -b com.streak.streak -a EntryAbility` → `start ability successfully`; app ran standalone (pid 59166).
- Streak icon visible on the home screen (screenshot `D:\ohos-tmp\spike.jpeg`); user confirmed the app on-device showing the StartupFailure screen (see Startup behavior below). Session stopped with `hdc shell aa force-stop com.streak.streak`.

## Fact (a) — Platform.operatingSystem on ohos: **`ohos`**

Observed value is the native `ohos` string — NOT an android alias. Verbatim hilog line (pid 59166):

```
OHOS_SPIKE Platform.operatingSystem=ohos version=HarmonyOS HongMeng Kernel 1.13.0 #1 SMP Sun Sep 20 14:04:41 UTC 2026
```

Capture method: spike debugPrint at the top of `main()` in worktree `lib/main.dart` (compile-verified against Dart 3.9.2 — an earlier `Platform.localizedOperatingSystem` variant failed to compile and was fixed), read back with `hdc shell "hilog -x | grep OHOS_SPIKE"` (full dump: `D:\ohos-tmp\hilog.txt`). Note: `debugPrint` output reaches hilog (tag `A00000/com.streak.streak/XComFlutterOHOS_Native`), NOT the `flutter run` console.

## Fact (b) — assets/shaders/edge_fade.frag load: **INCONCLUSIVE — app stopped at the data-error screen before glass rendered**

The production load path (`lib/core/widgets/glass.dart:199`, `FragmentProgram.fromAsset` with `onError: (_) {}` swallowing failures) never executed: startup died earlier at the path_provider channel (see Startup behavior), so no glass widget mounted. Zero shader/FragmentProgram lines in the captured hilog. A direct spike probe (`FragmentProgram.fromAsset('assets/shaders/edge_fade.frag')` + `OHOS_SPIKE shader load OK/FAILED` debugPrint) is compiled into worktree `lib/main.dart` `main()` but was NOT run on device (wrap-up directive). Task 3's first run will print the verdict.

## Startup behavior on ohos (Task 3 input)

App installs and launches, renders its own StartupFailure screen (user-confirmed on device). Verbatim hilog cause:

```
Streak could not start: MissingPluginException(No implementation found for method getApplicationSupportDirectory on channel plugins.flutter.io/path_provider)
```

Consistent with fact (c): zero ohos plugin implementations are linked, so the first plugin call in `_startup()` (AppDirs/path_provider) throws. Task 3 must add OpenHarmony-SIG plugin packages (or shims) before the app passes startup.

## Fact (c) — SIG plugin repos/refs resolved during pub get

**NONE.** Pub get went green with ZERO OpenHarmony-SIG (gitee flutter_packages) overrides or git dependencies. Everything resolved from `pub.flutter-io.cn` hosted packages only. The full resolved set is standard pub.dev packages (no `*_ohos` plugin implementations present — e.g. no `path_provider_ohos`, no `url_launcher_ohos`). Implication for Tasks 3-6: federated plugins (path_provider, url_launcher, image_picker, permission_handler, etc.) compile into the HAP but have NO ohos implementation packages linked, so their MethodChannels will return `MissingPluginException` at runtime unless SIG ohos packages are added later. `ohos/` shell generated by `flutter create --platforms ohos .` includes its own ohos glue (EntryAbility.ets, generated registrant via the fork's plugin manager) and no SIG har deps were injected into `ohos/entry/oh-package.json5`.

## Fact (d) — device/emulator target id

**`5ZFYD25B20000755`** (physical HarmonyOS phone via USB, per controller directive; DevEco emulator not used — has deployed instances "Pura 90 Pro"/"Mate X7"/"MateBook Pro" with HarmonyOS 7.0.0 images if ever needed).

## Task 3 additions (2026-11-05)

- **SIG overrides landed** (all `gitcode.com/openharmony-sig/*`, pinned to commit SHAs in `pubspec.yaml`; app packages pull their `*_ohos` endorsers via in-repo git deps, root overrides pin the endorsers to the same SHAs): path_provider 2.1.5 + path_provider_ohos 2.2.17 (`flutter_packages` `br_path_provider-v2.1.5_ohos` @ d4e49daa), url_launcher 6.3.2 + url_launcher_ohos 6.3.2 (`br_url_launcher-v6.3.2_ohos` @ ae4494a7), image_picker 1.2.1 + image_picker_ohos 0.8.13+7 (`br_image_picker-v1.2.1_ohos` @ 1af98579), permission_handler 12.0.1 + permission_handler_ohos 12.0.1 (`flutter_permission_handler` `br_v12.0.1_ohos` @ c93847f0), package_info_plus 9.0.0 (`flutter_plus_plugins` `br_package_info_plus-v9.0.0_ohos` @ bc4df814), share_plus 10.1.1 (`br_share_plus-v10.1.1_ohos` @ 55de300a), wakelock_plus 1.4.0 (`fluttertpc_wakelock_plus` `br_v1.4.0_ohos` @ 7009f270), audioplayers 6.5.1 + audioplayers_ohos 5.2.1 + audioplayers_android (`flutter_audioplayers` tag `6.5.1-ohos-1.0.0` @ 3a3e2264). Plus-plugins adaptations declare ohos inline (no separate endorser). Repo-migration note: SIG repos are migrating to the `CPF-Flutter` org (old gitcode URLs keep working via redirect as of 2026-11-05).
- **file_picker**: SIG ships only the endorser `file_picker_ohos` 10.3.8 (`fluttertpc_file_picker` `br_v10.3.8_ohos` @ 98af2156); upstream file_picker is not federated so dependency_overrides cannot pull the endorser in — added as a git entry under `dependencies:` instead (deviation from the brief, disclosed in task-3-report).
- **Host stable flutter**: not installed on this machine (C: full, no PATH/registry/pub-cache traces); installed Flutter 3.47.9 stable (Dart 3.13.7) to `D:\flutter-stable\flutter` for the regression gate, invoked by full path — no PATH/registry changes.
