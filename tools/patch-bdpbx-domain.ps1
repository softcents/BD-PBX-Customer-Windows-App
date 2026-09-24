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
        'edit->SetWindowText(BdPbxDisplayValue(m_Account.server));' + [Environment]::NewLine + [Environment]::NewLine +
        'edit = (CEdit*)GetDlgItem(IDC_EDIT_USERNAME);'
}, 1)

$savePattern = '(?s)edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_SERVER\);.*?edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_USERNAME\);'
$cpp = [regex]::Replace($cpp, $savePattern, {
    param($m)
    return 'edit = (CEdit*)GetDlgItem(IDC_EDIT_SERVER);' + [Environment]::NewLine +
        'edit->GetWindowText(str);' + [Environment]::NewLine +
        'm_Account.server = BdPbxFullValue(str);' + [Environment]::NewLine +
        'm_Account.proxy = m_Account.server;' + [Environment]::NewLine +
        'm_Account.domain = m_Account.server;' + [Environment]::NewLine + [Environment]::NewLine +
        'edit = (CEdit*)GetDlgItem(IDC_EDIT_USERNAME);'
}, 1)

$cpp = [regex]::Replace($cpp, '\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_AUTHID\);\r?\n\s*edit->SetWindowText\(m_Account\.authID\);', '', 1)
$cpp = [regex]::Replace($cpp, '\r?\n\s*edit = \(CEdit\*\)GetDlgItem\(IDC_EDIT_AUTHID\);\r?\n\s*edit->GetWindowText\(str\);\r?\n\s*m_Account\.authID\s*=\s*str\.Trim\(\);', '', 1)
$cpp = [regex]::Replace($cpp, 'm_Account\.domain\.IsEmpty\(\)\s*\|\|\s*m_Account\.username\.IsEmpty\(\)', { param($m) 'm_Account.server.IsEmpty() ||' + [Environment]::NewLine + "`t`t" + 'm_Account.username.IsEmpty() ||' + [Environment]::NewLine + "`t`t" + 'm_Account.password.IsEmpty()' }, 1)
$cpp = $cpp.Replace('accountId = -1;', 'accountId = -1;' + [Environment]::NewLine + "`t" + 'm_bdGreenBrush.CreateSolidBrush(RGB(0, 106, 78));' + [Environment]::NewLine + "`t" + 'm_bdBlueBrush.CreateSolidBrush(RGB(0, 51, 102));' + [Environment]::NewLine + "`t" + 'm_bdRedBrush.CreateSolidBrush(RGB(218, 41, 28));')
$cpp = $cpp.Replace('TranslateDialog(this->m_hWnd);', 'SetIcon((HICON)LoadImage(AfxGetInstanceHandle(), MAKEINTRESOURCE(IDI_MAINFRAME), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR), FALSE);' + [Environment]::NewLine + 'SetIcon((HICON)LoadImage(AfxGetInstanceHandle(), MAKEINTRESOURCE(IDI_MAINFRAME), IMAGE_ICON, 32, 32, LR_DEFAULTCOLOR), TRUE);' + [Environment]::NewLine + [Environment]::NewLine + 'TranslateDialog(this->m_hWnd);')
$cpp = $cpp.Replace('ON_WM_CREATE()' + [Environment]::NewLine, 'ON_WM_CREATE()' + [Environment]::NewLine + 'ON_WM_CTLCOLOR()' + [Environment]::NewLine)
$ctl = @('HBRUSH AccountDlg::OnCtlColor(CDC* pDC, CWnd* pWnd, UINT nCtlColor)','{' ,'HBRUSH hbr = CDialog::OnCtlColor(pDC, pWnd, nCtlColor);','if (!pWnd) return hbr;','const int id = pWnd->GetDlgCtrlID();','`tif (nCtlColor == CTLCOLOR_STATIC) {','    pDC->SetTextColor((id == IDC_SYSLINK_DISPLAY_PASSWORD) ? RGB(0, 106, 78) : RGB(0, 51, 102));','    pDC->SetBkColor(GetSysColor(COLOR_3DFACE));','    return GetSysColorBrush(COLOR_3DFACE);',' }','`tif (nCtlColor == CTLCOLOR_EDIT || nCtlColor == CTLCOLOR_LISTBOX) {','`t`tpDC->SetTextColor(RGB(20, 20, 20));','`t`tpDC->SetBkColor(RGB(255, 255, 255));','    return GetSysColorBrush(COLOR_WINDOW);','`t}','`tif (nCtlColor == CTLCOLOR_BTN) {','    if (id == IDOK) return (HBRUSH)m_bdGreenBrush.GetSafeHandle();','`t`tif (id == IDCANCEL) return (HBRUSH)m_bdBlueBrush.GetSafeHandle();','`t}','return hbr;','}','') -join [Environment]::NewLine
if (-not $cpp.Contains('HBRUSH AccountDlg::OnCtlColor')) { $cpp = $cpp.Replace('void AccountDlg::OnDestroy()', $ctl + [Environment]::NewLine + 'void AccountDlg::OnDestroy()') }
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

