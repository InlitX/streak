# HarmonyOS Port of Streak — Design

Date: 2026-11-05
Status: draft, pending approval

## Intent

Run the existing Streak Flutter habit tracker on HarmonyOS (OpenHarmony NEXT-era) devices by reusing the entire Dart codebase through the community Flutter-for-OpenHarmony fork. Native ArkTS rewrite is explicitly out of scope.

## Decisions already made (by the user)

- **Route A**: Flutter → OpenHarmony adaptation via the CPF-Flutter / OpenHarmony-SIG fork. No ArkTS rewrite.
- **Phase 1 scope**: core habit loop only — habit create/edit/delete, check-in, streak display, local storage, charts. **Notifications/reminders are fully deferred to Phase 2.** Home-screen widgets, biometric lock, gallery export come later.
- **Focus mode**: stays reachable; `wakelock_plus` wired via its SIG adapter. Biometric app-lock setting hidden on ohos (local_auth wiring is Phase 2).
- **ohos is classified as a mobile (phone) platform** throughout the app — mobile data dir, mobile navigation shell, mobile responsive layout (builder call; Streak is a phone app).
- **Deliverables land on a `feature/harmonyos` branch** in this repo: platform guards + the generated `ohos/` directory. Existing GitHub Actions workflows stay stock-Flutter and untouched.

## Verified facts (2026-11-05)

