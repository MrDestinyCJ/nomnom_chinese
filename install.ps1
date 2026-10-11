<#
  《美味银河》简体中文汉化补丁 v1.0 - 安装器
  用法一：双击「安装汉化.bat」，在弹出的窗口里选择游戏目录
  用法二：把游戏文件夹直接拖到「安装汉化.bat」上
  特点：不需要 Python、不需要联网，只用 Windows 自带的 PowerShell
#>
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$patchDir = Join-Path $here "patch_data"
$NL = [string][char]10

function Pause-Exit([int]$code) { Write-Host ""; Read-Host "按回车键关闭" | Out-Null; exit $code }

function Find-Game([string]$p) {
  if (-not $p) { return $null }
  $p = $p.Trim('"').TrimEnd('\')
  foreach ($cand in @($p, (Join-Path $p "NomNomGalaxy"))) {
    if (Test-Path (Join-Path $cand "data.pkdwin")) { return $cand }
  }
  return $null
}

Write-Host "==============================================="
Write-Host "  《美味银河》简体中文汉化补丁 v1.0 - 安装"
Write-Host "==============================================="
Write-Host ""

# ---------- 1. 由用户指定游戏目录（不使用任何默认路径）----------
$game = $null
if ($Args -and $Args.Count -gt 0) { $game = Find-Game $Args[0] }

if (-not $game) {
  Add-Type -AssemblyName System.Windows.Forms | Out-Null
  while (-not $game) {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "请选择游戏安装目录（包含 NomNomGalaxy.exe 和 data.pkdwin 的那个文件夹）"
    $dlg.ShowNewFolderButton = $false
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
      Write-Host "已取消，未做任何修改。"
      Pause-Exit 1
    }
    $game = Find-Game $dlg.SelectedPath
    if (-not $game) {
      $msg = "这个文件夹里没有找到 data.pkdwin。" + $NL + $NL + "请选择游戏根目录，例如：" + $NL + "SteamLibrary\steamapps\common\NomNomGalaxy"
      [System.Windows.Forms.MessageBox]::Show($msg, "目录不对", "OK", "Warning") | Out-Null
    }
  }
}
Write-Host "游戏目录：$game"

# ---------- 2. 备份 ----------
$pkdPath = Join-Path $game "data.pkdwin"
$pkiPath = Join-Path $game "data.pkiwin"
$bakPkd  = "$pkdPath.bak_zh"
$bakPki  = "$pkiPath.bak_zh"

if (-not (Test-Path $bakPkd)) {
  Write-Host "正在备份原始文件（首次安装，约 128MB，请稍候）..."
  Copy-Item -LiteralPath $pkdPath -Destination $bakPkd -Force
  Copy-Item -LiteralPath $pkiPath -Destination $bakPki -Force
  Write-Host "  备份完成：data.pkdwin.bak_zh / data.pkiwin.bak_zh"
} else {
  Write-Host "已存在原始备份，跳过备份。"
}

# ---------- 3. 读取原始档案（有备份就用备份，保证可反复安装）----------
$srcPkd = if (Test-Path $bakPkd) { $bakPkd } else { $pkdPath }
$srcPki = if (Test-Path $bakPki) { $bakPki } else { $pkiPath }
Write-Host "正在读取原始档案..."
$pkd = [System.IO.File]::ReadAllBytes($srcPkd)
$pki = [System.IO.File]::ReadAllBytes($srcPki)
$count = [BitConverter]::ToUInt32($pki, 8)
Write-Host ("  档案条目数：{0}" -f $count)

