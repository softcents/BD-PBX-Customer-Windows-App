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
$cpp = $cpp.Replace('edit->SetWindowText(m_Account.proxy);', 'edit->SetWindowText(BdPbxDisplayValue(m_Account.proxy));')
$cpp = $cpp.Replace('edit->SetWindowText(m_Account.domain);', 'edit->SetWindowText(BdPbxDisplayValue(m_Account.domain));')
$cpp = $cpp.Replace('m_Account.server=str.Trim();', 'm_Account.server=BdPbxFullValue(str);')
$cpp = $cpp.Replace('m_Account.proxy=str.Trim();', 'm_Account.proxy=BdPbxFullValue(str);')
$cpp = $cpp.Replace('m_Account.domain=str.Trim();', 'm_Account.domain=BdPbxFullValue(str);')
[IO.File]::WriteAllText($cppPath, $cpp, [Text.UTF8Encoding]::new($false))

$rc = [IO.File]::ReadAllText($rcPath)
$domainSuffix = 'LTEXT           ".bdpbx.com", IDC_STATIC, 166, '
$controls = @(
    @{ id='IDC_EDIT_SERVER'; y='7'; labelY='10' },
    @{ id='IDC_EDIT_PROXY'; y='26'; labelY='29' },
    @{ id='IDC_EDIT_DOMAIN'; y='71'; labelY='74' }
)
foreach ($c in $controls) {
    $pattern = 'EDITTEXT\s+' + [regex]::Escape($c.id) + ',\s*86,\s*' + $c.y + '\s*\+\s*IDD_ACCOUNT_OFF_LABEL,\s*127\s*,\s*14,\s*ES_AUTOHSCROLL'
    $replacement = 'EDITTEXT        ' + $c.id + ', 86, ' + $c.y + ' + IDD_ACCOUNT_OFF_LABEL, 78, 14, ES_AUTOHSCROLL' + "`r`n" + $domainSuffix + $c.labelY + ' + IDD_ACCOUNT_OFF_LABEL, 47, 8'
    $newRc = [regex]::Replace($rc, $pattern, $replacement, 1)
    if ($newRc -eq $rc) { throw ('Account domain resource block not found: ' + $c.id) }
    $rc = $newRc
}
[IO.File]::WriteAllText($rcPath, $rc, [Text.UTF8Encoding]::new($false))

Write-Host 'BD PBX fixed-domain UI/source patch applied: *.bdpbx.com'