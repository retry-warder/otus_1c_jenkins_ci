<#
  Настройка репозитория сборки под ваше окружение.
  Подставляет версию платформы, пути к базам, хранилищу и адрес GitHub
  во все файлы настроек (jobConfiguration.json, tools/*.json).

  Пример запуска (PowerShell, из корня репозитория):
    powershell -ExecutionPolicy Bypass -File .\setup.ps1 `
      -V8Version 8.3.25.1546 `
      -GitHubUrl https://github.com/ivanov/otus_1c_ci.git `
      -StoragePath "tcp://localhost/StorageOtus" `
      -TemplateDb "C:/1C/build/Demo83_otus" `
      -ClearDb "C:/1C/build/Demo83_otus_clear"

  Необязательные ключи: -EnableBdd -EnableSonar -EnableEmail -StorageUser DeployGit
#>
param(
  [Parameter(Mandatory = $true)][string]$V8Version,
  [Parameter(Mandatory = $true)][string]$GitHubUrl,
  [Parameter(Mandatory = $true)][string]$StoragePath,
  [Parameter(Mandatory = $true)][string]$TemplateDb,
  [Parameter(Mandatory = $true)][string]$ClearDb,
  [string]$StorageUser = "DeployGit",
  [string]$Branch = "storage_1c",
  [switch]$EnableBdd,
  [switch]$EnableSonar,
  [switch]$EnableEmail
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)   # JSON без BOM

function Read-Json($rel) {
  $text = [IO.File]::ReadAllText((Join-Path $root $rel), [Text.Encoding]::UTF8)
  return $text | ConvertFrom-Json
}
function Write-Json($rel, $obj) {
  $json = $obj | ConvertTo-Json -Depth 20
  # ConvertTo-Json в PS 5.1 экранирует кириллицу как \uXXXX - возвращаем читаемый вид
  $json = [regex]::Replace($json, '\\u([0-9a-fA-F]{4})', { param($m) [char][Convert]::ToInt32($m.Groups[1].Value, 16) })
  [IO.File]::WriteAllText((Join-Path $root $rel), $json + "`n", $utf8)
  Write-Host "  обновлён $rel"
}

$TemplateDb = $TemplateDb.Replace('\', '/').TrimEnd('/')
$ClearDb    = $ClearDb.Replace('\', '/').TrimEnd('/')

Write-Host "Настройка сборки..."

# 1. jobConfiguration.json (Jenkins-Lib, мультипайплайн ci)
$job = Read-Json "jobConfiguration.json"
$job.v8version = $V8Version
$job.defaultBranch = $Branch
$job.initInfobase.templateDBPath = "$TemplateDb/1Cv8.1CD"
$job.stages.bdd = [bool]$EnableBdd
$job.stages.sonarqube = [bool]$EnableSonar
$job.stages.email = [bool]$EnableEmail
Write-Json "jobConfiguration.json" $job

# 2. tools/gitsync.json (Vanessa-Usher, пайплайн gitsync)
$gs = Read-Json "tools/gitsync.json"
$gs.v8Version = $V8Version
$gs.defaultInfobase.connectionString = "/F$ClearDb"
Write-Json "tools/gitsync.json" $gs

# 3. tools/gitsync_conf.json (хранилище -> git)
$gc = Read-Json "tools/gitsync_conf.json"
$gc.globals.'storage-user' = $StorageUser
foreach ($r in $gc.repositories) {
  $r.v8version = $V8Version
  $r.'plugins-config'.URL = $GitHubUrl
  if ($r.dir -eq "./src/cf") { $r.path = $StoragePath }
}
Write-Json "tools/gitsync_conf.json" $gc

# 4. tools/VAParams.json - путь к платформе для VA
$va = Join-Path $root "tools/VAParams.json"
$vaText = [IO.File]::ReadAllText($va, [Text.Encoding]::UTF8)
$vaText = [regex]::Replace($vaText, '1cv8\\\\[0-9.]+\\\\bin', "1cv8\\$V8Version\\bin")
[IO.File]::WriteAllText($va, $vaText, $utf8)
Write-Host "  обновлён tools/VAParams.json"

Write-Host ""
Write-Host "Готово. Проверьте изменения: git diff"
Write-Host "Не забудьте добавить всех пользователей хранилища в src/cf/AUTHORS"
