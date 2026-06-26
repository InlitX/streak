# F-Droid submission files

This folder is **not part of the app**. It holds the recipe F-Droid needs to
build and publish Streak. The actual app metadata (descriptions, screenshots,
changelog) lives in `../fastlane/metadata/android/` and IS committed to this
repo so F-Droid can read it.

## What goes where

| File | Destination |
|------|-------------|
| `../fastlane/metadata/android/**` | Stays in **this** repo (GitHub). F-Droid reads it from your tags. |
| `com.streak.app.yml` | Goes into the **fdroiddata** repo at `metadata/com.streak.app.yml`. |

## How to submit

1. Make sure your GitHub repo is **public** and the release is **tagged**
   (`v1.0.0` already exists, matching versionName 1.0.0 / versionCode 1).
2. Fork https://gitlab.com/fdroid/fdroiddata
3. Create a branch named `com.streak.app`.
4. Copy `com.streak.app.yml` into `metadata/com.streak.app.yml` in your fork.
5. (On Linux/Docker) test it:
   ```
   fdroid lint com.streak.app
   fdroid build com.streak.app
   ```
6. Commit (`New App: com.streak.app`), push, and open a Merge Request against
   fdroiddata `master`.

> Easier alternative if you can't run fdroidserver on Windows: open a
> **Request For Packaging (RFP)** issue at
> https://gitlab.com/fdroid/rfp/-/issues and a maintainer helps with the recipe.

## Note on the build recipe

`srclibs: flutter@stable` may need to be pinned to the exact Flutter version
that builds the app (the project targets Dart SDK ^3.9.2). F-Droid maintainers
often adjust this during review. If the build fails on the Flutter toolchain,
pin a specific version, e.g. `flutter@3.35.2`.
