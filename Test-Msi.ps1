$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$msi = (Get-ChildItem -LiteralPath $base -Filter '*.msi' | Select-Object -First 1).FullName
$installDir = Join-Path ${env:ProgramFiles(x86)} 'NT Softphone'
$result = [ordered]@{ identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name; install = $null; repair = $null; uninstall = $null; filesVerified = 0; success = $false }
try {
    if ($result.identity -ne 'NT AUTHORITY\SYSTEM') { throw 'Test must run as SYSTEM' }
    foreach ($step in @(@('install','/i'), @('repair','/fa'))) {
        $log = Join-Path $base ($step[0] + '.log')
        $p = Start-Process msiexec.exe -ArgumentList @($step[1], ('"' + $msi + '"'), '/qn', '/norestart', '/L*v', ('"' + $log + '"')) -Wait -PassThru
        $result[$step[0]] = $p.ExitCode
        if ($p.ExitCode -notin 0,3010) { throw "$($step[0]) failed: $($p.ExitCode)" }
    }
    $manifest = Get-Content (Join-Path $base 'payload-manifest.json') -Raw | ConvertFrom-Json
    foreach ($entry in $manifest) {
        $path = Join-Path $installDir $entry.name
        if (!(Test-Path -LiteralPath $path)) { throw "Missing file: $($entry.name)" }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Hash mismatch: $($entry.name)" }
        $result.filesVerified++
    }
    foreach ($link in @('C:\Users\Public\Desktop\NT Softphone.lnk', 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\NT Softphone\NT Softphone.lnk')) {
        if (!(Test-Path -LiteralPath $link)) { throw "Missing all-users shortcut: $link" }
    }
    $arp = Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object DisplayName -eq 'NT Softphone'
    if (!$arp -or $arp.DisplayVersion -ne '3.21.3' -or $arp.WindowsInstaller -ne 1) { throw 'Machine-wide Windows Installer registration missing' }
    $log = Join-Path $base 'uninstall.log'
    $p = Start-Process msiexec.exe -ArgumentList @('/x', ('"' + $msi + '"'), '/qn', '/norestart', '/L*v', ('"' + $log + '"')) -Wait -PassThru
    $result.uninstall = $p.ExitCode
    if ($p.ExitCode -notin 0,3010) { throw "Uninstall failed: $($p.ExitCode)" }
    if (Test-Path -LiteralPath (Join-Path $installDir 'NT Softphone.exe')) { throw 'Executable remains after uninstall' }
    if (Test-Path -LiteralPath 'C:\Users\Public\Desktop\NT Softphone.lnk') { throw 'Desktop shortcut remains after uninstall' }
    $result.success = $true
} catch {
    $result.error = $_.Exception.Message
} finally {
    $result | ConvertTo-Json | Set-Content (Join-Path $base 'test-result.json') -Encoding UTF8
}
if (!$result.success) { exit 1 }
