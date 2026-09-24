$ErrorActionPreference = 'Stop'

$root = $env:GITHUB_WORKSPACE
if ([string]::IsNullOrWhiteSpace($root)) { $root = (Get-Location).Path }
$cppPath = Join-Path $root 'AccountDlg.cpp'
$rcPath = Join-Path $root 'res\dialog.rc2'
$cpp = [IO.File]::ReadAllText($cppPath)
$rc = [IO.File]::ReadAllText($rcPath)

$marker = 'static CString transportValues[] = {'
$helper = @(
'static const CString kBdPbxDomainSuffix = _T(".bdpbx.com");',
'',
'static CString BdPbxDisplayValue(const CString& value)',
'{',
'    CString v = value;',
'    v.Trim();',
'    int colon = v.Find(_T(":"));',
'    if (colon > 0) v = v.Left(colon);',
'    if (v.GetLength() >= kBdPbxDomainSuffix.GetLength() && v.Right(kBdPbxDomainSuffix.GetLength()).CompareNoCase(kBdPbxDomainSuffix) == 0) {',
'        v = v.Left(v.GetLength() - kBdPbxDomainSuffix.GetLength());',
'    } else {',
'        int dot = v.Find(_T("."));',
'        if (dot > 0) v = v.Left(dot);',
'    }',
'    v.Trim(_T("."));',
'    return v;',
'}',
'',
'static CString BdPbxFullValue(const CString& value)',
'{',
'    CString v = BdPbxDisplayValue(value);',
'    if (v.IsEmpty()) return _T("");',
'    return v + kBdPbxDomainSuffix;',
'}',
''
) -join [Environment]::NewLine

if (-not $cpp.Contains('static const CString kBdPbxDomainSuffix')) {
    if (-not $cpp.Contains($marker)) { throw 'AccountDlg transport marker not found.' }
    $cpp = $cpp.Replace($marker, $helper + [Environment]::NewLine + $marker)
}

$loadPattern = '(?s)edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_SERVER\);.*?edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_USERNAME\);'
$cpp = [regex]::Replace($cpp, $loadPattern, {
    param($m)
    return 'edit = (CEdit*)GetDlgItem(IDC_EDIT_SERVER);' + [Environment]::NewLine +
        '`tedit->SetWindowText(BdPbxDisplayValue(m_Account.server));' + [Environment]::NewLine + [Environment]::NewLine +
        '`tedit = (CEdit*)GetDlgItem(IDC_EDIT_USERNAME);'
}, 1)

$savePattern = '(?s)edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_SERVER\);.*?edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_USERNAME\);'
$cpp = [regex]::Replace($cpp, $savePattern, {
    param($m)
    return 'edit = (CEdit*)GetDlgItem(IDC_EDIT_SERVER);' + [Environment]::NewLine +
        '`tedit->GetWindowText(str);' + [Environment]::NewLine +
        '`tm_Account.server = BdPbxFullValue(str);' + [Environment]::NewLine +
        '`tm_Account.proxy = m_Account.server;' + [Environment]::NewLine +
        '`tm_Account.domain = m_Account.server;' + [Environment]::NewLine + [Environment]::NewLine +
        '`tedit = (CEdit*)GetDlgItem(IDC_EDIT_USERNAME);'
}, 1)

$cpp = [regex]::Replace($cpp, '\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_AUTHID\);\r?\n\s*edit->SetWindowText\(m_Account\.authID\);', '', 1)
$cpp = [regex]::Replace($cpp, '\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_AUTHID\);\r?\n\s*edit->GetWindowText\(str\);\r?\n\s*m_Account\.authID\s*=\s*str\.Trim\(\);', '', 1)
$cpp = $cpp.Replace('m_Account.domain.IsEmpty()', 'm_Account.server.IsEmpty()')
[IO.File]::WriteAllText($cppPath, $cpp, [Text.UTF8Encoding]::new($false))

$rc = $rc.Replace('RTEXT           "SIP Server", IDC_STATIC, 7, 10 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS', 'RTEXT           "ID", IDC_STATIC, 7, 10 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS')
$rc = $rc.Replace('RTEXT           "SIP Proxy", IDC_STATIC, 7, 29 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS', 'RTEXT           "SIP Proxy", IDC_STATIC, 7, 29 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS | NOT WS_VISIBLE')
$rc = $rc.Replace('LTEXT           "*" , IDC_ACCOUNT_REQUIRED_USERNAME', 'LTEXT           "*" , IDC_ACCOUNT_REQUIRED_USERNAME')
$rc = $rc.Replace('"Username"', '"Extension / User"')
$rc = $rc.Replace('86, 52 + IDD_ACCOUNT_OFF_LABEL, 127, 14, ES_AUTOHSCROLL', '86, 26 + IDD_ACCOUNT_OFF_LABEL, 127, 14, ES_AUTOHSCROLL')
$rc = $rc.Replace('LTEXT           "*", IDC_ACCOUNT_REQUIRED_DOMAIN, 78, 74 + IDD_ACCOUNT_OFF_LABEL, 8, 5', 'LTEXT           "*", IDC_ACCOUNT_REQUIRED_DOMAIN, 78, 74 + IDD_ACCOUNT_OFF_LABEL, 8, 5 | NOT WS_VISIBLE')
$rc = $rc.Replace('RTEXT           "Domain", IDC_STATIC, 7, 74 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS', 'RTEXT           "Domain", IDC_STATIC, 7, 74 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS | NOT WS_VISIBLE')
$rc = $rc.Replace('RTEXT           "Login", IDC_STATIC, 7, 93 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS', 'RTEXT           "Login", IDC_STATIC, 7, 93 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS | NOT WS_VISIBLE')
$rc = $rc.Replace('EDITTEXT        IDC_EDIT_AUTHID, 86, 90 + IDD_ACCOUNT_OFF_LABEL, 127, 14, ES_AUTOHSCROLL', 'EDITTEXT        IDC_EDIT_AUTHID, 86, 90 + IDD_ACCOUNT_OFF_LABEL, 127, 14, ES_AUTOHSCROLL | NOT WS_VISIBLE')
$rc = $rc.Replace('RTEXT' + [Environment]::NewLine + '"Password"' + [Environment]::NewLine + ', IDC_STATIC, 7, 112 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS', 'RTEXT           "Password", IDC_STATIC, 7, 48 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS')
$rc = $rc.Replace('86, 109 + IDD_ACCOUNT_OFF_LABEL, 127, 14, ES_AUTOHSCROLL | ES_PASSWORD', '86, 45 + IDD_ACCOUNT_OFF_LABEL, 127, 14, ES_AUTOHSCROLL | ES_PASSWORD')
$rc = $rc.Replace('86, 125 + IDD_ACCOUNT_OFF_LABEL, 120, 8', '86, 61 + IDD_ACCOUNT_OFF_LABEL, 120, 8')
[IO.File]::WriteAllText($rcPath, $rc, [Text.UTF8Encoding]::new($false))

Write-Host 'BD PBX account UI: ID + Extension/User + Password; backend fills server/proxy/domain and uses username as auth ID.'
