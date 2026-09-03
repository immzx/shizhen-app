# 开发机配置检测脚本
# 用途：判断一台机器是否适合作为鸿蒙（DevEco Studio）主开发机
# 用法：右键「使用 PowerShell 运行」，或在 PowerShell 中执行
#       powershell -ExecutionPolicy Bypass -File .\detect-specs.ps1

$ErrorActionPreference = 'SilentlyContinue'

Write-Output "=============================================="
Write-Output " 开发机配置检测 · 拾帧项目"
Write-Output " 检测时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "=============================================="
Write-Output ""

# ---- 系统 ----
$os = Get-CimInstance Win32_OperatingSystem
Write-Output "【操作系统】"
Write-Output "  系统:      $($os.Caption)  (Build $($os.BuildNumber))"
Write-Output "  架构:      $($os.OSArchitecture)"
Write-Output ""

# ---- CPU ----
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Write-Output "【处理器】"
Write-Output "  型号:      $($cpu.Name.Trim())"
Write-Output "  物理核心:  $($cpu.NumberOfCores)  线程: $($cpu.NumberOfLogicalProcessors)"
Write-Output "  基准频率:  $($cpu.MaxClockSpeed) MHz"
Write-Output ""

# ---- 内存 ----
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedPct = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)

Write-Output "【内存】  ← 最关键的指标"
Write-Output "  总量:      $totalGB GB"
Write-Output "  当前可用:  $freeGB GB   (已占用 $usedPct%)"

if ($totalGB -ge 16) {
    Write-Output "  判定:      [可] 满足 DevEco 推荐配置（16 GB）"
} elseif ($totalGB -ge 12) {
    Write-Output "  判定:      [勉强] 高于最低线（8 GB），可开发但模拟器吃力"
} else {
    Write-Output "  判定:      [不足] 仅达最低线，模拟器不可用，必须真机调试"
}
Write-Output ""

# 内存插槽信息（判断是否可扩容）
$slots = Get-CimInstance Win32_PhysicalMemory
Write-Output "  内存条数:  $($slots.Count)"
foreach ($s in $slots) {
    $capGB = [math]::Round($s.Capacity / 1GB, 1)
    Write-Output "    - $capGB GB @ $($s.Speed) MHz  ($($s.Manufacturer.Trim()))"
}
Write-Output ""

# ---- 磁盘 ----
Write-Output "【磁盘】  DevEco 建议 100 GB 可用，最低 30 GB"
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $free = [math]::Round($_.FreeSpace / 1GB, 1)
    $size = [math]::Round($_.Size / 1GB, 1)
    $flag = if ($free -ge 100) { "[推荐]" } elseif ($free -ge 30) { "[可用]" } else { "[不足]" }
    Write-Output "  $($_.DeviceID)  可用 $free GB / 总 $size GB   $flag"
}
Write-Output ""

# ---- 显卡 ----
Write-Output "【显卡】  模拟器依赖 GPU，真机调试则无要求"
Get-CimInstance Win32_VideoController | ForEach-Object {
    $vramGB = if ($_.AdapterRAM -gt 1GB) { [math]::Round($_.AdapterRAM / 1GB, 1) } else { "<1" }
    Write-Output "  $($_.Name.Trim())  (显存约 $vramGB GB)"
}
Write-Output ""

# ---- 屏幕 ----
$w = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$h = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
Add-Type -AssemblyName System.Windows.Forms
Write-Output "【显示器】  DevEco 最低 1280x800，推荐 1920x1080 及以上"
Write-Output "  分辨率:    $w x $h"
Write-Output ""

# ---- 结论 ----
Write-Output "=============================================="
Write-Output " 判定标准（鸿蒙开发）"
Write-Output "=============================================="
Write-Output "  内存 >= 16 GB  → 主开发机首选，可跑模拟器"
Write-Output "  内存 12~16 GB  → 可开发，建议真机调试"
Write-Output "  内存 < 12 GB   → 仅适合写代码，动效验证必须真机"
Write-Output ""
Write-Output "  注意：拾帧项目的出片动画、滑卡手势、视频合成三项"
Write-Output "        都必须在真机上验证帧率，模拟器/预览器不可信。"
Write-Output "=============================================="
