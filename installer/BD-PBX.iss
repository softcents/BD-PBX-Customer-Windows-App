#define MyAppName "BD PBX"
#define MyAppVersion "3.22.3"
#define MyAppPublisher "BD PBX"
#define MyAppExeName "BD-PBX.exe"

[Setup]
AppId={{7D7E6E75-5F8C-4B0A-BD-PBX-3223}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\BD PBX
DefaultGroupName=BD PBX
OutputDir=..\artifacts
OutputBaseFilename=BD-PBX-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\branding\BD-PBX.ico
UninstallDisplayIcon={app}\BD-PBX.exe
PrivilegesRequired=admin
DisableProgramGroupPage=yes

[Files]
Source: "..\artifacts\BD-PBX.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\branding\BD-PBX.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\artifacts\vc_redist.x86.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{autodesktop}\BD PBX"; Filename: "{app}\BD-PBX.exe"; IconFilename: "{app}\BD-PBX.ico"
Name: "{group}\BD PBX"; Filename: "{app}\BD-PBX.exe"; IconFilename: "{app}\BD-PBX.ico"

[Run]
Filename: "{tmp}\vc_redist.x86.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ Runtime..."; Flags: waituntilterminated
Filename: "{app}\BD-PBX.exe"; Description: "Launch BD PBX"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
