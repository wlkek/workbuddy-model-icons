param(
  [string]$AppRoot,
  [switch]$Uninstall,
  [switch]$Status
)

# WorkBuddy 模型图标 —— 安装 / 卸载
# 只做两件事：往 index.html 插一段加载器；把脚本复制进 resources/。
# 和其它插件（思考强度滑条）互不干扰：只追加 / 只删自己那一段。

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$enc = New-Object System.Text.UTF8Encoding($false)
$MARK = 'wb-model-icons'
$LOADER = '<script>!function(){try{var m=/^(.*)\/app\.asar\/renderer\/index\.html/.exec(location.href),s=document.createElement("script");s.src=m?m[1]+"/' + $MARK + '/' + $MARK + '.js":"../../' + $MARK + '/' + $MARK + '.js";(document.head||document.documentElement).appendChild(s)}catch(e){}}()</script>'

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function ReadUtf8($p) { $enc.GetString([IO.File]::ReadAllBytes($p)) }

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
if (-not $AppRoot) { throw '找不到 WorkBuddy 安装目录，请用 -AppRoot 指定' }

$html = Join-Path $AppRoot 'resources\app.asar.unpacked\renderer\index.html'
$dstDir = Join-Path $AppRoot ("resources\" + $MARK)
$dst = Join-Path $dstDir ($MARK + '.js')
$src = Join-Path $here ('src\' + $MARK + '.js')
if (-not (Test-Path $html)) { throw "找不到入口文件：$html" }

# ---------------------------------------------------------------- 状态
if ($Status) {
  $t = ReadUtf8 $html
  Say ''
  Say ('  安装目录 : ' + $AppRoot)
  Say ('  加载器   : ' + $(if ($t.Contains($MARK)) { '已注入' } else { '未注入' }))
  if (Test-Path $dst) {
    $v = ([regex]::Match((ReadUtf8 $dst), "VERSION = '([0-9.]+)'")).Groups[1].Value
    Say ('  脚本     : v' + $v)
  } else { Say '  脚本     : 未安装' }
  Say ''
  exit 0
}

# ---------------------------------------------------------------- 卸载
if ($Uninstall) {
  $t = ReadUtf8 $html
  $re = '<script>[^<]*' + $MARK + '[^<]*</script>'
  if ($t -match $re) {
    $t2 = [regex]::Replace($t, $re, '')
    [IO.File]::WriteAllBytes($html, $enc.GetBytes($t2))
    Say '[OK] 已移除加载器' 'Green'
  } else {
    Say '[--] 没有找到加载器（可能未安装）' 'Yellow'
  }
  if (Test-Path $dstDir) { Remove-Item $dstDir -Recurse -Force }
  Say '[OK] 已删除脚本目录'
  Say '     完全退出 WorkBuddy 再打开即可恢复'
  exit 0
}

# ---------------------------------------------------------------- 安装
if (-not (Test-Path $src)) { throw "找不到脚本：$src" }
New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
Copy-Item $src $dst -Force

$text = ReadUtf8 $html
$curLen = (Get-Item $html).Length

if ($text.Contains($MARK)) {
  Say '[OK] 加载器已存在，只更新脚本' 'Green'
  Say '     完全退出 WorkBuddy 再打开'
  exit 0
}

# 上限：优先用备份的原始大小（应用按 asar 头里记录的 size 返回文件，超出会被截断）
$cap = $curLen
foreach ($b in @($html + '.wb-es.bak', $html + '.wbm-icons.bak')) {
  if (Test-Path $b) { $cap = [Math]::Max($cap, (Get-Item $b).Length) }
}

# 先腾空间：删 <script> 之外的 HTML 注释和纯空行（惰性内容，删了不影响功能）
$parts = [regex]::Split($text, '(?is)(<script\b[^>]*>.*?</script>)')
for ($i = 0; $i -lt $parts.Count; $i++) {
  if ($i % 2 -eq 1) { continue }
  $q = [regex]::Replace($parts[$i], '(?s)<!--.*?-->', '')
  $q = [regex]::Replace($q, '(?m)^[ \t]*\r?\n', '')
  $parts[$i] = $q
}
$slim = -join $parts

$anchor = '<meta charset="UTF-8" />'
if ($slim.IndexOf($anchor) -lt 0) { $anchor = '<head>' }
if ($slim.IndexOf($anchor) -lt 0) { throw '在 index.html 里找不到 <head>，无法插入加载器' }
$at = $slim.IndexOf($anchor) + $anchor.Length
$out = $slim.Insert($at, "`r`n" + $LOADER)

$bytes = $enc.GetBytes($out)
if ($bytes.Length -gt $cap) {
  throw ("生成结果 " + $bytes.Length + " 字节 > 上限 " + $cap + " 字节，会被截断。请先卸载其它修改入口的插件再试。")
}

Copy-Item $html ($html + '.wbm-icons.bak') -Force
[IO.File]::WriteAllBytes($html, $bytes)

$check = ReadUtf8 $html
if (-not $check.Contains($MARK)) { throw '写入后校验失败' }

Say ''
Say '[OK] 安装完成' 'Green'
Say ('     index.html ' + $bytes.Length + ' / ' + $cap + ' 字节')
Say '     请**完全退出 WorkBuddy 再重新打开**（托盘退出）'
Say '     打开任意模型菜单即可看到图标'
