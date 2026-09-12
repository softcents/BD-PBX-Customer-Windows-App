$ErrorActionPreference = 'Stop'
$root = $env:GITHUB_WORKSPACE
if ([string]::IsNullOrWhiteSpace($root)) { $root = (Get-Location).Path }

$cppPath = Join-Path $root 'mainDlg.cpp'
$cpp = [IO.File]::ReadAllText($cppPath)

$checkPattern = '(?s)void CmainDlg::OnCheckUpdates\(\)\s*\{.*?\}\s*\r?\n\s*void CmainDlg::CheckUpdates\(\)\s*\{.*?\}\s*\r?\n\s*LRESULT CmainDlg::OnUpdateCheckerLoaded'
$checkReplacement = @'
void CmainDlg::OnCheckUpdates()
{
    // BD PBX: update notifications are permanently disabled.
}

void CmainDlg::CheckUpdates()
{
    // BD PBX: no remote update check.
}

LRESULT CmainDlg::OnUpdateCheckerLoaded
'@
$newCpp = [regex]::Replace($cpp, $checkPattern, $checkReplacement, 1)
if ($newCpp -eq $cpp) { throw 'Update-check handler block was not found.' }
$cpp = $newCpp

$websitePattern = '(?s)void CmainDlg::OnMenuWebsite\(\)\s*\{.*?\}\s*\r?\n\s*void CmainDlg::OnMenuHelp\(\)\s*\{.*?\}'
$websiteReplacement = @'
void CmainDlg::OnMenuWebsite()
{
    MSIP::OpenURL(_T("https://bdpbx.com"));
}

void CmainDlg::OnMenuHelp()
{
    MSIP::OpenURL(_T("https://bdpbx.com"));
}
'@
$newCpp = [regex]::Replace($cpp, $websitePattern, $websiteReplacement, 1)
if ($newCpp -eq $cpp) { throw 'Website/help handler block was not found.' }
$cpp = $newCpp

[IO.File]::WriteAllText($cppPath, $cpp, [Text.UTF8Encoding]::new($false))

$settingsPath = Join-Path $root 'settings.cpp'
$settings = [IO.File]::ReadAllText($settingsPath)
$settings = $settings.Replace('GetPrivateProfileString(section, _T("updatesInterval"), NULL, ptr, 256, iniFile);', 'GetPrivateProfileString(section, _T("updatesInterval"), _T("never"), ptr, 256, iniFile);')
[IO.File]::WriteAllText($settingsPath, $settings, [Text.UTF8Encoding]::new($false))

Write-Host 'BD PBX update checker disabled; Website and Help forced to https://bdpbx.com.'