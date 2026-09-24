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
$cpp = [regex]::Replace($cpp, '\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_PROXY\);\r?\n\s*edit->SetWindowText\(m_Account\.proxy\);\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_DOMAIN\);\r?\n\s*edit->SetWindowText\(m_Account\.domain\);', '')
$cpp = [regex]::Replace($cpp, 'm_Account\.server\s*=\s*str\.Trim\(\);', 'm_Account.server = BdPbxFullValue(str); m_Account.proxy = m_Account.server; m_Account.domain = m_Account.server;')
$cpp = [regex]::Replace($cpp, '\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_PROXY\);\r?\n\s*edit->GetWindowText\(str\);\r?\n\s*m_Account\.proxy\s*=\s*BdPbxFullValue\(str\);\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_DOMAIN\);\r?\n\s*edit->GetWindowText\(str\);\r?\n\s*m_Account\.domain\s*=\s*BdPbxFullValue\(str\);', '')
$cpp = $cpp.Replace('m_Account.domain.IsEmpty()', 'm_Account.server.IsEmpty()')
$cpp = $cpp.Replace('if (m_Account.domain.IsEmpty()) {', 'if (m_Account.server.IsEmpty()) {')
$cpp = $cpp.Replace('if (!m_Account.server.IsEmpty()) m_Account.domain = m_Account.server;', 'if (!m_Account.server.IsEmpty()) m_Account.domain = m_Account.server;')
[IO.File]::WriteAllText($cppPath, $cpp, [Text.UTF8Encoding]::new($false))

$rc = [IO.File]::ReadAllText($rcPath)
# One visible fixed-domain input: user enters only the subdomain.
# The backend copies the normalized full domain into server, proxy and domain.
$rc = [regex]::Replace($rc, 'RTEXT\s+"SIP Server",\s*IDC_STATIC,\s*7,\s*10\s*\+\s*IDD_ACCOUNT_OFF_LABEL,\s*70,\s*8,\s*SS_WORDELLIPSIS', 'RTEXT           "ID", IDC_STATIC, 7, 10 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS', 1)
$rc = [regex]::Replace($rc, 'RTEXT\s+"SIP Proxy",\s*IDC_STATIC,\s*7,\s*29\s*\+\s*IDD_ACCOUNT_OFF_LABEL,\s*70,\s*8,\s*SS_WORDELLIPSIS\r?\nEDITTEXT\s+IDC_EDIT_PROXY[^\r\n]*\r?\n(?:\d+\r?\n)?', '', 1)
$rc = [regex]::Replace($rc, 'LTEXT\s+"\*",\s*IDC_ACCOUNT_REQUIRED_DOMAIN[^\r\n]*\r?\n', '', 1)
$rc = [regex]::Replace($rc, 'RTEXT\s+"Domain",\s*IDC_STATIC,\s*7,\s*74\s*\+\s*IDD_ACCOUNT_OFF_LABEL[^\r\n]*\r?\nEDITTEXT\s+IDC_EDIT_DOMAIN[^\r\n]*\r?\n(?:\d+\r?\n)?', '', 1)
$rc = [regex]::Replace($rc, 'CONTROL\s+"<a>\?</a>",\s*IDC_SYSLINK_SIP_PROXY[^\r\n]*\r?\n', '', 1)
$rc = [regex]::Replace($rc, 'CONTROL\s+"<a>\?</a>",\s*IDC_SYSLINK_DOMAIN[^\r\n]*\r?\n', '', 1)
$rc = [regex]::Replace($rc, 'RTEXT\s+"Username",\s*IDC_STATIC[^\r\n]*', 'RTEXT           "Extension / User", IDC_STATIC, 7, 55 + IDD_ACCOUNT_OFF_LABEL, 70, 8, SS_WORDELLIPSIS', 1)
$rc = [regex]::Replace($rc, 'LTEXT\s+"\*",\s*IDC_ACCOUNT_REQUIRED_USERNAME[^\r\n]*\r?\n', 'LTEXT           "*", IDC_ACCOUNT_REQUIRED_USERNAME, 78, 55 + IDD_ACCOUNT_OFF_LABEL, 8, 5\r\n', 1)
$rc = [regex]::Replace($rc, 'RTEXT\s+"Login",\s*IDC_STATIC[^\r\n]*\r?\nEDITTEXT\s+IDC_EDIT_AUTHID[^\r\n]*\r?\n', '', 1)
[IO.File]::WriteAllText($rcPath, $rc, [Text.UTF8Encoding]::new($false))

Write-Host 'BD PBX account UI: ID + Extension/User; backend fills server/proxy/domain and uses username as auth ID.'
