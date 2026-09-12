#define MyAppName "BD PBX"
#define MyAppVersion "3.22.3"
#define MyAppPublisher "BD PBX"
#define MyAppExeName "BD-PBX.exe"

[Setup]
AppId={{7D7E6E75-5F8C-4B0A-BD-PBX-3223}
AppName={#MyAppName}
AppVerName={#MyAppName} {#MyAppVersion}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://bdpbx.com
AppSupportURL=https://bdpbx.com
DefaultDirName={autopf}\BD PBX
DefaultGroupName=BD PBX
OutputDir=..\artifacts
OutputBaseFilename=BD-PBX-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\artifacts\BD-PBX-installer.ico
WizardImageFile=..\artifacts\BD-PBX-wizard.bmp
UninstallDisplayIcon={app}\BD-PBX.exe
PrivilegesRequired=admin
DisableProgramGroupPage=yes

[InstallDelete]
; Fresh install: remove every known BD PBX configuration location first.
Type: filesandordirs; Name: "{userappdata}\BD PBX"
Type: filesandordirs; Name: "{localappdata}\BD PBX"
Type: filesandordirs; Name: "{userappdata}\BD-PBX"
Type: filesandordirs; Name: "{localappdata}\BD-PBX"
; Fresh install: remove legacy MicroSIP configuration locations.
Type: filesandordirs; Name: "{userappdata}\MicroSIP"
Type: filesandordirs; Name: "{localappdata}\MicroSIP"
; Force recreation of the desktop shortcut so Windows uses the BD PBX icon.
Type: files; Name: "{autodesktop}\BD PBX.lnk"

[Files]
Source: "..\artifacts\BD-PBX.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\branding\BD-PBX.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\artifacts\vc_redist.x86.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{autodesktop}\BD PBX"; Filename: "{app}\BD-PBX.exe"; IconFilename: "{app}\BD-PBX.ico"; IconIndex: 0
Name: "{group}\BD PBX"; Filename: "{app}\BD-PBX.exe"; IconFilename: "{app}\BD-PBX.ico"; IconIndex: 0

[Registry]
Root: HKCU; Subkey: "Software\BD-PBX"; ValueType: string; ValueName: ""; ValueData: "{app}"; Flags: uninsdeletekey

[Run]
Filename: "{tmp}\vc_redist.x86.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ Runtime..."; Flags: waituntilterminated
Filename: "{app}\BD-PBX.exe"; Description: "Launch BD PBX"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /F /IM BD-PBX.exe /T >nul 2>&1"; Flags: runhidden waituntilterminated
Filename: "{cmd}"; Parameters: "/C taskkill /F /IM MicroSIP.exe /T >nul 2>&1"; Flags: runhidden waituntilterminated

[UninstallDelete]
; Remove application files and all known configuration locations.
Type: filesandordirs; Name: "{app}"
Type: filesandordirs; Name: "{userappdata}\BD PBX"
Type: filesandordirs; Name: "{localappdata}\BD PBX"
Type: filesandordirs; Name: "{userappdata}\BD-PBX"
Type: filesandordirs; Name: "{localappdata}\BD-PBX"
Type: filesandordirs; Name: "{userappdata}\MicroSIP"
Type: filesandordirs; Name: "{localappdata}\MicroSIP"

[Code]
function RunHidden(const FileName, Params: String): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec(FileName, Params, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function InitializeSetup(): Boolean;
begin
  { Stop running clients so configuration files are not locked during cleanup. }
  RunHidden(ExpandConstant('{cmd}'), '/C taskkill /F /IM BD-PBX.exe /T >nul 2>&1');
  RunHidden(ExpandConstant('{cmd}'), '/C taskkill /F /IM MicroSIP.exe /T >nul 2>&1');

  { Remove old registry state so the next BD PBX start is truly fresh. }
  RunHidden(ExpandConstant('{sys}\reg.exe'), 'delete "HKCU\Software\BD-PBX" /f');
  RunHidden(ExpandConstant('{sys}\reg.exe'), 'delete "HKCU\Software\BD PBX" /f');
  RunHidden(ExpandConstant('{sys}\reg.exe'), 'delete "HKLM\Software\BD-PBX" /f');
  RunHidden(ExpandConstant('{sys}\reg.exe'), 'delete "HKLM\Software\BD PBX" /f');

  Result := True;
end;

function InitializeUninstall(): Boolean;
begin
  { Stop the application before UninstallDelete removes its files and settings. }
  RunHidden(ExpandConstant('{cmd}'), '/C taskkill /F /IM BD-PBX.exe /T >nul 2>&1');
  RunHidden(ExpandConstant('{cmd}'), '/C taskkill /F /IM MicroSIP.exe /T >nul 2>&1');
  Result := True;
end;
