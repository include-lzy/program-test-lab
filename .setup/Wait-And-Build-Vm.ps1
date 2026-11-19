<#
.SYNOPSIS
  轮询等待 Win11 ISO 下载落盘，完成后自动调用 New-Vm.ps1 建基线 VM。
.DESCRIPTION
  - 每 45 秒检查一次 D:\VMs：无 *.crdownload 且出现 *.iso 视为下载完成。
  - ISO 需大于 1GB，避免把半成品/损坏镜像当成完成。
  - 若 Win11-Base VM 已存在则跳过，不重复注册。
  - 全过程写入 .setup\vm-build.log。
.PARAMETER MemoryMB
  基线 VM 内存 MB，默认 4096。可用内存紧张时可调低（如 3072）。
#>
param(
    [int]$MemoryMB = 4096,
    [int]$PollSeconds = 45
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$vmDir = "D:\VMs"
$script = Join-Path $PSScriptRoot "New-Vm.ps1"
$log = Join-Path $PSScriptRoot "vm-build.log"

function Write-Log([string]$msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    Add-Content -Path $log -Value $line -Encoding UTF8
    Write-Output $line
}

Write-Log "等待 ISO 落盘，轮询目录 $vmDir"

while ($true) {
    $crds = Get-ChildItem $vmDir -Filter "*.crdownload" -Force -ErrorAction SilentlyContinue
    $isos = Get-ChildItem $vmDir -Filter "*.iso" -Force -ErrorAction SilentlyContinue

    if (-not $crds -and $isos) {
        $iso = $isos | Sort-Object Length -Descending | Select-Object -First 1
        if ($iso.Length -gt 1GB) {
            Write-Log "ISO 就绪：$($iso.FullName)，大小 $([math]::Round($iso.Length/1GB,2)) GB"
            break
        } else {
            Write-Log "发现 ISO 但仅 $([math]::Round($iso.Length/1MB,1)) MB，判定不完整，继续等待"
        }
    } else {
        if ($crds) {
            Write-Log "下载中：存在临时文件 *.crdownload（大小以 D:\VMs 实况为准，下载期间元数据可能延迟）"
        } else {
            Write-Log "尚无 ISO，继续等待"
        }
    }
    Start-Sleep -Seconds $PollSeconds
}

# 防重复：VM 已存在则退出
$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$existing = & $vbox list vms
if ($existing -match "Win11-Base") {
    Write-Log "VM [Win11-Base] 已存在，跳过创建。"
    exit 0
}

Write-Log "开始创建基线 VM（内存 $MemoryMB MB）"
& pwsh -NoProfile -ExecutionPolicy Bypass -File $script -IsoPath $iso.FullName -MemoryMB $MemoryMB
if ($LASTEXITCODE -ne 0) {
    Write-Log "New-Vm.ps1 退出码 $LASTEXITCODE，创建未成功。"
    exit $LASTEXITCODE
}
Write-Log "基线 VM 已启动无人值守安装。装完进系统打完更新、关机后执行：VBoxManage snapshot Win11-Base take base-clean"
