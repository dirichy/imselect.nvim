param([ValidateSet('im_select', 'winime', 'wsl')][string]$Driver)
$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$output = Join-Path $root '.dev/native'
New-Item -ItemType Directory -Force $output | Out-Null
$report = Join-Path $output "$Driver.json"
if (Test-Path $report) { Remove-Item $report }
$control = Join-Path $root 'tests/native/windows-control.ps1'
$env:IMSELECT_TEST_DRIVER = $Driver
$env:IMSELECT_TEST_OBSERVER = ConvertTo-Json -Compress @('powershell.exe', '-NoProfile', '-NonInteractive', '-File', $control, $Driver)
$env:IMSELECT_TEST_REPORT = $report
if ($Driver -eq 'wsl') {
    # The Linux Neovim and Windows PowerShell communicate through genuine WSL interop.
    $linuxRoot = & wsl.exe -d imselect-test --exec wslpath -a $root.Replace('\', '/')
    if ($LASTEXITCODE -ne 0 -or -not $linuxRoot) { throw 'Cannot translate the checkout path into WSL' }
    $linuxRoot = $linuxRoot.Trim()
    $linuxReport = & wsl.exe -d imselect-test --exec wslpath -a $report.Replace('\', '/')
    if ($LASTEXITCODE -ne 0) { throw 'Cannot translate the checkout path into WSL' }
    $linuxReport = $linuxReport.Trim()
    $env:WSLENV = 'IMSELECT_TEST_DRIVER:IMSELECT_TEST_OBSERVER:IMSELECT_TEST_REPORT'
    $env:IMSELECT_TEST_REPORT = $linuxReport
    $process = Start-Process -PassThru wsl.exe -ArgumentList @('-d', 'imselect-test', '--cd', "`"$linuxRoot`"", '--', 'nvim', '-n', '-i', 'NONE', '-u', 'NONE', '-c', '"luafile tests/native/state.lua"')
} else {
    $process = Start-Process -PassThru (Get-Command nvim).Source -ArgumentList @('-n', '-i', 'NONE', '-u', 'NONE', '-c', '"luafile tests/native/state.lua"')
}
try {
    $shell = New-Object -ComObject WScript.Shell
    $focused = $false
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if ($shell.AppActivate($process.Id)) { $focused = $true; break }
        if ($process.HasExited) { break }
        Start-Sleep -Milliseconds 100
    }
    if (-not $focused) { throw 'Runner cannot focus a real terminal; an interactive desktop is required' }
    if (-not $process.WaitForExit(120000)) { throw 'Native driver test timed out' }
    if (-not (Test-Path $report)) { throw 'Native test produced no result' }
    $result = Get-Content -Raw $report | ConvertFrom-Json
    $result | ConvertTo-Json
    if (-not $result.passed) { throw $result.error }
    if ($process.ExitCode -ne 0) { throw "Terminal exited with code $($process.ExitCode)" }
} finally {
    if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
}
