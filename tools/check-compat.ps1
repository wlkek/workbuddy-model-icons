# WorkBuddy 模型图标 —— 兼容性自查
# 扫描安装目录的前端包，看插件依赖的类名是否还在。
# 用法：.\check-compat.ps1              （自动找安装目录）
#       .\check-compat.ps1 -AppRoot "D:\...\WorkBuddy"

param(
  [string]$AppRoot
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- 定位安装目录
if (-not $AppRoot) {
  $cands = @()
  $p = Get-Process -Name 'WorkBuddy' -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($p -and $p.Path) { $cands += (Split-Path -Parent $p.Path) }
  $cands += (Join-Path $env:LOCALAPPDATA 'Programs\WorkBuddy')
  $cands += (Join-Path $env:ProgramFiles 'WorkBuddy')
  foreach ($c in $cands) {
    if ($c -and (Test-Path (Join-Path $c 'resources\app.asar'))) { $AppRoot = $c; break }
  }
}
if (-not $AppRoot) {
  Write-Host "找不到 WorkBuddy 安装目录，请用 -AppRoot 指定" -ForegroundColor Red
  exit 1
}

$assets = Join-Path $AppRoot 'resources\app.asar.unpacked\renderer\assets'
if (-not (Test-Path $assets)) {
  Write-Host "找不到资源目录：$assets" -ForegroundColor Red
  exit 1
}

$files = Get-ChildItem $assets -Filter *.js -File
$totalBytes = ($files | Measure-Object Length -Sum).Sum

Write-Host ""
Write-Host "  安装目录 : $AppRoot" -ForegroundColor Cyan
Write-Host ("  前端包   : {0} 个文件 / {1:N0} MB" -f $files.Count, ($totalBytes / 1MB))
Write-Host ""

# 插件依赖的类名词根（不含前缀）
$tokens = @(
  'model-selector__item',
  'model-selector__item-icon',
  'model-selector__item-name',
  'model-selector__trigger',
  'trigger-icon',
  'model-group-option'
)

$rows = @()
foreach ($t in $tokens) {
  $hits = 0
  foreach ($f in $files) {
    try {
      if ([IO.File]::ReadAllText($f.FullName).Contains($t)) { $hits++ }
    } catch { }
  }
  $rows += [pscustomobject]@{ 类名 = $t; 命中文件 = $hits }
}

$rows | Format-Table -AutoSize

$miss = @($rows | Where-Object { $_.命中文件 -eq 0 })
Write-Host ""
if ($miss.Count -eq 0) {
  Write-Host "  结论：全部命中，图标插件应当正常工作。" -ForegroundColor Green
  exit 0
}

Write-Host ("  结论：有 {0} 个类名没找到 —— {1}" -f $miss.Count, ($miss.类名 -join ', ')) -ForegroundColor Yellow
Write-Host "       插件会自动降级为「不做任何事」，不会破坏界面。" -ForegroundColor Yellow
exit 2
