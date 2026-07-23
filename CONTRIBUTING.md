<div align="center">

# Contributing to Streak

Bug fixes, features or a well-written issue — all of it helps.

</div>

> [!NOTE]
> **Only here to translate?** You don't need any of this.
> Head to [**TRANSLATING.md**](TRANSLATING.md) — no code required.

---

## Ground rules

| | |
|---|---|
| **Small fix** | Just open a pull request. |
| **Feature or behavior change** | Open an issue first, so we agree on the direction before you spend an evening on it. |
| **Bug** | The [issue templates](.github/ISSUE_TEMPLATE) ask for your app version and device — those two answers save all the guessing. |

Streak is deliberately small, offline and free of trackers. Analytics, ads,
accounts and network backends are out of scope.

---

## Getting set up

```bash
git clone https://github.com/InlitX/streak.git
cd streak
flutter pub get     # also generates the localization code
flutter run
```

You'll need the Flutter SDK (stable), the Android SDK and JDK 17. Streak targets
Android 9 (API 28) and up.

Before opening a pull request, keep both of these green:

```bash
flutter analyze     # no issues
flutter test        # all passing
```

If you touch **completions, streaks, scheduling or the importers**, add a test —
that's where a quiet regression corrupts someone's real history.

---

## Good to know

Three traps that have already bitten this codebase, none of which fail loudly.

- **Date walks need a floor.** Avoidance habits are *clean by default*, so a
  loop walking backwards day by day must stop at the habit's `createdAt`.
  Unbounded, it freezes the app.
- **Never dispose a `TextEditingController` right after `await showDialog`.**
  The future completes when the dialog *starts* closing, while the field is
  still mounted and rebuilding. Own it in a `State` instead.
- **Glance draws only the first 10 children** of a `Row` or `Column` — no error,
  just half a widget. Chunk anything longer, and run `flutter clean` after
  Kotlin changes or you'll keep testing the old one.

---

## The code

**Flutter + Dart**, state in `provider`, storage in `hive_ce`, charts from
`fl_chart`, home widgets in Kotlin with Jetpack Glance.

Features are self-contained — each owns its models, controllers, pages and
widgets. Anything that changes a habit's completions belongs in `CompletionOps`,
which both the UI and the widgets call.

<details>
<summary><b>Directory layout</b></summary>

```
lib/
├── main.dart       App entry point and home-widget callback
├── app/            App shell, navigation host, theming
├── core/           Storage, date helpers, icons, routing, shared widgets
├── l10n/           Translation files (source of truth)
├── features/       habits · statistics · settings · onboarding
└── services/       Notifications, widgets, backup, import, launcher icon

android/            Android host project and the Glance widgets
fastlane/           Store listing and changelogs — F-Droid reads these
test/               Unit tests
```

</details>

**Style:** match the code around you. Comments are rare on purpose — prefer a
name that explains itself. Every user-visible string goes in
`lib/l10n/app_en.arb` and is used via `context.l10n.your_key`; leave the other
languages to [Weblate](https://hosted.weblate.org/engage/streak/), and never
rename an existing key or its translations are lost everywhere.

> [!NOTE]
> Versions, tags, signing and publishing are handled by the maintainer — never
> bump a version or push a tag in a pull request. CI builds every PR as a check.

---

<div align="center">

By contributing you agree that your work ships under the project's
[MIT License](LICENSE).

</div>
