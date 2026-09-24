$ErrorActionPreference = 'Stop'
$root = $env:GITHUB_WORKSPACE
if ([string]::IsNullOrWhiteSpace($root)) { $root = (Get-Location).Path }

$cppPath = Join-Path $root 'AccountDlg.cpp'
$rcPath = Join-Path $root 'res\dialog.rc2'
$cpp = [IO.File]::ReadAllText($cppPath)

$marker = 'static CString transportValues[] = {'
$helper = @(
'static const CString kBdPbxDomainSuffix = _T(".bdpbx.com");',
'',
'static CString BdPbxDisplayValue(const CString& value)',
'{',
'    CString v = value;',
'    while (!v.IsEmpty() && (v[0] == _T('' '') || v[0] == _T(''\t'') || v[0] == _T(''\r'') || v[0] == _T(''\n''))) v = v.Mid(1);',
'    while (!v.IsEmpty() && (v[v.GetLength() - 1] == _T('' '') || v[v.GetLength() - 1] == _T(''\t'') || v[v.GetLength() - 1] == _T(''\r'') || v[v.GetLength() - 1] == _T(''\n''))) v = v.Left(v.GetLength() - 1);',
'    int colon = v.Find(_T(":"));',
'    if (colon > 0) v = v.Left(colon);',
'    if (v.GetLength() >= kBdPbxDomainSuffix.GetLength() && v.Right(kBdPbxDomainSuffix.GetLength()).CompareNoCase(kBdPbxDomainSuffix) == 0) {',
'        v = v.Left(v.GetLength() - kBdPbxDomainSuffix.GetLength());',
'    } else {',
'        int dot = v.Find(_T("."));',
'        if (dot > 0) v = v.Left(dot);',
'    }',
'    while (!v.IsEmpty() && v[0] == _T(''.'')) v = v.Mid(1);',
'    while (!v.IsEmpty() && v[v.GetLength() - 1] == _T(''.'')) v = v.Left(v.GetLength() - 1);',
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
) -join "`r`n"
if (-not $cpp.Contains('static const CString kBdPbxDomainSuffix')) {
    if (-not $cpp.Contains($marker)) { throw 'AccountDlg transport marker not found.' }
    $cpp = $cpp.Replace($marker, $helper + $marker)
}

$cpp = $cpp.Replace('edit->SetWindowText(m_Account.server);', 'edit->SetWindowText(BdPbxDisplayValue(m_Account.server));')
$cpp = [regex]::Replace($cpp, '(?s)edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_SERVER\);\s*edit->SetWindowText\(BdPbxDisplayValue\(m_Account\.server\)\);.*?edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_USERNAME\);', 'edit = (CEdit*)GetDlgItem(IDC_EDIT_SERVER);\r\n\tedit->SetWindowText(BdPbxDisplayValue(m_Account.server));\r\n\r\n\tedit = (CEdit*)GetDlgItem(IDC_EDIT_USERNAME);', 1)
$cpp = [regex]::Replace($cpp, '(?s)edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_SERVER\);\s*edit->GetWindowText\(str\);\s*m_Account\.server\s*=\s*BdPbxFullValue\(str\);.*?edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_USERNAME\);', 'edit = (CEdit*)GetDlgItem(IDC_EDIT_SERVER);\r\n\tedit->GetWindowText(str);\r\n\tm_Account.server = BdPbxFullValue(str);\r\n\tm_Account.proxy = m_Account.server;\r\n\tm_Account.domain = m_Account.server;\r\n\r\n\tedit = (CEdit*)GetDlgItem(IDC_EDIT_USERNAME);', 1, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$cpp = [regex]::Replace($cpp, '\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_AUTHID\);\r?\n\s*edit->SetWindowText\(m_Account\.authID\);', '', 1)
$cpp = [regex]::Replace($cpp, '\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_AUTHID\);\r?\n\s*edit->GetWindowText\(str\);\r?\n\s*m_Account\.authID\s*=\s*str\.Trim\(\);', '', 1)
[IO.File]::WriteAllText($cppPath, $cpp, [Text.UTF8Encoding]::new($false))

$rc = [IO.File]::ReadAllText($rcPath)
$accountUi = @'
RTEXT           "Account Name", IDC_STATIC, 7, 10, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_ACCOUNT_LABEL, 86, 7, 127, 14, ES_AUTOHSCROLL
RTEXT           "ID", IDC_STATIC, 7, 10 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_EDIT_SERVER, 86, 7 + IDD_ACCOUNT_OFF_LABEL, 127, 14, ES_AUTOHSCROLL
LTEXT           "*", IDC_ACCOUNT_REQUIRED_USERNAME, 78, 29 + IDD_ACCOUNT_OFF_LABEL, 8, 5
RTEXT           "Extension / User", IDC_STATIC, 7, 29 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_EDIT_USERNAME, 86, 26 + IDD_ACCOUNT_OFF_LABEL, 127, 14, ES_AUTOHSCROLL
RTEXT           "Password", IDC_STATIC, 7, 48 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_EDIT_PASSWORD, 86, 45 + IDD_ACCOUNT_OFF_LABEL, 127, 14, ES_AUTOHSCROLL | ES_PASSWORD
CONTROL         "", IDC_SYSLINK_DISPLAY_PASSWORD, "SysLink", WS_TABSTOP, 86, 61 + IDD_ACCOUNT_OFF_LABEL, 120, 8
'@
$rc = [regex]::Replace($rc, '(?s)RTEXT\s+"Account Name".*?(?=RTEXT\s+"Password")', $accountUi, 1, [System.Text.RegularExpressions.RegexOptions]::Singleline)
[IO.File]::WriteAllText($rcPath, $rc, [Text.UTF8Encoding]::new($false))

Write-Host 'BD PBX account UI: ID + Extension/User; backend fills server/proxy/domain and uses username as auth ID.'
