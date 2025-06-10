param(
    [string]$Mode = 'local'
)


$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Set-PSDebug -Trace 1

if ($Mode -eq 'local') {
    moon fmt
    moon info --target native
    Remove-Item src/errno/linux/linux.mbti
    Remove-Item src/errno/win32/win32.mbti
    moon check --target native
}


# $env:MOON_CC = 'cl.exe /fsanitize=address /Z7'

moon test --target native
Set-Location .\tests
moon test --target native
Set-Location ..

Set-PSDebug -Trace 0
$ErrorActionPreference = 'Continue'