Repo:
- Flutter app, `pubspec.yaml` requires Dart `^3.9.2` (= Flutter 3.35.x), 308 Dart files, ~86.6k LOC.
- Targets today: Android, iOS, Windows, Linux. No ohos code exists.
- Custom MethodChannels owned by the app (no ohos handler exists; must be stubbed or no-op'd on ohos): `streak/health` (health_steps.dart), `streak/sounds` (reminder_sounds.dart), `streak/focus` (focus_service.dart), `streak/app_icon` (app_icon_service.dart, main.dart:187, notification_service.dart:409, app_lock.dart, widget_style_list.dart), `streak/widget_action` (main.dart:283), `streak/window` (desktop_window.dart).
- Platform classification predicates live in `lib/core/utils/app_dirs.dart` (`isMobile => Platform.isAndroid || Platform.isIOS`, `hasAppIcons => isMobile`, `hasBiometricLock => !Platform.isLinux`) and drive data-dir resolution, navigation shell, settings visibility — ~60 branching call sites depend on how the fork reports ohos.
- Third-party plugin usage of packages without SIG ohos adapters is narrow:
  - `home_widget` — 4 files (services/widget_action_service.dart, services/home_widget_service.dart, services/todos_widget_service.dart, features/settings/state/settings_controller.dart)
  - `gal` — 1 file (features/habits/widgets/share_card.dart)
  - `flutter_timezone` — 1 file (services/notification_service.dart) — relevant only once notifications land in Phase 2
  - `video_player_win` — 1 file (features/focus/widgets/focus_video_scene.dart), Windows-only plugin
- The reminder system is built on 9 `zonedSchedule` call sites (notification_service.dart:531-1037) + `tz.getLocation(IANA name)` where the name comes from flutter_timezone; `DateTime.timeZoneName` yields non-IANA names like "GMT+8" on many platforms, which throws in `tz.getLocation`.
- Custom fragment shader `assets/shaders/edge_fade.frag` loaded in `lib/core/widgets/glass.dart` (a core UI component).
- `dependency_overrides` already contains a Windows-local plugin (`desktop/permission_handler_windows`) — pattern for overrides exists.

Fork ecosystem (verified on gitcode.com, Gitee copies are archived):
- Live repo: `openharmony-sig/flutter_flutter` on gitcode (maintained by CPF-Flutter). Branches/tags include a **3.35.7/3.35.8-ohos line matching this repo's Dart 3.9 requirement**, plus 3.41.10 (roadmap: 3.41 est. 2026-06, lag shrinking to ~4 months).
- Since 3.35.7 the engine ships as cloud prebuilt artifacts — `flutter build hap` does not need a local engine build.
- Impeller/Vulkan unsupported (Skia backend). Windows rule: Flutter project and plugin dependencies must be on the same disk as the fork.
- SIG plugin adapters exist for: path_provider, url_launcher, image_picker, share_plus, permission_handler, file_picker, audioplayers, flutter_local_notifications, package_info_plus, local_auth, wakelock_plus, video_player.
- No adapters exist for: home_widget, gal, flutter_timezone.

Local machine:
- DevEco Studio 26.0 at `%LOCALAPPDATA%\Huawei\DevEcoStudio26.0`; OpenHarmony SDK 26.0.0 at `%LOCALAPPDATA%\OpenHarmony\Sdk`; emulator installed. `hdc` not on PATH.

## Phase 1 — this project

Goal: Streak's core habit loop runs on a HarmonyOS emulator (or device) from this Windows machine.

1. **Environment spike** (throwaway, in a git worktree or copy — never the main checkout):
   - Clone the fork to `D:\` (same-disk rule).
   - Configure env: `TOOL_HOME`, `DEVECO_SDK_HOME`, ohpm/hvigor/node on PATH, `PUB_HOSTED_URL` / `FLUTTER_STORAGE_BASE_URL` (CN mirrors), JDK 17.
   - `flutter doctor -v` must report Flutter + OpenHarmony ok.
   - `flutter create --platforms ohos .` in the copy; `flutter build hap --debug`; install and run on emulator.
2. **Dependency adaptation**:
   - Keep pubspec `sdk` constraint compatible with the pinned fork branch (verify, don't blindly relax).
   - Add SIG adapter packages via whatever consumption method the spike proves out (git deps or path overrides), scoped so Android/iOS/desktop builds keep resolving pub.dev packages unchanged.
3. **Platform identity decision tree** (spike resolves, both branches pre-agreed):
   - If the fork aliases ohos onto Android (`Platform.isAndroid` true): every Android branch activates, including the app's 6 custom MethodChannels — each needs a no-op ohos handler to avoid `MissingPluginException`.
   - If ohos reports as a distinct OS: patch the classification predicates in `app_dirs.dart` so ohos counts as mobile (data dir, navigation shell, responsive layout), and audit which custom channels are reachable.
   - Either way: `Platform.isOhos`/`defaultTargetPlatform` behavior is recorded in notes.md and the guard list is finalized from the observed behavior.
4. **Platform guards for Phase 1** (ohos behavior; Android/iOS/desktop untouched):
   - Notifications/reminder system: fully disabled on ohos (no scheduling, no notification init, no permission prompts). Full implementation is Phase 2.
   - `home_widget` calls → no-op on ohos (service cards are Phase 2).
   - `gal` → skip gallery save on ohos; share flow still works via share_plus.
   - `video_player_win` → focus video background disabled on ohos.
   - `local_auth` / biometric lock setting → hidden on ohos (adapter wiring is Phase 2); the local_auth calls themselves degrade gracefully so only the settings visibility needs a guard.
   - `wakelock_plus` → wired via its SIG adapter so the focus page cannot crash with `MissingPluginException`.
   - Guard mechanism must not change Android/iOS/desktop behavior (platform check + stub, or conditional import).
5. **Shader fallback**: if `FragmentProgram.fromAsset` fails on ohos, platform-gate `glass.dart` to a BlurMaskFilter/gradient fallback. Test this early in the spike, since glass.dart is a core component.
6. **Verification**: on the emulator — create a habit, check in, streak renders, charts render, kill + restart app and data persists (hive via path_provider), focus page opens without crashing (wakelock active). Notifications are explicitly out of Phase-1 verification.

Non-goals (Phase 1): notifications/reminders of any kind, home-screen widgets/service cards, biometric lock, gallery save, release signing / AppGallery packaging, localization changes, any behavior change on Android/iOS/Windows/Linux.

Anti-goals: ArkTS native rewrite; contributing adapter plugins upstream (separate effort); restructuring the Dart codebase.

## Phase 2 backlog (explicitly not now)

- Full notification/reminder system on ohos: verify SIG `flutter_local_notifications` adapter `zonedSchedule` support, bridge a real IANA timezone ID from the ohos i18n system API (replacing flutter_timezone's role), notification permission flow.
- Service cards (ArkTS FormExtensionAbility) replacing home_widget, bridged by PlatformChannel.
- local_auth via SIG adapter (un-hide the biometric lock setting on ohos).
- gal via photoAccessHelper (gallery save).
- Release signing, AppGallery / debug-HAP distribution, versioning aligned with `2.6.0+17`.
- Upstreaming any new adapter work.

## Risks

- **Toolchain mismatch**: DevEco 26.0's hvigor/ohpm may be newer than what the pinned fork branch documents. Spike verifies; fallback is installing the command-line-tools version the fork docs specify.
- **SIG adapter lag**: adapters may track older plugin versions than pubspec pins (e.g., file_picker ^10.3.7, share_plus ^10.1.4). Mitigation: pin to adapter versions and adapt call sites only where the API drifted.
- **Shader**: glass.dart is core; if the Skia backend rejects the `.frag`, the fallback lands in Phase 1 regardless.
- **Network**: pub/flutter artifact fetches need CN mirrors configured.
- **Same-disk rule**: fork must be cloned to `D:\`.

## Left to the builder (spike answers these)

- Exact fork branch/tag to pin.
- Exact consumption method per SIG adapter (git dependency vs path override).
- Whether the fragment shader works on ohos.
- Emulator vs real device as the Phase-1 verification target.
