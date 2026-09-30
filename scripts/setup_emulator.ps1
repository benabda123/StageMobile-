# ============================================================================
# Lance l'app Flutter sur l'émulateur Android avec le tunnel adb reverse actif.
# ----------------------------------------------------------------------------
# Contexte : Keycloak est configuré avec KC_HOSTNAME=localhost (URLs
# http://localhost:8085 partout, y compris la page de login HTML). Sur
# l'émulateur, "localhost" = l'émulateur lui-même : sans tunnel, la Custom Tab
# afficherait "This site can't be reached". Le tunnel adb forwarde les ports
# de l'émulateur vers la machine hôte où tournent les conteneurs Docker.
#
# Le tunnel ne persiste PAS entre deux redémarrages de l'émulateur ni du
# serveur adb : exécuter ce script avant chaque `flutter run`.
# ============================================================================

$ErrorActionPreference = 'Stop'

# ADB est généralement dans le SDK Android (variable ANDROID_HOME ou chemin
# par défaut). On le résout s'il n'est pas dans le PATH.
$adb = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adb) {
  $sdkRoot = $env:ANDROID_HOME
  if (-not $sdkRoot) { $sdkRoot = "$env:LOCALAPPDATA\Android\Sdk" }
  $adbPath = Join-Path $sdkRoot 'platform-tools\adb.exe'
  if (-not (Test-Path -LiteralPath $adbPath)) {
    throw "adb introuvable. Installez le SDK Android ou ajoutez adb au PATH."
  }
  $adb = $adbPath
} else {
  $adb = $adb.Path
}

# Ports à tunneliser : Keycloak (8085) et l'API via Kong (8000).
$rules = @(
  @{ devicePort = 8085; hostPort = 8085 },
  @{ devicePort = 8000; hostPort = 8000 }
)

foreach ($rule in $rules) {
  & $adb reverse tcp:$($rule.devicePort) tcp:$($rule.hostPort)
  if ($LASTEXITCODE -ne 0) {
    throw "Échec de: adb reverse tcp:$($rule.devicePort) tcp:$($rule.hostPort)"
  }
  Write-Host "adb reverse tcp:$($rule.devicePort) tcp:$($rule.hostPort) -> OK"
}

Write-Host "`nRègles actives :"
& $adb reverse --list

Write-Host "`nLancement de l'app..."
& flutter run
