<#
  《美味银河》简体中文汉化补丁 - 卸载还原（恢复英文原版）
  用法同安装：双击后在窗口里选游戏目录，或把游戏文件夹拖到「卸载还原.bat」上
#>
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$NL = [string][char]10

function Pause-Exit([int]$code) { Write-Host ""; Read-Host "按回车键关闭" | Out-Null; exit $code }
function Find-Game([string]$p) {
  if (-not $p) { return $null }
  $p = $p.Trim('"').TrimEnd('\')
  foreach ($cand in @($p, (Join-Path $p "NomNomGalaxy"))) {
    if ((Test-Path (Join-Path $cand "data.pkdwin")) -or (Test-Path (Join-Path $cand "data.pkdwin.bak_zh"))) { return $cand }
  }
  return $null
}

Write-Host "==============================================="
Write-Host "  《美味银河》汉化补丁 - 卸载还原"
Write-Host "==============================================="
Write-Host ""

$game = $null
if ($Args -and $Args.Count -gt 0) { $game = Find-Game $Args[0] }
if (-not $game) {
  Add-Type -AssemblyName System.Windows.Forms | Out-Null
  while (-not $game) {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "请选择游戏安装目录（包含 data.pkdwin 的文件夹）"
    $dlg.ShowNewFolderButton = $false
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { Write-Host "已取消。"; Pause-Exit 1 }
    $game = Find-Game $dlg.SelectedPath
    if (-not $game) {
      $msg = "这个文件夹里没有 data.pkdwin，请重新选择。"
      [System.Windows.Forms.MessageBox]::Show($msg, "目录不对", "OK", "Warning") | Out-Null
    }
  }
}
Write-Host "游戏目录：$game"

$done = $false
foreach ($f in @("data.pkdwin","data.pkiwin")) {
  $src = Join-Path $game "$f.bak_zh"
  if (Test-Path $src) {
    Copy-Item -LiteralPath $src -Destination (Join-Path $game $f) -Force
    Write-Host "  已还原 $f"
    $done = $true
  } else {
    Write-Host "  [提示] 未找到备份 $f.bak_zh，跳过"
  }
}

$base = Join-Path ([Environment]::GetFolderPath("ApplicationData")) "NomNomGalaxy"
if (Test-Path $base) {
  $files = Get-ChildItem -Path $base -Recurse -Filter "globals.dat" -ErrorAction SilentlyContinue
  foreach ($g in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($g.FullName)
    $ob = [System.Text.Encoding]::ASCII.GetBytes("SPANISH")
    $hit = $false
    for ($i = 0; $i -le $bytes.Length - 7; $i++) {
      if ($bytes[$i] -eq $ob[0]) {
        $ok = $true
        for ($j = 1; $j -lt 7; $j++) { if ($bytes[$i + $j] -ne $ob[$j]) { $ok = $false; break } }
        if ($ok) {
          [Array]::Copy([System.Text.Encoding]::ASCII.GetBytes("ENGLISH"), 0, $bytes, $i, 7)
          [System.IO.File]::WriteAllBytes($g.FullName, $bytes)
          Write-Host "  存档语言已还原为 English"
          $hit = $true
          break
        }
      }
    }
    if ($hit) { break }
  }
}

Write-Host ""
if ($done) { Write-Host "卸载完成，游戏已回到英文原版。" } else { Write-Host "没有找到备份文件，未做任何修改。" }
Pause-Exit 0
