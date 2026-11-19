<#
.SYNOPSIS
  在 VirtualBox 中无人值守创建一台 Windows 基线虚拟机。
.DESCRIPTION
  前置：已提供 Windows 10/11 x64 ISO 镜像。脚本建 VM、配 2 vCPU / 4 GB / 60 GB、
  挂 SATA 磁盘与 ISO，调用 VBoxManage unattended install 自动装系统。
  ISO 未就位前不要执行；先把镜像放到 D:\VMs，再用 -IsoPath 传入。
.PARAMETER IsoPath
  Windows 安装 ISO 的完整路径。
.PARAMETER VmName
  虚拟机名称，默认 Win11-Base。
.PARAMETER MemoryMB
  内存 MB，默认 4096。低配套改 2048。
.PARAMETER Cpus
  vCPU 数量，默认 2。
.PARAMETER DiskMB
  磁盘 MB，默认 61440（60 GB）。
.PARAMETER User
  系统内用户名，默认 bill。
.PARAMETER Password
  系统内用户密码（建议运行时由控制台输入，不要写进脚本）。
.EXAMPLE
  .\New-Vm.ps1 -IsoPath "D:\VMs\Win11.iso"
#>
param(
    [Parameter(Mandatory = $true)][string]$IsoPath,
    [string]$VmName = "Win11-Base",
    [int]$MemoryMB = 4096,
    [int]$Cpus = 2,
    [int]$DiskMB = 61440,
    [string]$User = "bill",
    [string]$Password = "Test1234!"
)

$ErrorActionPreference = "Stop"
$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$baseDir = "D:\VMs"
$vmDir = Join-Path $baseDir $VmName
$diskPath = Join-Path $vmDir "disk.vdi"

if (-not (Test-Path $IsoPath)) { throw "ISO 不存在：$IsoPath" }
if (-not (Test-Path $vbox)) { throw "未找到 VBoxManage，先安装 VirtualBox。" }

function Invoke-VBox {
    param([string[]]$ArgsList)
    & $vbox @ArgsList
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage 失败：$($ArgsList -join ' ')" }
}

# 0. 避免重复注册
$existing = & $vbox list vms
if ($existing -match [regex]::Escape($VmName)) { throw "VM [$VmName] 已存在，先处理旧实例。" }

New-Item -ItemType Directory -Force -Path $vmDir | Out-Null

# 1. 注册 VM
Invoke-VBox @("createvm", "--name", $VmName, "--ostype", "Windows11_64", "--basefolder", $baseDir, "--register")

# 2. 硬件配置：EFI + TPM 2.0（Win11 安装要求）
Invoke-VBox @("modifyvm", $VmName,
    "--cpus", $Cpus, "--memory", $MemoryMB, "--vram", 16,
    "--graphicscontroller", "vmsvga",
    "--firmware", "efi64", "--tpm-type", "2.0",
    "--rtc-use-utc", "--boot1", "dvd")

# 3. 安全启动变量库
Invoke-VBox @("modifynvram", $VmName, "inituefivarstore")
Invoke-VBox @("modifynvram", $VmName, "enrollmssignatures")
Invoke-VBox @("modifynvram", $VmName, "secureboot", "--enable")

# 4. 磁盘
Invoke-VBox @("createmedium", "disk", "--filename", $diskPath, "--size", $DiskMB, "--format", "VDI")

# 5. SATA 控制器 + 挂盘
Invoke-VBox @("storagectl", $VmName, "--name", "SATA", "--add", "sata")
Invoke-VBox @("storageattach", $VmName, "--storagectl", "SATA", "--port", "0", "--device", "0", "--type", "hdd", "--medium", $diskPath)

# 6. 无人值守安装（自动挂 ISO、建用户、装增强工具）
Invoke-VBox @("unattended", "install", $VmName,
    "--iso", $IsoPath,
    "--user", $User, "--user-password", $Password,
    "--full-user-name", $User,
    "--locale", "zh_CN", "--country", "CN", "--time-zone", "Asia/Shanghai",
    "--install-additions",
    "--start-vm", "headless")

Write-Output "VM [$VmName] 已启动无人值守安装，日志见 VirtualBox 管理器。装完后建议："
Write-Output "  1. 进系统装完剩余更新；2. 关机；3. 打基线快照：VBoxManage snapshot $VmName take base-clean"