$accountBlock = @'
#define IDD_ACCOUNT_OFF_LABEL 19
#define IDD_ACCOUNT_OFF_HIDE_CID 0
#define IDD_ACCOUNT_OFFSET_KEEP_ALIVE 0
#define IDD_ACCOUNT_OFFSET_CUSTOM_LINK 286
#define IDD_ACCOUNT_OFF_FINAL 305

IDD_ACCOUNT DIALOGEX 0, 0, 236, IDD_ACCOUNT_OFF_FINAL
STYLE DS_SETFONT | WS_CAPTION | WS_SYSMENU | DS_MODALFRAME | WS_POPUP | WS_VISIBLE
CAPTION "Account"
FONT 8, "Microsoft Sans Serif", 400, 0, 0x1
BEGIN
RTEXT           "Account Name", IDC_STATIC, 7, 10, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_ACCOUNT_LABEL, 86, 7, 127, 14, ES_AUTOHSCROLL
RTEXT           "ID", IDC_STATIC, 7, 29, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_EDIT_SERVER, 86, 26, 127, 14, ES_AUTOHSCROLL
CONTROL         "<a>?</a>", IDC_SYSLINK_SIP_SERVER, "SysLink", 0x0, 222, 28, 7, 8
LTEXT           "*", IDC_ACCOUNT_REQUIRED_USERNAME, 78, 48, 8, 5
RTEXT           "Extension / User", IDC_STATIC, 7, 48, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_EDIT_USERNAME, 86, 45, 127, 14, ES_AUTOHSCROLL
CONTROL         "<a>?</a>", IDC_SYSLINK_USERNAME, "SysLink", 0x0, 222, 47, 7, 8
LTEXT           "*", IDC_STATIC, 78, 67, 8, 5
RTEXT           "Password", IDC_STATIC, 7, 67, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_EDIT_PASSWORD, 86, 64, 127, 14, ES_AUTOHSCROLL | ES_PASSWORD
CONTROL         "<a>?</a>", IDC_SYSLINK_PASSWORD, "SysLink", 0x0, 222, 66, 7, 8
CONTROL         "", IDC_SYSLINK_DISPLAY_PASSWORD, "SysLink", WS_TABSTOP, 86, 80, 120, 8
RTEXT           "Display Name", IDC_STATIC, 7, 91, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_EDIT_DISPLAYNAME, 86, 88, 127, 14, ES_AUTOHSCROLL
CONTROL         "<a>?</a>", IDC_SYSLINK_NAME, "SysLink", 0x0, 222, 90, 7, 8
RTEXT           "Voicemail Number", IDC_STATIC, 7, 110, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_EDIT_VOICEMAIL, 86, 107, 127, 14, ES_AUTOHSCROLL
CONTROL         "<a>?</a>", IDC_SYSLINK_VOICEMAIL, "SysLink", 0x0, 222, 109, 7, 8
RTEXT           "Dialing Prefix", IDC_STATIC, 7, 129, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_ACCOUNT_DIALING_PREFIX, 86, 126, 127, 14, ES_AUTOHSCROLL
CONTROL         "<a>?</a>", IDC_ACCOUNT_HELP_DIALING_PREFIX, "SysLink", 0x0, 222, 128, 7, 8
RTEXT           "Dial Plan", IDC_STATIC, 7, 148, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_ACCOUNT_DIAL_PLAN, 86, 145, 127, 14, ES_AUTOHSCROLL
CONTROL         "<a>?</a>", IDC_ACCOUNT_HELP_DIAL_PLAN, "SysLink", 0x0, 222, 147, 7, 8
CONTROL         "Hide Caller ID", IDC_ACCOUNT_HIDE_CID, "Button", BS_AUTOCHECKBOX | WS_TABSTOP, 86, 165, 127, 10
CONTROL         "<a>?</a>", IDC_ACCOUNT_HELP_HIDE_CID, "SysLink", 0x0, 222, 164, 7, 8
RTEXT           "Media Encryption", IDC_STATIC, 7, 184, 70, 8, SS_WORDELLIPSIS
COMBOBOX        IDC_SRTP, 86, 181, 127, 30, CBS_DROPDOWNLIST | WS_VSCROLL | WS_TABSTOP
CONTROL         "<a>?</a>", IDC_SYSLINK_ENCRYPTION, "SysLink", 0x0, 222, 183, 7, 8
RTEXT           "Transport", IDC_STATIC, 7, 203, 70, 8, SS_WORDELLIPSIS
COMBOBOX        IDC_TRANSPORT, 86, 200, 127, 30, CBS_DROPDOWNLIST | WS_VSCROLL | WS_TABSTOP
CONTROL         "<a>?</a>", IDC_SYSLINK_TRANSPORT, "SysLink", 0x0, 222, 202, 7, 8
RTEXT           "Public Address", IDC_STATIC, 7, 222, 70, 8, SS_WORDELLIPSIS
COMBOBOX        IDC_PUBLIC_ADDR, 86, 219, 127, 30, CBS_DROPDOWN | WS_VSCROLL | WS_TABSTOP
CONTROL         "<a>?</a>", IDC_SYSLINK_PUBLIC_ADDRESS, "SysLink", 0x0, 222, 221, 7, 8
RTEXT           "Register Refresh", IDC_STATIC, 7, 260, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_ACCOUNT_REGISTER_REFRESH, 86, 257, 30, 14, ES_AUTOHSCROLL
RTEXT           "Keep-Alive", IDC_STATIC, 116, 260, 70, 8, SS_WORDELLIPSIS
EDITTEXT        IDC_ACCOUNT_KEEP_ALIVE, 191, 257, 20, 14, ES_AUTOHSCROLL
CONTROL         "Publish Presence", IDC_PUBLISH, "Button", BS_AUTOCHECKBOX | WS_TABSTOP, 86, 280, 127, 10
CONTROL         "<a>?</a>", IDC_SYSLINK_PUBLISH_PRESENCE, "SysLink", 0x0, 222, 278, 7, 8
CONTROL         "Allow IP Rewrite", IDC_REWRITE, "Button", BS_AUTOCHECKBOX | WS_TABSTOP, 86, 292, 127, 10
CONTROL         "<a>?</a>", IDC_SYSLINK_REWRITE, "SysLink", 0x0, 222, 290, 7, 8
CONTROL         "ICE", IDC_ICE, "Button", BS_AUTOCHECKBOX | WS_TABSTOP, 86, 304, 127, 10
CONTROL         "<a>?</a>", IDC_SYSLINK_ICE, "SysLink", 0x0, 222, 302, 7, 8
CONTROL         "Disable Session Timers", IDC_SESSION_TIMER, "Button", BS_AUTOCHECKBOX | WS_TABSTOP, 86, 316, 127, 10
CONTROL         "<a>?</a>", IDC_SYSLINK_SESSION_TIMER, "SysLink", 0x0, 222, 314, 7, 8
LTEXT           "*", IDC_ACCOUNT_REQUIRED_DOMAIN, 0, 0, 1, 1, NOT WS_VISIBLE
RTEXT           "SIP Proxy", IDC_STATIC, 0, 0, 1, 1, NOT WS_VISIBLE
EDITTEXT        IDC_EDIT_PROXY, 0, 0, 1, 1, ES_AUTOHSCROLL | NOT WS_VISIBLE
RTEXT           "Domain", IDC_STATIC, 0, 0, 1, 1, NOT WS_VISIBLE
EDITTEXT        IDC_EDIT_DOMAIN, 0, 0, 1, 1, ES_AUTOHSCROLL | NOT WS_VISIBLE
RTEXT           "Login", IDC_STATIC, 0, 0, 1, 1, NOT WS_VISIBLE
EDITTEXT        IDC_EDIT_AUTHID, 0, 0, 1, 1, ES_AUTOHSCROLL | NOT WS_VISIBLE
CONTROL         "<a>?</a>", IDC_SYSLINK_SIP_PROXY, "SysLink", 0x0, 0, 0, 1, 1, NOT WS_VISIBLE
CONTROL         "<a>?</a>", IDC_SYSLINK_DOMAIN, "SysLink", 0x0, 0, 0, 1, 1, NOT WS_VISIBLE
CONTROL         "<a>?</a>", IDC_SYSLINK_AUTHID, "SysLink", 0x0, 0, 0, 1, 1, NOT WS_VISIBLE
CONTROL         "", IDC_SYSLINK_ACCOUNT_DELETE, "SysLink", 0x0, 5, 2 + IDD_ACCOUNT_OFFSET_CUSTOM_LINK, 75, 8, NOT WS_VISIBLE
DEFPUSHBUTTON   "Save", IDOK, 83, IDD_ACCOUNT_OFFSET_CUSTOM_LINK, 70, 14
PUSHBUTTON      "Cancel", IDCANCEL, 158, IDD_ACCOUNT_OFFSET_CUSTOM_LINK, 70, 14
END
'@
$accountPattern = '(?s)IDD_ACCOUNT DIALOGEX.*?\r?\nEND'
$rc = [regex]::Replace($rc, $accountPattern, $accountBlock, 1)

[IO.File]::WriteAllText($rcPath, $rc, [Text.UTF8Encoding]::new($false))

Write-Host 'BD PBX account UI: ID + Extension/User + Password; backend fills server/proxy/domain and uses username as auth ID.'