$manifest = Get-Content -LiteralPath (Join-Path $patchDir "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$repl = @{}
$replUsize = @{}
foreach ($m in $manifest) {
  $repl[[int]$m.index] = [System.IO.File]::ReadAllBytes((Join-Path $patchDir ("entry_{0}.z" -f $m.index)))
  $replUsize[[int]$m.index] = [uint32]$m.usize
}

# ---------- 4. 重建档案 ----------
Write-Host "正在生成汉化档案..."
$newSize = 12
$entries = @()
for ($i = 0; $i -lt $count; $i++) {
  $o = 12 + $i * 16
  $csize = [BitConverter]::ToUInt32($pki, $o + 4)
  $eoff  = [BitConverter]::ToUInt32($pki, $o + 8)
  $hash  = [BitConverter]::ToUInt32($pki, $o + 12)
  $usize = [BitConverter]::ToUInt32($pki, $o)
  if ($repl.ContainsKey($i)) { $usize = $replUsize[$i]; $csize = [uint32]$repl[$i].Length }
  $entries += [pscustomobject]@{ idx=$i; usize=$usize; csize=$csize; off=$newSize; hash=$hash; old=$eoff }
  $newSize += [int]$csize
}

$newPkd = New-Object byte[] $newSize
[Array]::Copy($pkd, 0, $newPkd, 0, 12)
foreach ($e in $entries) {
  if ($repl.ContainsKey($e.idx)) {
    [Array]::Copy($repl[$e.idx], 0, $newPkd, $e.off, $repl[$e.idx].Length)
  } else {
    [Array]::Copy($pkd, [int]$e.old, $newPkd, $e.off, [int]$e.csize)
  }
}

$newPki = New-Object byte[] $pki.Length
[Array]::Copy($pki, 0, $newPki, 0, 12)
foreach ($e in $entries) {
  $o = 12 + $e.idx * 16
  [Array]::Copy([BitConverter]::GetBytes([uint32]$e.usize), 0, $newPki, $o, 4)
  [Array]::Copy([BitConverter]::GetBytes([uint32]$e.csize), 0, $newPki, $o + 4, 4)
  [Array]::Copy([BitConverter]::GetBytes([uint32]$e.off),   0, $newPki, $o + 8, 4)
  [Array]::Copy([BitConverter]::GetBytes([uint32]$e.hash),  0, $newPki, $o + 12, 4)
}
[Array]::Copy($pki, 12 + $count * 16, $newPki, 12 + $count * 16, 4)

Write-Host "正在写入游戏目录..."
[System.IO.File]::WriteAllBytes($pkdPath, $newPkd)
[System.IO.File]::WriteAllBytes($pkiPath, $newPki)
Write-Host ("  完成：data.pkdwin {0:N1} MB" -f ($newSize / 1MB))

# ---------- 5. 语言指向中文槽位 ----------
$base = Join-Path ([Environment]::GetFolderPath("ApplicationData")) "NomNomGalaxy"
$langDone = $false
if (Test-Path $base) {
  $files = Get-ChildItem -Path $base -Recurse -Filter "globals.dat" -ErrorAction SilentlyContinue
  foreach ($g in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($g.FullName)
    foreach ($old in @("ENGLISH","SPANISH")) {
      $ob = [System.Text.Encoding]::ASCII.GetBytes($old)
      $idx = -1
      for ($i = 0; $i -le $bytes.Length - $ob.Length; $i++) {
        if ($bytes[$i] -eq $ob[0]) {
          $ok = $true
          for ($j = 1; $j -lt $ob.Length; $j++) { if ($bytes[$i + $j] -ne $ob[$j]) { $ok = $false; break } }
          if ($ok) { $idx = $i; break }
        }
      }
      if ($idx -ge 0) {
        [Array]::Copy([System.Text.Encoding]::ASCII.GetBytes("SPANISH"), 0, $bytes, $idx, 7)
        [System.IO.File]::WriteAllBytes($g.FullName, $bytes)
        $langDone = $true
        Write-Host "  存档语言已设置：$($g.FullName)"
        break
      }
    }
    if ($langDone) { break }
  }
}
if (-not $langDone) { Write-Host "  未找到存档（首次进游戏后会自动用中文，或在选项里选「简体中文」）" }

Write-Host ""
Write-Host "==============================================="
Write-Host "  安装完成！直接启动游戏即为简体中文。"
Write-Host "  还原英文请双击「卸载还原.bat」"
Write-Host "==============================================="
Pause-Exit 0
