# scripts/ohos_env.ps1
# Environment for the HarmonyOS (ohos) Flutter toolchain on this machine.
# Dot-source from the repo root before any ohos build command:
#   . .\scripts\ohos_env.ps1
# Values located 2026-11-05 (HarmonyOS port phase 1, Task 1).

$ErrorActionPreference = 'Stop'

# --- Toolchain roots ---
# DevEco Studio install root (carries tools\ohpm, tools\hvigor, tools\node and the bundled sdk\).
$env:TOOL_HOME = 'D:\Program Files\Huawei\DevEco Studio'
# The ohos flutter fork's doctor expects DEVECO_SDK_HOME at the DevEco sdk root
# (resolves to sdk\default\openharmony). Standalone SDK fallback:
#   "$env:LOCALAPPDATA\OpenHarmony\Sdk"
$env:DEVECO_SDK_HOME = Join-Path $env:TOOL_HOME 'sdk'
# Standalone JDK 17 (Microsoft OpenJDK 17.0.20.1); preferred over DevEco's bundled JBR (JDK 25).
$env:JAVA_HOME = 'C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot'
# Pub cache kept on D:\ next to the fork (same-disk rule).
$env:PUB_CACHE = 'D:\flutter-ohos\pub-cache'

# --- CN mirrors (plan Global Constraints) ---
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'

# --- Tool binaries prepended to PATH (fork first, so it wins over any system flutter) ---
$ohosPathEntries = @(
  'D:\flutter-ohos\flutter\bin',                                      # ohos flutter fork
  (Join-Path $env:TOOL_HOME 'tools\ohpm\bin'),                        # ohpm.bat
  (Join-Path $env:TOOL_HOME 'tools\hvigor\bin'),                      # hvigorw.bat
  (Join-Path $env:TOOL_HOME 'tools\node'),                            # node.exe
  (Join-Path $env:LOCALAPPDATA 'OpenHarmony\Sdk\26.0.0\toolchains'),  # hdc.exe
  'D:\flutter-ohos\flutter\bin\cache\dart-sdk\bin'                    # dart (exists after first flutter bootstrap)
)
if (-not (Test-Path 'D:\flutter-ohos\flutter\bin')) {
  Write-Warning 'ohos flutter fork not found at D:\flutter-ohos\flutter - clone it first (plan Task 1 Step 1).'
}
$env:Path = ($ohosPathEntries -join ';') + ';' + $env:Path
