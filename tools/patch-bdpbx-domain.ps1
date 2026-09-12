$ErrorActionPreference = 'Stop'
$root = $env:GITHUB_WORKSPACE
if ([string]::IsNullOrWhiteSpace($root)) { $root = (Get-Location).Path }

$cppPath = Join-Path $root 'AccountDlg.cpp'
$rcPath = Join-Path $root 'res\dialog.rc2'

$cpp = [IO.File]::ReadAllText($cppPath)

$marker = 'static CString transportValues[] = {'
$helper = @'
static const CString kBdPbxDomainSuffix = _T(".bdpbx.com");

static CString BdPbxDisplayValue(const CString& value)
{
    CString v = value.Trim();
    int colon = v.Find(_T(":"));
    CString port;
    if (colon > 0) {
        port = v.Mid(colon);
        v = v.Left(colon);
    }
    CString lower = v;
    lower.MakeLower();
    CString suffix = kBdPbxDomainSuffix;
    CString suffixLower = suffix;
    suffixLower.MakeLower();
    if (lower.Right(suffixLower.GetLength()) == suffixLower) {
        v = v.Left(v.GetLength() - suffix.GetLength());
    }
    else {
        int dot = v.Find(_T("."));
        if (dot > 0) {
            v = v.Left(dot);
        }
    }
    v.Trim(_T("."));
    return v;
}

static CString BdPbxFullValue(const CString& value)
{
    CString v = value.Trim();
    int colon = v.Find(_T(":"));
    CString port;
    if (colon > 0) {
        port = v.Mid(colon);
        v = v.Left(colon);
    }
    CString lower = v;
    lower.MakeLower();
    CString suffix = kBdPbxDomainSuffix;
    CString suffixLower = suffix;
    suffixLower.MakeLower();
    if (lower.Right(suffixLower.GetLength()) == suffixLower) {
        v = v.Left(v.GetLength() - suffix.GetLength());
    }
    else {
        int dot = v.Find(_T("."));
        if (dot > 0) {
            v = v.Left(dot);
        }
    }
    v.Trim(_T("."));
    if (v.IsEmpty()) {
        return _T("");
    }
    return v + suffix + port;
}

'@
if ($cpp.Contains($helper)) { throw 'BD PBX domain helper is already present.' }
$cpp = $cpp.Replace($marker, $helper + $marker)

$oldLoad = @'
edit = (CEdit*)GetDlgItem(IDC_EDIT_SERVER);
edit->SetWindowText(m_Account.server);
edit = (CEdit*)GetDlgItem(IDC_EDIT_PROXY);
edit->SetWindowText(m_Account.proxy);
edit = (CEdit*)GetDlgItem(IDC_EDIT_DOMAIN);
edit->SetWindowText(m_Account.domain);
'@
$newLoad = @'
edit = (CEdit*)GetDlgItem(IDC_EDIT_SERVER);
edit->SetWindowText(BdPbxDisplayValue(m_Account.server));
edit = (CEdit*)GetDlgItem(IDC_EDIT_PROXY);
edit->SetWindowText(BdPbxDisplayValue(m_Account.proxy));
edit = (CEdit*)GetDlgItem(IDC_EDIT_DOMAIN);
edit->SetWindowText(BdPbxDisplayValue(m_Account.domain));
'@
if (-not $cpp.Contains($oldLoad)) { throw 'Account Load block not found.' }
$cpp = $cpp.Replace($oldLoad, $newLoad)

$oldSave = @'
edit = (CEdit*)GetDlgItem(IDC_EDIT_SERVER);
edit->GetWindowText(str);
m_Account.server=str.Trim();
edit = (CEdit*)GetDlgItem(IDC_EDIT_PROXY);
edit->GetWindowText(str);
m_Account.proxy=str.Trim();
edit = (CEdit*)GetDlgItem(IDC_EDIT_DOMAIN);
edit->GetWindowText(str);
m_Account.domain=str.Trim();
'@
$newSave = @'
edit = (CEdit*)GetDlgItem(IDC_EDIT_SERVER);
edit->GetWindowText(str);
m_Account.server=BdPbxFullValue(str);
edit = (CEdit*)GetDlgItem(IDC_EDIT_PROXY);
edit->GetWindowText(str);
m_Account.proxy=BdPbxFullValue(str);
edit = (CEdit*)GetDlgItem(IDC_EDIT_DOMAIN);
edit->GetWindowText(str);
m_Account.domain=BdPbxFullValue(str);
'@
if (-not $cpp.Contains($oldSave)) { throw 'Account Save block not found.' }
$cpp = $cpp.Replace($oldSave, $newSave)

[IO.File]::WriteAllText($cppPath, $cpp, [Text.UTF8Encoding]::new($false))

$rc = [IO.File]::ReadAllText($rcPath)
$oldServer = @'EDITTEXT        IDC_EDIT_SERVER, 86, 7 + IDD_ACCOUNT_OFF_LABEL,
127
, 14, ES_AUTOHSCROLL
'@
$newServer = @'EDITTEXT        IDC_EDIT_SERVER, 86, 7 + IDD_ACCOUNT_OFF_LABEL,
78
, 14, ES_AUTOHSCROLL
LTEXT           ".bdpbx.com", IDC_STATIC, 166, 10 + IDD_ACCOUNT_OFF_LABEL, 47, 8
'@
$oldProxy = @'EDITTEXT        IDC_EDIT_PROXY, 86, 26 + IDD_ACCOUNT_OFF_LABEL,
127
, 14, ES_AUTOHSCROLL
'@
$newProxy = @'EDITTEXT        IDC_EDIT_PROXY, 86, 26 + IDD_ACCOUNT_OFF_LABEL,
78
, 14, ES_AUTOHSCROLL
LTEXT           ".bdpbx.com", IDC_STATIC, 166, 29 + IDD_ACCOUNT_OFF_LABEL, 47, 8
'@
$oldDomain = @'EDITTEXT        IDC_EDIT_DOMAIN, 86, 71 + IDD_ACCOUNT_OFF_LABEL,
127
, 14, ES_AUTOHSCROLL
'@
$newDomain = @'EDITTEXT        IDC_EDIT_DOMAIN, 86, 71 + IDD_ACCOUNT_OFF_LABEL,
78
, 14, ES_AUTOHSCROLL
LTEXT           ".bdpbx.com", IDC_STATIC, 166, 74 + IDD_ACCOUNT_OFF_LABEL, 47, 8
'@
foreach ($pair in @(@($oldServer,$newServer), @($oldProxy,$newProxy), @($oldDomain,$newDomain))) {
    if (-not $rc.Contains($pair[0])) { throw 'Account domain resource block not found.' }
    $rc = $rc.Replace($pair[0], $pair[1])
}
[IO.File]::WriteAllText($rcPath, $rc, [Text.UTF8Encoding]::new($false))

Write-Host 'BD PBX fixed-domain UI/source patch applied: *.bdpbx.com'
